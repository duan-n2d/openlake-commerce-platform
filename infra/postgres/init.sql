CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'debezium') THEN
        CREATE ROLE debezium WITH LOGIN REPLICATION PASSWORD 'debezium';
    END IF;
END
$$;

CREATE SCHEMA IF NOT EXISTS commerce AUTHORIZATION commerce_app;

CREATE TABLE IF NOT EXISTS commerce.customers (
    customer_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT NOT NULL UNIQUE,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    phone TEXT,
    loyalty_tier TEXT NOT NULL DEFAULT 'bronze'
        CHECK (loyalty_tier IN ('bronze', 'silver', 'gold', 'platinum')),
    marketing_opt_in BOOLEAN NOT NULL DEFAULT TRUE,
    city TEXT NOT NULL,
    state TEXT NOT NULL,
    country TEXT NOT NULL DEFAULT 'US',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS commerce.products (
    product_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sku TEXT NOT NULL UNIQUE,
    product_name TEXT NOT NULL,
    category TEXT NOT NULL,
    brand TEXT NOT NULL,
    unit_price NUMERIC(12, 2) NOT NULL CHECK (unit_price >= 0),
    active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS commerce.inventory (
    inventory_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES commerce.products(product_id),
    warehouse_code TEXT NOT NULL,
    quantity_on_hand INTEGER NOT NULL CHECK (quantity_on_hand >= 0),
    reorder_threshold INTEGER NOT NULL CHECK (reorder_threshold >= 0),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (product_id, warehouse_code)
);

CREATE TABLE IF NOT EXISTS commerce.marketing_campaigns (
    campaign_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    campaign_code TEXT NOT NULL UNIQUE,
    campaign_name TEXT NOT NULL,
    channel TEXT NOT NULL CHECK (channel IN ('email', 'paid_search', 'social', 'affiliate', 'organic')),
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    budget_amount NUMERIC(12, 2) NOT NULL CHECK (budget_amount >= 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CHECK (end_date >= start_date)
);

CREATE TABLE IF NOT EXISTS commerce.orders (
    order_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID NOT NULL REFERENCES commerce.customers(customer_id),
    campaign_id UUID REFERENCES commerce.marketing_campaigns(campaign_id),
    order_status TEXT NOT NULL DEFAULT 'created'
        CHECK (order_status IN ('created', 'confirmed', 'paid', 'packed', 'shipped', 'delivered', 'cancelled', 'returned')),
    order_total NUMERIC(12, 2) NOT NULL DEFAULT 0 CHECK (order_total >= 0),
    currency TEXT NOT NULL DEFAULT 'USD',
    ordered_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS commerce.order_items (
    item_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES commerce.orders(order_id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES commerce.products(product_id),
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit_price NUMERIC(12, 2) NOT NULL CHECK (unit_price >= 0),
    discount_amount NUMERIC(12, 2) NOT NULL DEFAULT 0 CHECK (discount_amount >= 0),
    line_total NUMERIC(12, 2) NOT NULL CHECK (line_total >= 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS commerce.payments (
    payment_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES commerce.orders(order_id),
    payment_method TEXT NOT NULL CHECK (payment_method IN ('card', 'paypal', 'apple_pay', 'gift_card')),
    payment_status TEXT NOT NULL
        CHECK (payment_status IN ('authorized', 'captured', 'failed', 'refunded', 'cancelled')),
    amount NUMERIC(12, 2) NOT NULL CHECK (amount >= 0),
    failure_reason TEXT,
    processed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS commerce.shipments (
    shipment_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES commerce.orders(order_id),
    carrier TEXT NOT NULL,
    tracking_number TEXT UNIQUE,
    shipment_status TEXT NOT NULL DEFAULT 'pending'
        CHECK (shipment_status IN ('pending', 'packed', 'shipped', 'delayed', 'delivered', 'returned')),
    shipped_at TIMESTAMPTZ,
    estimated_delivery_at TIMESTAMPTZ,
    delivered_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS commerce.clickstream_events (
    event_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID NOT NULL,
    customer_id UUID REFERENCES commerce.customers(customer_id),
    campaign_id UUID REFERENCES commerce.marketing_campaigns(campaign_id),
    product_id UUID REFERENCES commerce.products(product_id),
    event_type TEXT NOT NULL
        CHECK (event_type IN ('page_view', 'product_view', 'add_to_cart', 'checkout_start', 'purchase', 'search', 'support_click')),
    page_url TEXT NOT NULL,
    user_agent TEXT NOT NULL,
    event_properties JSONB NOT NULL DEFAULT '{}'::jsonb,
    occurred_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS commerce.support_tickets (
    ticket_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID NOT NULL REFERENCES commerce.customers(customer_id),
    order_id UUID REFERENCES commerce.orders(order_id),
    channel TEXT NOT NULL CHECK (channel IN ('email', 'chat', 'phone', 'social')),
    priority TEXT NOT NULL CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
    ticket_status TEXT NOT NULL CHECK (ticket_status IN ('open', 'pending_customer', 'resolved', 'closed')),
    subject TEXT NOT NULL,
    opened_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    resolved_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_orders_customer_time ON commerce.orders(customer_id, ordered_at DESC);
CREATE INDEX IF NOT EXISTS idx_payments_order_status ON commerce.payments(order_id, payment_status);
CREATE INDEX IF NOT EXISTS idx_shipments_status_time ON commerce.shipments(shipment_status, updated_at DESC);
CREATE INDEX IF NOT EXISTS idx_clickstream_customer_time ON commerce.clickstream_events(customer_id, occurred_at DESC);
CREATE INDEX IF NOT EXISTS idx_inventory_risk ON commerce.inventory(quantity_on_hand, reorder_threshold);

INSERT INTO commerce.customers (customer_id, email, first_name, last_name, phone, loyalty_tier, marketing_opt_in, city, state)
VALUES
    ('10000000-0000-0000-0000-000000000001', 'maya.chen@example.com', 'Maya', 'Chen', '+1-415-555-0101', 'gold', TRUE, 'San Francisco', 'CA'),
    ('10000000-0000-0000-0000-000000000002', 'jordan.smith@example.com', 'Jordan', 'Smith', '+1-312-555-0199', 'silver', TRUE, 'Chicago', 'IL'),
    ('10000000-0000-0000-0000-000000000003', 'priya.patel@example.com', 'Priya', 'Patel', '+1-212-555-0114', 'platinum', FALSE, 'New York', 'NY'),
    ('10000000-0000-0000-0000-000000000004', 'diego.rivera@example.com', 'Diego', 'Rivera', '+1-512-555-0167', 'bronze', TRUE, 'Austin', 'TX')
ON CONFLICT (email) DO NOTHING;

INSERT INTO commerce.products (product_id, sku, product_name, category, brand, unit_price)
VALUES
    ('20000000-0000-0000-0000-000000000001', 'EL-HDP-100', 'Studio Wireless Headphones', 'electronics', 'Northstar Audio', 129.00),
    ('20000000-0000-0000-0000-000000000002', 'HM-COF-220', 'Cold Brew Maker', 'home', 'Brew & Co', 42.50),
    ('20000000-0000-0000-0000-000000000003', 'SP-YGA-310', 'Recycled Yoga Mat', 'sports', 'GreenMotion', 58.00),
    ('20000000-0000-0000-0000-000000000004', 'BT-SKN-410', 'Vitamin C Serum', 'beauty', 'GlowLab', 24.75),
    ('20000000-0000-0000-0000-000000000005', 'BK-DAT-510', 'Analytics Engineering Handbook', 'books', 'Lakehouse Press', 39.99)
ON CONFLICT (sku) DO NOTHING;

INSERT INTO commerce.inventory (product_id, warehouse_code, quantity_on_hand, reorder_threshold)
SELECT product_id, warehouse_code, quantity_on_hand, reorder_threshold
FROM (
    VALUES
        ('20000000-0000-0000-0000-000000000001'::uuid, 'SFO-01', 42, 15),
        ('20000000-0000-0000-0000-000000000002'::uuid, 'ORD-01', 18, 12),
        ('20000000-0000-0000-0000-000000000003'::uuid, 'AUS-01', 9, 10),
        ('20000000-0000-0000-0000-000000000004'::uuid, 'EWR-01', 55, 18),
        ('20000000-0000-0000-0000-000000000005'::uuid, 'SFO-01', 31, 8)
) AS seed(product_id, warehouse_code, quantity_on_hand, reorder_threshold)
ON CONFLICT (product_id, warehouse_code) DO NOTHING;

INSERT INTO commerce.marketing_campaigns (campaign_id, campaign_code, campaign_name, channel, start_date, end_date, budget_amount)
VALUES
    ('30000000-0000-0000-0000-000000000001', 'SUMMER26_EMAIL', 'Summer 2026 Email Launch', 'email', DATE '2026-06-01', DATE '2026-08-31', 15000.00),
    ('30000000-0000-0000-0000-000000000002', 'SEARCH_BRAND_ALWAYS_ON', 'Brand Search Always On', 'paid_search', DATE '2026-01-01', DATE '2026-12-31', 42000.00),
    ('30000000-0000-0000-0000-000000000003', 'SOCIAL_CREATOR_DROP', 'Creator Product Drop', 'social', DATE '2026-05-15', DATE '2026-07-15', 22500.00)
ON CONFLICT (campaign_code) DO NOTHING;

WITH new_order AS (
    INSERT INTO commerce.orders (order_id, customer_id, campaign_id, order_status, order_total, ordered_at)
    VALUES
        ('40000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000001', 'paid', 171.50, now() - interval '2 days'),
        ('40000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000002', '30000000-0000-0000-0000-000000000002', 'shipped', 58.00, now() - interval '1 day'),
        ('40000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000003', NULL, 'confirmed', 39.99, now() - interval '3 hours')
    ON CONFLICT (order_id) DO NOTHING
    RETURNING order_id
)
INSERT INTO commerce.order_items (order_id, product_id, quantity, unit_price, discount_amount, line_total)
VALUES
    ('40000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000001', 1, 129.00, 0.00, 129.00),
    ('40000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000002', 1, 42.50, 0.00, 42.50),
    ('40000000-0000-0000-0000-000000000002', '20000000-0000-0000-0000-000000000003', 1, 58.00, 0.00, 58.00),
    ('40000000-0000-0000-0000-000000000003', '20000000-0000-0000-0000-000000000005', 1, 39.99, 0.00, 39.99)
ON CONFLICT DO NOTHING;

INSERT INTO commerce.payments (payment_id, order_id, payment_method, payment_status, amount, processed_at)
VALUES
    ('50000000-0000-0000-0000-000000000001', '40000000-0000-0000-0000-000000000001', 'card', 'captured', 171.50, now() - interval '2 days'),
    ('50000000-0000-0000-0000-000000000002', '40000000-0000-0000-0000-000000000002', 'apple_pay', 'captured', 58.00, now() - interval '1 day'),
    ('50000000-0000-0000-0000-000000000003', '40000000-0000-0000-0000-000000000003', 'card', 'authorized', 39.99, now() - interval '2 hours')
ON CONFLICT (payment_id) DO NOTHING;

INSERT INTO commerce.shipments (shipment_id, order_id, carrier, tracking_number, shipment_status, shipped_at, estimated_delivery_at)
VALUES
    ('60000000-0000-0000-0000-000000000001', '40000000-0000-0000-0000-000000000001', 'UPS', '1ZOPENLAKE001', 'packed', NULL, now() + interval '2 days'),
    ('60000000-0000-0000-0000-000000000002', '40000000-0000-0000-0000-000000000002', 'FedEx', 'FDXOPENLAKE002', 'shipped', now() - interval '18 hours', now() + interval '1 day')
ON CONFLICT (shipment_id) DO NOTHING;

INSERT INTO commerce.clickstream_events (event_id, session_id, customer_id, campaign_id, product_id, event_type, page_url, user_agent, event_properties, occurred_at)
VALUES
    ('70000000-0000-0000-0000-000000000001', '80000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000001', 'product_view', '/products/studio-wireless-headphones', 'Mozilla/5.0', '{"device":"mobile"}', now() - interval '2 days'),
    ('70000000-0000-0000-0000-000000000002', '80000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000001', 'purchase', '/checkout/confirmation', 'Mozilla/5.0', '{"device":"mobile"}', now() - interval '2 days')
ON CONFLICT (event_id) DO NOTHING;

INSERT INTO commerce.support_tickets (ticket_id, customer_id, order_id, channel, priority, ticket_status, subject, opened_at)
VALUES
    ('90000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000002', '40000000-0000-0000-0000-000000000002', 'chat', 'normal', 'open', 'Question about shipment ETA', now() - interval '4 hours')
ON CONFLICT (ticket_id) DO NOTHING;

ALTER TABLE commerce.customers REPLICA IDENTITY FULL;
ALTER TABLE commerce.products REPLICA IDENTITY FULL;
ALTER TABLE commerce.inventory REPLICA IDENTITY FULL;
ALTER TABLE commerce.marketing_campaigns REPLICA IDENTITY FULL;
ALTER TABLE commerce.orders REPLICA IDENTITY FULL;
ALTER TABLE commerce.order_items REPLICA IDENTITY FULL;
ALTER TABLE commerce.payments REPLICA IDENTITY FULL;
ALTER TABLE commerce.shipments REPLICA IDENTITY FULL;
ALTER TABLE commerce.clickstream_events REPLICA IDENTITY FULL;
ALTER TABLE commerce.support_tickets REPLICA IDENTITY FULL;

GRANT USAGE ON SCHEMA commerce TO debezium;
GRANT SELECT ON ALL TABLES IN SCHEMA commerce TO debezium;
ALTER DEFAULT PRIVILEGES IN SCHEMA commerce GRANT SELECT ON TABLES TO debezium;
