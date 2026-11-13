#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../dbt"
dbt deps --profiles-dir .
dbt compile --profiles-dir .
dbt run --profiles-dir .
dbt test --profiles-dir .
