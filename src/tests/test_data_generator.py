from __future__ import annotations

from uuid import uuid4

from data_generator.generator import SyntheticCommerceGenerator


def test_order_generation_is_financially_consistent() -> None:
    generator = SyntheticCommerceGenerator(seed=7)
    products = [
        {
            "product_id": uuid4(),
            "sku": "TEST-001",
            "unit_price": "25.00",
        },
        {
            "product_id": uuid4(),
            "sku": "TEST-002",
            "unit_price": "40.00",
        },
    ]

    generated = generator.order(uuid4(), products)

    line_total = sum(item["line_total"] for item in generated.items)
    assert generated.order["order_total"] == line_total
    assert generated.payment["amount"] == generated.order["order_total"]
    assert generated.shipment["order_id"] == generated.order["order_id"]
    assert generated.clickstream_events


def test_customer_generation_uses_business_enums() -> None:
    customer = SyntheticCommerceGenerator(seed=11).customer()
    assert customer["loyalty_tier"] in {"bronze", "silver", "gold", "platinum"}
    assert customer["email"].endswith("@example.com")
