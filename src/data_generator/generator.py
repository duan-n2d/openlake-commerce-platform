from __future__ import annotations

import random
import uuid
from dataclasses import dataclass
from datetime import UTC, datetime, timedelta
from decimal import Decimal

from faker import Faker


PRODUCT_CATALOG = [
    ("EL-HDP-100", "Studio Wireless Headphones", "electronics", "Northstar Audio", Decimal("129.00")),
    ("HM-COF-220", "Cold Brew Maker", "home", "Brew & Co", Decimal("42.50")),
    ("SP-YGA-310", "Recycled Yoga Mat", "sports", "GreenMotion", Decimal("58.00")),
    ("BT-SKN-410", "Vitamin C Serum", "beauty", "GlowLab", Decimal("24.75")),
    ("BK-DAT-510", "Analytics Engineering Handbook", "books", "Lakehouse Press", Decimal("39.99")),
    ("EL-USB-610", "USB-C Travel Dock", "electronics", "Nomad Systems", Decimal("89.95")),
    ("HM-LMP-720", "Adjustable Desk Lamp", "home", "BrightDesk", Decimal("64.00")),
]


@dataclass(frozen=True)
class GeneratedOrder:
    order: dict[str, object]
    items: list[dict[str, object]]
    payment: dict[str, object]
    shipment: dict[str, object]
    clickstream_events: list[dict[str, object]]
    inventory_updates: list[dict[str, object]]


