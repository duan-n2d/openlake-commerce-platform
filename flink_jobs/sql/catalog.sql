CREATE CATALOG openlake WITH (
    'type' = 'iceberg',
    'catalog-type' = 'rest',
    'uri' = 'http://polaris:8181/api/catalog',
    'warehouse' = 'commerce',
    'io-impl' = 'org.apache.iceberg.aws.s3.S3FileIO',
    's3.endpoint' = 'http://minio:9000',
    's3.path-style-access' = 'true',
    's3.access-key-id' = 'minioadmin',
    's3.secret-access-key' = 'minioadmin',
    's3.region' = 'us-east-1'
);

USE CATALOG openlake;

CREATE DATABASE IF NOT EXISTS bronze;
CREATE DATABASE IF NOT EXISTS silver;
CREATE DATABASE IF NOT EXISTS gold;
