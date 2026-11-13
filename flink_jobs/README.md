# Flink Jobs

The Flink profile consumes Debezium JSON topics from Kafka and writes normalized metrics into Iceberg tables through the Polaris REST catalog.

Submit the main job:

```bash
make flink-job
```

The base Flink image does not bundle every Kafka/Iceberg connector. For a fully offline setup, place the matching connector JARs in `infra/flink/lib/` and rebuild/restart the profile. The SQL is kept in `flink_jobs/sql/` so the streaming logic is reviewable even before connector JARs are added.
