from __future__ import annotations

import argparse
import json
from pathlib import Path


REQUIRED_PATHS = [
    "README.md",
    "docker-compose.yml",
    ".env.example",
    "Makefile",
    "infra/postgres/init.sql",
    "infra/debezium/postgres-connector.json",
    "infra/kafka/topics.txt",
    "scripts/create_iceberg_tables.sql",
    "dbt/dbt_project.yml",
    "dagster_project/definitions.py",
    "great_expectations/checkpoints/commerce_critical_checkpoint.yml",
    "superset/dashboards/openlake_commerce_dashboard.yaml",
]


def static_check(root: Path) -> None:
    missing = [path for path in REQUIRED_PATHS if not (root / path).exists()]
    if missing:
        raise AssertionError(f"Missing required files: {', '.join(missing)}")

    connector = json.loads((root / "infra/debezium/postgres-connector.json").read_text())
    assert connector["config"]["topic.prefix"] == "openlake_pg"
    topics = (root / "infra/kafka/topics.txt").read_text().splitlines()
    assert "openlake_pg.public.orders" in topics
    assert "openlake.metrics.revenue_per_minute" in topics
    print("Static smoke checks passed.")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--static", action="store_true")
    args = parser.parse_args()
    if args.static:
        static_check(Path(__file__).resolve().parents[1])
    else:
        raise SystemExit("Only --static is implemented for local no-Docker validation.")


if __name__ == "__main__":
    main()
