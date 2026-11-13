param(
    [Parameter(Position = 0)]
    [ValidateSet("up", "down", "restart", "logs", "seed", "generate", "topics", "register-connector", "flink-job", "dbt-run", "dbt-test", "ge-check", "dagster", "superset", "api", "smoke", "compose-config", "clean")]
    [string]$Command = "up"
)

$ErrorActionPreference = "Stop"

switch ($Command) {
    "up" { docker compose --profile core up -d }
    "down" { docker compose down }
    "restart" { docker compose down; docker compose --profile core up -d }
    "logs" { docker compose logs -f --tail=200 }
    "seed" { python scripts/init_postgres.py }
    "generate" { python -m data_generator.cli generate --continuous }
    "topics" { docker compose exec kafka /bin/bash /opt/openlake/scripts/create_kafka_topics.sh }
    "register-connector" { python scripts/register_debezium_connector.py }
    "flink-job" { docker compose --profile streaming exec flink-jobmanager flink run -py /opt/flink/usrlib/jobs/commerce_streaming_job.py }
    "dbt-run" { Push-Location dbt; dbt run --profiles-dir .; Pop-Location }
    "dbt-test" { Push-Location dbt; dbt test --profiles-dir .; Pop-Location }
    "ge-check" { python scripts/run_quality_checks.py --suite critical }
    "dagster" { docker compose --profile quality up -d dagster }
    "superset" { docker compose --profile bi up -d superset }
    "api" { uvicorn api.main:app --host 0.0.0.0 --port 8000 --reload }
    "smoke" { python scripts/smoke_test.py --static }
    "compose-config" { docker compose config }
    "clean" { docker compose down -v --remove-orphans }
}
