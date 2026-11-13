CREATE TABLE IF NOT EXISTS gold.realtime_order_metrics (
    metric_minute TIMESTAMP_LTZ(3),
    order_count BIGINT,
    gross_revenue DECIMAL(18, 2),
    captured_revenue DECIMAL(18, 2),
    failed_payment_count BIGINT,
    payment_success_rate DOUBLE,
    updated_at TIMESTAMP_LTZ(3)
) WITH ('format-version' = '2');

CREATE TABLE IF NOT EXISTS gold.inventory_risk_alerts (
    alert_id STRING,
    product_id STRING,
    sku STRING,
    warehouse_code STRING,
    quantity_on_hand INT,
    reorder_threshold INT,
    risk_level STRING,
    alert_ts TIMESTAMP_LTZ(3)
) WITH ('format-version' = '2');

CREATE TABLE IF NOT EXISTS gold.campaign_conversion_events (
    metric_minute TIMESTAMP_LTZ(3),
    campaign_id STRING,
    sessions BIGINT,
    conversions BIGINT,
    conversion_rate DOUBLE,
    updated_at TIMESTAMP_LTZ(3)
) WITH ('format-version' = '2');

CREATE TABLE IF NOT EXISTS gold.customer_activity_sessions (
    session_id STRING,
    customer_id STRING,
    campaign_id STRING,
    session_start TIMESTAMP_LTZ(3),
    session_end TIMESTAMP_LTZ(3),
    event_count BIGINT,
    purchase_count BIGINT,
    updated_at TIMESTAMP_LTZ(3)
) WITH ('format-version' = '2');

INSERT INTO gold.realtime_order_metrics
SELECT
    TUMBLE_START(o.updated_at, INTERVAL '1' MINUTE) AS metric_minute,
    COUNT(DISTINCT o.order_id) AS order_count,
    SUM(o.order_total) AS gross_revenue,
    SUM(CASE WHEN p.payment_status = 'captured' THEN p.amount ELSE CAST(0 AS DECIMAL(12, 2)) END) AS captured_revenue,
    SUM(CASE WHEN p.payment_status = 'failed' THEN 1 ELSE 0 END) AS failed_payment_count,
    CAST(SUM(CASE WHEN p.payment_status = 'captured' THEN 1 ELSE 0 END) AS DOUBLE)
        / NULLIF(COUNT(p.payment_id), 0) AS payment_success_rate,
    CURRENT_TIMESTAMP AS updated_at
FROM TABLE(TUMBLE(TABLE kafka_orders, DESCRIPTOR(updated_at), INTERVAL '1' MINUTE)) o
LEFT JOIN kafka_payments p
    ON o.order_id = p.order_id
GROUP BY TUMBLE_START(o.updated_at, INTERVAL '1' MINUTE);

INSERT INTO gold.inventory_risk_alerts
SELECT
    CONCAT(product_id, '-', warehouse_code, '-', CAST(updated_at AS STRING)) AS alert_id,
    product_id,
    CAST(NULL AS STRING) AS sku,
    warehouse_code,
    quantity_on_hand,
    reorder_threshold,
    CASE
        WHEN quantity_on_hand = 0 THEN 'critical'
        WHEN quantity_on_hand <= reorder_threshold THEN 'reorder'
        WHEN quantity_on_hand <= reorder_threshold * 2 THEN 'watch'
        ELSE 'healthy'
    END AS risk_level,
    updated_at AS alert_ts
FROM kafka_inventory
WHERE quantity_on_hand <= reorder_threshold * 2;

INSERT INTO gold.campaign_conversion_events
SELECT
    TUMBLE_START(occurred_at, INTERVAL '1' MINUTE) AS metric_minute,
    campaign_id,
    COUNT(DISTINCT session_id) AS sessions,
    SUM(CASE WHEN event_type = 'purchase' THEN 1 ELSE 0 END) AS conversions,
    CAST(SUM(CASE WHEN event_type = 'purchase' THEN 1 ELSE 0 END) AS DOUBLE)
        / NULLIF(COUNT(DISTINCT session_id), 0) AS conversion_rate,
    CURRENT_TIMESTAMP AS updated_at
FROM TABLE(TUMBLE(TABLE kafka_clickstream_events, DESCRIPTOR(occurred_at), INTERVAL '1' MINUTE))
WHERE campaign_id IS NOT NULL
GROUP BY TUMBLE_START(occurred_at, INTERVAL '1' MINUTE), campaign_id;

INSERT INTO gold.customer_activity_sessions
SELECT
    session_id,
    customer_id,
    campaign_id,
    MIN(occurred_at) AS session_start,
    MAX(occurred_at) AS session_end,
    COUNT(*) AS event_count,
    SUM(CASE WHEN event_type = 'purchase' THEN 1 ELSE 0 END) AS purchase_count,
    CURRENT_TIMESTAMP AS updated_at
FROM kafka_clickstream_events
GROUP BY session_id, customer_id, campaign_id;
