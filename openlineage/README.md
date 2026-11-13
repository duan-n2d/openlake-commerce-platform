# OpenLineage

Dagster and dbt can emit OpenLineage events so lineage follows:

`PostgreSQL -> Debezium -> Kafka -> Flink -> Iceberg -> dbt -> Superset/FastAPI`

Local configuration:

```bash
export OPENLINEAGE_URL=http://localhost:5000
export OPENLINEAGE_NAMESPACE=openlake-commerce-local
```

Dagster assets in `dagster_project/definitions.py` map platform steps to materialized datasets. dbt metadata can be emitted through DataHub and OpenLineage-compatible integrations when installed.