class SyntheticCommerceGenerator:
    """Creates realistic, internally consistent ecommerce events."""

    def __init__(self, seed: int | None = None) -> None:
        self.faker = Faker("en_US")
        self.random = random.Random(seed)
        Faker.seed(seed)

    def customer(self) -> dict[str, object]:
        first_name = self.faker.first_name()
        last_name = self.faker.last_name()
        email = f"{first_name}.{last_name}.{self.random.randint(1000, 9999)}@example.com".lower()
        return {
            "customer_id": uuid.uuid4(),
            "email": email,
            "first_name": first_name,
            "last_name": last_name,
            "phone": self.faker.phone_number(),
            "loyalty_tier": self.random.choices(
                ["bronze", "silver", "gold", "platinum"], weights=[45, 30, 20, 5]
            )[0],
            "marketing_opt_in": self.random.random() > 0.18,
            "city": self.faker.city(),
            "state": self.faker.state_abbr(),
            "country": "US",
        }

    def product(self) -> dict[str, object]:
        sku, name, category, brand, price = self.random.choice(PRODUCT_CATALOG)
        suffix = self.random.randint(100, 999)
        return {
            "product_id": uuid.uuid4(),
            "sku": f"{sku}-{suffix}",
            "product_name": name,
            "category": category,
            "brand": brand,
            "unit_price": price,
            "active": True,
        }

    def order(
        self,
        customer_id: uuid.UUID,
        products: list[dict[str, object]],
        campaign_id: uuid.UUID | None = None,
    ) -> GeneratedOrder:
        if not products:
            raise ValueError("At least one product is required to generate an order")

        now = datetime.now(tz=UTC)
        order_id = uuid.uuid4()
        selected_products = self.random.sample(products, k=self.random.randint(1, min(3, len(products))))
        items: list[dict[str, object]] = []
        total = Decimal("0.00")
        inventory_updates: list[dict[str, object]] = []

        for product in selected_products:
            quantity = self.random.choices([1, 2, 3], weights=[70, 25, 5])[0]
            unit_price = Decimal(str(product["unit_price"]))
            discount = Decimal("0.00")
            if self.random.random() < 0.15:
                discount = (unit_price * Decimal("0.10")).quantize(Decimal("0.01"))
            line_total = ((unit_price - discount) * quantity).quantize(Decimal("0.01"))
            total += line_total
            items.append(
                {
                    "item_id": uuid.uuid4(),
                    "order_id": order_id,
                    "product_id": product["product_id"],
                    "quantity": quantity,
                    "unit_price": unit_price,
                    "discount_amount": discount,
                    "line_total": line_total,
                }
            )
            inventory_updates.append(
                {
                    "product_id": product["product_id"],
                    "warehouse_code": self.random.choice(["SFO-01", "ORD-01", "AUS-01", "EWR-01"]),
                    "quantity_delta": -quantity,
                    "updated_at": now,
                }
            )

        payment_status = self.random.choices(
            ["captured", "failed", "authorized"], weights=[83, 9, 8]
        )[0]
        order_status = "paid" if payment_status == "captured" else "confirmed"
        failure_reason = None
        if payment_status == "failed":
            failure_reason = self.random.choice(
                ["insufficient_funds", "card_declined", "processor_timeout", "fraud_check"]
            )
            order_status = "created"

        session_id = uuid.uuid4()
        first_product = selected_products[0]
        clickstream_events = [
            self._click_event(
                session_id,
                customer_id,
                campaign_id,
                first_product["product_id"],
                "product_view",
                f"/products/{first_product['sku']}",
                now - timedelta(minutes=3),
            ),
            self._click_event(
                session_id,
                customer_id,
                campaign_id,
                first_product["product_id"],
                "checkout_start",
                "/checkout",
                now - timedelta(minutes=1),
            ),
        ]
        if payment_status == "captured":
            clickstream_events.append(
                self._click_event(
                    session_id,
                    customer_id,
                    campaign_id,
                    first_product["product_id"],
                    "purchase",
                    "/checkout/confirmation",
                    now,
                )
            )

        return GeneratedOrder(
            order={
                "order_id": order_id,
                "customer_id": customer_id,
                "campaign_id": campaign_id,
                "order_status": order_status,
                "order_total": total.quantize(Decimal("0.01")),
                "currency": "USD",
                "ordered_at": now,
                "updated_at": now,
            },
            items=items,
            payment={
                "payment_id": uuid.uuid4(),
                "order_id": order_id,
                "payment_method": self.random.choice(["card", "paypal", "apple_pay", "gift_card"]),
                "payment_status": payment_status,
                "amount": total.quantize(Decimal("0.01")),
                "failure_reason": failure_reason,
                "processed_at": now,
                "updated_at": now,
            },
            shipment={
                "shipment_id": uuid.uuid4(),
                "order_id": order_id,
                "carrier": self.random.choice(["UPS", "FedEx", "USPS", "DHL"]),
                "tracking_number": f"OL{self.random.randint(10_000_000, 99_999_999)}",
                "shipment_status": "pending" if payment_status != "captured" else "packed",
                "shipped_at": None,
                "estimated_delivery_at": now + timedelta(days=self.random.randint(2, 6)),
                "delivered_at": None,
                "updated_at": now,
            },
            clickstream_events=clickstream_events,
            inventory_updates=inventory_updates,
        )

    def support_ticket(self, customer_id: uuid.UUID, order_id: uuid.UUID | None) -> dict[str, object]:
        now = datetime.now(tz=UTC)
        return {
            "ticket_id": uuid.uuid4(),
            "customer_id": customer_id,
            "order_id": order_id,
            "channel": self.random.choice(["email", "chat", "phone", "social"]),
            "priority": self.random.choices(["low", "normal", "high", "urgent"], [20, 55, 20, 5])[0],
            "ticket_status": self.random.choice(["open", "pending_customer"]),
            "subject": self.random.choice(
                [
                    "Shipment ETA question",
                    "Need help applying a promo code",
                    "Payment authorization question",
                    "Product recommendation request",
                ]
            ),
            "opened_at": now,
            "updated_at": now,
        }

    def _click_event(
        self,
        session_id: uuid.UUID,
        customer_id: uuid.UUID,
        campaign_id: uuid.UUID | None,
        product_id: uuid.UUID,
        event_type: str,
        page_url: str,
        occurred_at: datetime,
    ) -> dict[str, object]:
        return {
            "event_id": uuid.uuid4(),
            "session_id": session_id,
            "customer_id": customer_id,
            "campaign_id": campaign_id,
            "product_id": product_id,
            "event_type": event_type,
            "page_url": page_url,
            "user_agent": self.faker.user_agent(),
            "event_properties": {
                "device": self.random.choice(["desktop", "mobile", "tablet"]),
                "referrer": self.random.choice(["email", "search", "social", "direct"]),
            },
            "occurred_at": occurred_at,
        }
