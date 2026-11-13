#!/usr/bin/env bash
set -euo pipefail

python scripts/smoke_test.py --static
docker compose config >/dev/null
curl -fsS http://localhost:8000/health
