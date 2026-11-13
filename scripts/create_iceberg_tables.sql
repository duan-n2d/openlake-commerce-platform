CREATE SCHEMA IF NOT EXISTS iceberg.bronze WITH (location = 's3://openlake/bronze');
CREATE SCHEMA IF NOT EXISTS iceberg.silver WITH (location = 's3://openlake/silver');
CREATE SCHEMA IF NOT EXISTS iceberg.gold WITH (location = 's3://openlake/gold');

CREATE TABLE IF NOT EXISTS iceberg.bronze.raw_cdc_events (
    event_id varchar,
    source_table varchar,
    op varchar,
    payload json,
    source_metadata json,
    event_ts timestamp(6) with time zone,
    ingest_ts timestamp(6) with time zone
)
WITH (
    format = 'PARQUET',
    partitioning = ARRAY['source_table', 'day(event_ts)']
);

CREATE TABLE IF NOT EXISTS iceberg.silver.orders (
    order_id varchar,
    customer_id varchar,
    campaign_id varchar,
    order_status varchar,
    order_total decimal(12, 2),
    currency varchar,
    ordered_at timestamp(6) with time zone,
    updated_at timestamp(6) with time zone,
    record_updated_at timestamp(6) with time zone
)
WITH (
    format = 'PARQUET',
    partitioning = ARRAY['day(ordered_at)']
);

CREATE TABLE IF NOT EXISTS iceberg.silver.payments (
    payment_id varchar,
    order_id varchar,
    payment_method varchar,
    payment_status varchar,
    amount decimal(12, 2),
    failure_reason varchar,
    processed_at timestamp(6) with time zone,
    updated_at timestamp(6) with time zone
)
WITH (
    format = 'PARQUET',
    partitioning = ARRAY['day(processed_at)']
);

CREATE TABLE IF NOT EXISTS iceberg.silver.inventory (
    inventory_id varchar,
    product_id varchar,
    warehouse_code varchar,
    quantity_on_hand integer,
    reorder_threshold integer,
    updated_at timestamp(6) with time zone
)
WITH (
    format = 'PARQUET',
    partitioning = ARRAY['warehouse_code']
);

CREATE TABLE IF NOT EXISTS iceberg.gold.realtime_order_metrics (
    metric_minute timestamp(6) with time zone,
    order_count bigint,
    gross_revenue decimal(18, 2),
    captured_revenue decimal(18, 2),
    failed_payment_count bigint,
    payment_success_rate double,
    updated_at timestamp(6) with time zone
)
WITH (
    format = 'PARQUET',
    partitioning = ARRAY['day(metric_minute)']
);

CREATE TABLE IF NOT EXISTS iceberg.gold.inventory_risk_alerts (
    alert_id varchar,
    product_id varchar,
    sku varchar,
    warehouse_code varchar,
    quantity_on_hand integer,
    reorder_threshold integer,
    risk_level varchar,
    alert_ts timestamp(6) with time zone
)
WITH (
    format = 'PARQUET',
    partitioning = ARRAY['risk_level']
);
