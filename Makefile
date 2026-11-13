SHELL := /bin/bash
COMPOSE := docker compose
PROJECT := openlake-commerce-platform

.PHONY: up down restart logs seed generate flink-job dbt-run dbt-test ge-check dagster superset clean smoke compose-config topics register-connector api

up:
	$(COMPOSE) --profile core up -d

down:
	$(COMPOSE) down

restart:
	$(COMPOSE) down && $(COMPOSE) --profile core up -d

logs:
	$(COMPOSE) logs -f --tail=200

seed:
	python scripts/init_postgres.py

generate:
	python -m data_generator.cli generate --continuous

topics:
	bash scripts/create_kafka_topics.sh

register-connector:
	python scripts/register_debezium_connector.py

flink-job:
	$(COMPOSE) --profile streaming exec flink-jobmanager flink run -py /opt/flink/usrlib/jobs/commerce_streaming_job.py

dbt-run:
	cd dbt && dbt run --profiles-dir .

dbt-test:
	cd dbt && dbt test --profiles-dir .

ge-check:
	python scripts/run_quality_checks.py --suite critical

dagster:
	$(COMPOSE) --profile quality up -d dagster

superset:
	$(COMPOSE) --profile bi up -d superset

api:
	uvicorn api.main:app --host 0.0.0.0 --port 8000 --reload

compose-config:
	$(COMPOSE) config

smoke:
	python scripts/smoke_test.py --static

clean:
	$(COMPOSE) down -v --remove-orphans
