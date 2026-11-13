-- Bronze: raw CDC payloads by source table.
SELECT source_table, op, count(*) AS events
FROM iceberg.bronze.raw_cdc_events
GROUP BY source_table, op
ORDER BY events DESC;

-- Silver: current-state orders.
SELECT order_status, count(*) AS orders, sum(order_total) AS order_total
FROM iceberg.silver.orders
GROUP BY order_status
ORDER BY orders DESC;

-- Gold: daily revenue.
SELECT order_date, gross_revenue, captured_revenue, order_count
FROM iceberg.gold.mart_daily_revenue
ORDER BY order_date DESC
LIMIT 30;

-- Top products.
SELECT product_name, category, units_sold, gross_revenue
FROM iceberg.gold.mart_product_performance
ORDER BY gross_revenue DESC
LIMIT 10;

-- Repeat customers.
SELECT customer_id, full_name, lifetime_orders, lifetime_revenue
FROM iceberg.gold.mart_customer_360
WHERE lifetime_orders >= 2
ORDER BY lifetime_revenue DESC;

-- Campaign conversion rate.
SELECT campaign_code, channel, sessions, conversions, conversion_rate
FROM iceberg.gold.mart_campaign_performance
ORDER BY conversion_rate DESC;

-- Failed payment rate.
SELECT metric_minute, failed_payments, total_payments, failed_payment_rate
FROM iceberg.gold.mart_payment_health
ORDER BY metric_minute DESC
LIMIT 60;

-- Delayed shipments.
SELECT shipment_id, order_id, carrier, estimated_delivery_at, shipment_status
FROM iceberg.silver.shipments
WHERE shipment_status = 'delayed'
ORDER BY estimated_delivery_at;

-- Customer lifetime value.
SELECT customer_id, full_name, loyalty_tier, lifetime_revenue
FROM iceberg.gold.mart_customer_360
ORDER BY lifetime_revenue DESC
LIMIT 25;

-- Inventory risk.
SELECT sku, product_name, warehouse_code, quantity_on_hand, reorder_threshold, risk_level
FROM iceberg.gold.mart_inventory_risk
WHERE risk_level IN ('critical', 'reorder')
ORDER BY quantity_on_hand ASC;
