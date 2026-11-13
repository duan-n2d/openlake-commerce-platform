from __future__ import annotations

import time
import uuid
from collections.abc import Sequence
from decimal import Decimal
from typing import Any

import psycopg
import structlog
from psycopg.rows import dict_row
from tenacity import retry, stop_after_attempt, wait_fixed

from common.settings import PlatformSettings
from data_generator.generator import GeneratedOrder, SyntheticCommerceGenerator

LOGGER = structlog.get_logger(__name__)


@retry(stop=stop_after_attempt(20), wait=wait_fixed(2))
def connect(settings: PlatformSettings) -> psycopg.Connection:
    return psycopg.connect(settings.postgres_dsn, row_factory=dict_row)


def _money(value: object) -> Decimal:
    return value if isinstance(value, Decimal) else Decimal(str(value))


class CommerceWriter:
    def __init__(self, settings: PlatformSettings | None = None) -> None:
        self.settings = settings or PlatformSettings()

    def seed_reference_data(self, customers: int = 25, products: int = 15) -> None:
        generator = SyntheticCommerceGenerator(seed=42)
        with connect(self.settings) as conn:
            for _ in range(customers):
                self._insert_customer(conn, generator.customer())
            for _ in range(products):
                self._insert_product(conn, generator.product())
            conn.commit()
        LOGGER.info("reference_data_seeded", customers=customers, products=products)

    def generate_once(self) -> GeneratedOrder:
        generator = SyntheticCommerceGenerator()
        with connect(self.settings) as conn:
            customers = self._fetch(conn, "SELECT customer_id FROM commerce.customers")
            products = self._fetch(
                conn,
                "SELECT product_id, sku, unit_price FROM commerce.products WHERE active = true",
            )
            campaigns = self._fetch(
                conn,
                """
                SELECT campaign_id
                FROM commerce.marketing_campaigns
                WHERE current_date BETWEEN start_date AND end_date
                """,
            )
            if not customers or not products:
                raise RuntimeError("Postgres must contain customers and products before generation")
            customer_id = customers[0]["customer_id"] if len(customers) == 1 else generator.random.choice(customers)["customer_id"]
            campaign_id = None
            if campaigns and generator.random.random() < 0.55:
                campaign_id = generator.random.choice(campaigns)["campaign_id"]
            order = generator.order(customer_id, list(products), campaign_id)
            self._insert_generated_order(conn, order)
            self._maybe_mutate_existing_records(conn, generator)
            conn.commit()
        LOGGER.info("generated_commerce_activity", order_id=str(order.order["order_id"]))
        return order

    def run_continuous(self, interval_seconds: float = 2.0) -> None:
        while True:
            self.generate_once()
            time.sleep(interval_seconds)

    def _insert_generated_order(self, conn: psycopg.Connection, generated: GeneratedOrder) -> None:
        with conn.cursor() as cur:
            cur.execute(
                """
                INSERT INTO commerce.orders
                    (order_id, customer_id, campaign_id, order_status, order_total, currency, ordered_at, updated_at)
                VALUES
                    (%(order_id)s, %(customer_id)s, %(campaign_id)s, %(order_status)s, %(order_total)s, %(currency)s, %(ordered_at)s, %(updated_at)s)
                """,
                generated.order,
            )
            cur.executemany(
                """
                INSERT INTO commerce.order_items
                    (item_id, order_id, product_id, quantity, unit_price, discount_amount, line_total)
                VALUES
                    (%(item_id)s, %(order_id)s, %(product_id)s, %(quantity)s, %(unit_price)s, %(discount_amount)s, %(line_total)s)
                """,
                generated.items,
            )
            cur.execute(
                """
                INSERT INTO commerce.payments
                    (payment_id, order_id, payment_method, payment_status, amount, failure_reason, processed_at, updated_at)
                VALUES
                    (%(payment_id)s, %(order_id)s, %(payment_method)s, %(payment_status)s, %(amount)s, %(failure_reason)s, %(processed_at)s, %(updated_at)s)
                """,
                generated.payment,
            )
            cur.execute(
                """
                INSERT INTO commerce.shipments
                    (shipment_id, order_id, carrier, tracking_number, shipment_status, shipped_at, estimated_delivery_at, delivered_at, updated_at)
                VALUES
                    (%(shipment_id)s, %(order_id)s, %(carrier)s, %(tracking_number)s, %(shipment_status)s, %(shipped_at)s, %(estimated_delivery_at)s, %(delivered_at)s, %(updated_at)s)
                """,
                generated.shipment,
            )
            cur.executemany(
                """
                INSERT INTO commerce.clickstream_events
                    (event_id, session_id, customer_id, campaign_id, product_id, event_type, page_url, user_agent, event_properties, occurred_at)
                VALUES
                    (%(event_id)s, %(session_id)s, %(customer_id)s, %(campaign_id)s, %(product_id)s, %(event_type)s, %(page_url)s, %(user_agent)s, %(event_properties)s, %(occurred_at)s)
                """,
                generated.clickstream_events,
            )
            for update in generated.inventory_updates:
                cur.execute(
                    """
                    UPDATE commerce.inventory
                    SET quantity_on_hand = GREATEST(0, quantity_on_hand + %(quantity_delta)s),
                        updated_at = %(updated_at)s
                    WHERE product_id = %(product_id)s AND warehouse_code = %(warehouse_code)s
                    """,
                    update,
                )

    def _maybe_mutate_existing_records(
        self, conn: psycopg.Connection, generator: SyntheticCommerceGenerator
    ) -> None:
        with conn.cursor() as cur:
            if generator.random.random() < 0.20:
                cur.execute(
                    """
                    UPDATE commerce.customers
                    SET loyalty_tier = CASE loyalty_tier
                        WHEN 'bronze' THEN 'silver'
                        WHEN 'silver' THEN 'gold'
                        ELSE loyalty_tier
                    END,
                    updated_at = now()
                    WHERE customer_id = (
                        SELECT customer_id FROM commerce.customers ORDER BY random() LIMIT 1
                    )
                    """
                )
            if generator.random.random() < 0.18:
                cur.execute(
                    """
                    UPDATE commerce.shipments
                    SET shipment_status = 'delayed', updated_at = now()
                    WHERE shipment_status IN ('pending', 'packed', 'shipped')
                    AND random() < 0.5
                    """
                )
            if generator.random.random() < 0.08:
                cur.execute(
                    """
                    UPDATE commerce.payments
                    SET payment_status = 'refunded', updated_at = now()
                    WHERE payment_status = 'captured'
                    AND random() < 0.2
                    """
                )

    def _insert_customer(self, conn: psycopg.Connection, customer: dict[str, object]) -> None:
        with conn.cursor() as cur:
            cur.execute(
                """
                INSERT INTO commerce.customers
                    (customer_id, email, first_name, last_name, phone, loyalty_tier, marketing_opt_in, city, state, country)
                VALUES
                    (%(customer_id)s, %(email)s, %(first_name)s, %(last_name)s, %(phone)s, %(loyalty_tier)s, %(marketing_opt_in)s, %(city)s, %(state)s, %(country)s)
                ON CONFLICT (email) DO NOTHING
                """,
                customer,
            )

    def _insert_product(self, conn: psycopg.Connection, product: dict[str, object]) -> None:
        with conn.cursor() as cur:
            cur.execute(
                """
                INSERT INTO commerce.products
                    (product_id, sku, product_name, category, brand, unit_price, active)
                VALUES
                    (%(product_id)s, %(sku)s, %(product_name)s, %(category)s, %(brand)s, %(unit_price)s, %(active)s)
                ON CONFLICT (sku) DO NOTHING
                """,
                product,
            )
            product_id = product["product_id"]
            for warehouse_code in ("SFO-01", "ORD-01"):
                cur.execute(
                    """
                    INSERT INTO commerce.inventory
                        (inventory_id, product_id, warehouse_code, quantity_on_hand, reorder_threshold)
                    VALUES
                        (%s, %s, %s, %s, %s)
                    ON CONFLICT (product_id, warehouse_code) DO NOTHING
                    """,
                    (
                        uuid.uuid4(),
                        product_id,
                        warehouse_code,
                        generator_quantity(product["unit_price"]),
                        10,
                    ),
                )

    @staticmethod
    def _fetch(conn: psycopg.Connection, sql: str) -> Sequence[dict[str, Any]]:
        with conn.cursor() as cur:
            cur.execute(sql)
            return cur.fetchall()


def generator_quantity(unit_price: object) -> int:
    price = _money(unit_price)
    if price > Decimal("100"):
        return 35
    if price > Decimal("50"):
        return 55
    return 80
