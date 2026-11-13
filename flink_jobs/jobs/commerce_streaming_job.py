from __future__ import annotations

import os
from pathlib import Path

from pyflink.table import EnvironmentSettings, TableEnvironment


SQL_DIR = Path(__file__).resolve().parents[1] / "sql"


def _statement_sets(script_name: str) -> list[str]:
    text = (SQL_DIR / script_name).read_text(encoding="utf-8")
    return [statement.strip() for statement in text.split(";") if statement.strip()]


def main() -> None:
    settings = EnvironmentSettings.in_streaming_mode()
    table_env = TableEnvironment.create(settings)
    table_env.get_config().set("pipeline.name", "openlake-commerce-streaming")
    table_env.get_config().set("table.local-time-zone", "UTC")

    table_env.get_config().get_configuration().set_string(
        "kafka.bootstrap.servers", os.getenv("KAFKA_BOOTSTRAP_SERVERS", "kafka:9092")
    )

    for script in ("catalog.sql", "bronze_cdc_tables.sql", "realtime_metrics.sql"):
        for statement in _statement_sets(script):
            table_env.execute_sql(statement)


if __name__ == "__main__":
    main()
