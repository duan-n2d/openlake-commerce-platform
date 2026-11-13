from __future__ import annotations

from datetime import date, datetime
from decimal import Decimal
from enum import StrEnum
from typing import Any
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field


class LoyaltyTier(StrEnum):
    bronze = "bronze"
    silver = "silver"
    gold = "gold"
    platinum = "platinum"


class OrderStatus(StrEnum):
    created = "created"
    confirmed = "confirmed"
    paid = "paid"
    packed = "packed"
    shipped = "shipped"
    delivered = "delivered"
    cancelled = "cancelled"
    returned = "returned"


class PaymentStatus(StrEnum):
    authorized = "authorized"
    captured = "captured"
    failed = "failed"
    refunded = "refunded"
    cancelled = "cancelled"


class ShipmentStatus(StrEnum):
    pending = "pending"
    packed = "packed"
    shipped = "shipped"
    delayed = "delayed"
    delivered = "delivered"
    returned = "returned"


class ClickEventType(StrEnum):
    page_view = "page_view"
    product_view = "product_view"
    add_to_cart = "add_to_cart"
    checkout_start = "checkout_start"
    purchase = "purchase"
    search = "search"
    support_click = "support_click"


class CampaignChannel(StrEnum):
    email = "email"
    paid_search = "paid_search"
    social = "social"
    affiliate = "affiliate"
    organic = "organic"


class CustomerContract(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    customer_id: UUID
    email: str
    first_name: str
    last_name: str
    phone: str | None = None
    loyalty_tier: LoyaltyTier
    marketing_opt_in: bool
    city: str
    state: str
    country: str = "US"
    created_at: datetime
    updated_at: datetime


class ProductContract(BaseModel):
    product_id: UUID
    sku: str
    product_name: str
    category: str
    brand: str
    unit_price: Decimal = Field(ge=0)
    active: bool = True


class CampaignContract(BaseModel):
    campaign_id: UUID
    campaign_code: str
    campaign_name: str
    channel: CampaignChannel
    start_date: date
    end_date: date
    budget_amount: Decimal = Field(ge=0)


class InventoryContract(BaseModel):
    inventory_id: UUID
    product_id: UUID
    warehouse_code: str
    quantity_on_hand: int = Field(ge=0)
    reorder_threshold: int = Field(ge=0)
    updated_at: datetime


class OrderItemContract(BaseModel):
    item_id: UUID
    order_id: UUID
    product_id: UUID
    quantity: int = Field(gt=0)
    unit_price: Decimal = Field(ge=0)
    discount_amount: Decimal = Field(default=Decimal("0.00"), ge=0)
    line_total: Decimal = Field(ge=0)


class OrderContract(BaseModel):
    order_id: UUID
    customer_id: UUID
    campaign_id: UUID | None = None
    order_status: OrderStatus
    order_total: Decimal = Field(ge=0)
    currency: str = "USD"
    ordered_at: datetime
    updated_at: datetime
    items: list[OrderItemContract] = Field(default_factory=list)


class PaymentContract(BaseModel):
    payment_id: UUID
    order_id: UUID
    payment_method: str
    payment_status: PaymentStatus
    amount: Decimal = Field(ge=0)
    failure_reason: str | None = None
    processed_at: datetime
    updated_at: datetime


class ShipmentContract(BaseModel):
    shipment_id: UUID
    order_id: UUID
    carrier: str
    tracking_number: str | None = None
    shipment_status: ShipmentStatus
    shipped_at: datetime | None = None
    estimated_delivery_at: datetime | None = None
    delivered_at: datetime | None = None
    updated_at: datetime


class ClickstreamEventContract(BaseModel):
    event_id: UUID
    session_id: UUID
    customer_id: UUID | None = None
    campaign_id: UUID | None = None
    product_id: UUID | None = None
    event_type: ClickEventType
    page_url: str
    user_agent: str
    event_properties: dict[str, Any] = Field(default_factory=dict)
    occurred_at: datetime


class SupportTicketContract(BaseModel):
    ticket_id: UUID
    customer_id: UUID
    order_id: UUID | None = None
    channel: str
    priority: str
    ticket_status: str
    subject: str
    opened_at: datetime
    resolved_at: datetime | None = None
    updated_at: datetime
