from __future__ import annotations

import os
import subprocess
from pathlib import Path

from dagster import AssetExecutionContext, Definitions, ScheduleDefinition, asset, define_asset_job

ROOT = Path(__file__).resolve().parents[1]


def _run(command: list[str], cwd: Path = ROOT) -> None:
    subprocess.run(command, cwd=cwd, check=True)


@asset(group_name="source")
def postgres_seed(context: AssetExecutionContext) -> None:
    _run(["python", "scripts/init_postgres.py"])
    context.log.info("PostgreSQL source seed verified.")


@asset(group_name="cdc", deps=[postgres_seed])
def kafka_topics(context: AssetExecutionContext) -> None:
    _run(["bash", "scripts/create_kafka_topics.sh"])
    context.log.info("Kafka CDC and metric topics are available.")


@asset(group_name="cdc", deps=[kafka_topics])
def debezium_connector(context: AssetExecutionContext) -> None:
    _run(["python", "scripts/register_debezium_connector.py"])
    context.log.info("Debezium connector registered or updated.")


@asset(group_name="lakehouse", deps=[debezium_connector])
def iceberg_tables(context: AssetExecutionContext) -> None:
    trino_cli = os.getenv("TRINO_CLI", "trino")
    _run([trino_cli, "--server", "http://localhost:8080", "-f", "scripts/create_iceberg_tables.sql"])
    context.log.info("Iceberg bronze, silver, and gold tables are available.")


@asset(group_name="streaming", deps=[iceberg_tables])
def flink_realtime_metrics(context: AssetExecutionContext) -> None:
    _run(["docker", "compose", "--profile", "streaming", "exec", "flink-jobmanager", "flink", "run", "-py", "/opt/flink/usrlib/jobs/commerce_streaming_job.py"])
    context.log.info("Flink streaming job submitted.")


@asset(group_name="transform", deps=[iceberg_tables])
def dbt_gold_marts(context: AssetExecutionContext) -> None:
    _run(["dbt", "run", "--profiles-dir", "."], cwd=ROOT / "dbt")
    _run(["dbt", "test", "--profiles-dir", "."], cwd=ROOT / "dbt")
    context.log.info("dbt gold marts built and tested.")


@asset(group_name="quality", deps=[dbt_gold_marts])
def great_expectations_checkpoint(context: AssetExecutionContext) -> None:
    _run(["python", "scripts/run_quality_checks.py", "--suite", "critical"])
    context.log.info("Great Expectations critical checkpoint completed.")


@asset(group_name="metadata", deps=[dbt_gold_marts, great_expectations_checkpoint])
def datahub_metadata_ingestion(context: AssetExecutionContext) -> None:
    _run(["datahub", "ingest", "-c", "infra/datahub/recipes/dbt.yml"])
    context.log.info("DataHub dbt metadata ingestion completed.")


openlake_asset_job = define_asset_job("openlake_commerce_full_refresh")
hourly_realtime_schedule = ScheduleDefinition(
    job=openlake_asset_job,
    cron_schedule="0 * * * *",
    name="hourly_openlake_asset_refresh",
)

defs = Definitions(
    assets=[
        postgres_seed,
        kafka_topics,
        debezium_connector,
        iceberg_tables,
        flink_realtime_metrics,
        dbt_gold_marts,
        great_expectations_checkpoint,
        datahub_metadata_ingestion,
    ],
    jobs=[openlake_asset_job],
    schedules=[hourly_realtime_schedule],
)
