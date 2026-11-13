CREATE TABLE IF NOT EXISTS kafka_orders (
    order_id STRING,
    customer_id STRING,
    campaign_id STRING,
    order_status STRING,
    order_total DECIMAL(12, 2),
    currency STRING,
    ordered_at TIMESTAMP_LTZ(3),
    updated_at TIMESTAMP_LTZ(3),
    WATERMARK FOR updated_at AS updated_at - INTERVAL '5' SECOND
) WITH (
    'connector' = 'kafka',
    'topic' = 'openlake_pg.public.orders',
    'properties.bootstrap.servers' = 'kafka:9092',
    'scan.startup.mode' = 'earliest-offset',
    'format' = 'debezium-json'
);

CREATE TABLE IF NOT EXISTS kafka_payments (
    payment_id STRING,
    order_id STRING,
    payment_method STRING,
    payment_status STRING,
    amount DECIMAL(12, 2),
    failure_reason STRING,
    processed_at TIMESTAMP_LTZ(3),
    updated_at TIMESTAMP_LTZ(3),
    WATERMARK FOR updated_at AS updated_at - INTERVAL '5' SECOND
) WITH (
    'connector' = 'kafka',
    'topic' = 'openlake_pg.public.payments',
    'properties.bootstrap.servers' = 'kafka:9092',
    'scan.startup.mode' = 'earliest-offset',
    'format' = 'debezium-json'
);

CREATE TABLE IF NOT EXISTS kafka_inventory (
    inventory_id STRING,
    product_id STRING,
    warehouse_code STRING,
    quantity_on_hand INT,
    reorder_threshold INT,
    updated_at TIMESTAMP_LTZ(3),
    WATERMARK FOR updated_at AS updated_at - INTERVAL '5' SECOND
) WITH (
    'connector' = 'kafka',
    'topic' = 'openlake_pg.public.inventory',
    'properties.bootstrap.servers' = 'kafka:9092',
    'scan.startup.mode' = 'earliest-offset',
    'format' = 'debezium-json'
);

CREATE TABLE IF NOT EXISTS kafka_clickstream_events (
    event_id STRING,
    session_id STRING,
    customer_id STRING,
    campaign_id STRING,
    product_id STRING,
    event_type STRING,
    page_url STRING,
    user_agent STRING,
    occurred_at TIMESTAMP_LTZ(3),
    WATERMARK FOR occurred_at AS occurred_at - INTERVAL '5' SECOND
) WITH (
    'connector' = 'kafka',
    'topic' = 'openlake_pg.public.clickstream_events',
    'properties.bootstrap.servers' = 'kafka:9092',
    'scan.startup.mode' = 'earliest-offset',
    'format' = 'debezium-json'
);

CREATE TABLE IF NOT EXISTS silver.orders (
    order_id STRING,
    customer_id STRING,
    campaign_id STRING,
    order_status STRING,
    order_total DECIMAL(12, 2),
    currency STRING,
    ordered_at TIMESTAMP_LTZ(3),
    updated_at TIMESTAMP_LTZ(3),
    record_updated_at TIMESTAMP_LTZ(3),
    PRIMARY KEY (order_id) NOT ENFORCED
) WITH ('format-version' = '2');

CREATE TABLE IF NOT EXISTS silver.payments (
    payment_id STRING,
    order_id STRING,
    payment_method STRING,
    payment_status STRING,
    amount DECIMAL(12, 2),
    failure_reason STRING,
    processed_at TIMESTAMP_LTZ(3),
    updated_at TIMESTAMP_LTZ(3),
    PRIMARY KEY (payment_id) NOT ENFORCED
) WITH ('format-version' = '2');

CREATE TABLE IF NOT EXISTS silver.inventory (
    inventory_id STRING,
    product_id STRING,
    warehouse_code STRING,
    quantity_on_hand INT,
    reorder_threshold INT,
    updated_at TIMESTAMP_LTZ(3),
    PRIMARY KEY (inventory_id) NOT ENFORCED
) WITH ('format-version' = '2');

INSERT INTO silver.orders
SELECT *, CURRENT_TIMESTAMP
FROM kafka_orders;

INSERT INTO silver.payments
SELECT *
FROM kafka_payments;

INSERT INTO silver.inventory
SELECT *
FROM kafka_inventory;
