#!/usr/bin/env bash
set -euo pipefail

BOOTSTRAP_SERVERS="${KAFKA_BOOTSTRAP_SERVERS:-kafka:9092}"
KAFKA_BIN="${KAFKA_BIN:-/opt/kafka/bin}"
REPLICATION_FACTOR="${KAFKA_REPLICATION_FACTOR:-1}"
PARTITIONS="${KAFKA_PARTITIONS:-3}"

create_topic() {
  local topic="$1"
  local cleanup_policy="${2:-delete}"
  "${KAFKA_BIN}/kafka-topics.sh" \
    --bootstrap-server "${BOOTSTRAP_SERVERS}" \
    --create \
    --if-not-exists \
    --topic "${topic}" \
    --partitions "${PARTITIONS}" \
    --replication-factor "${REPLICATION_FACTOR}" \
    --config "cleanup.policy=${cleanup_policy}" \
    --config "retention.ms=604800000"
}

create_topic "openlake_connect_configs" compact
create_topic "openlake_connect_offsets" compact
create_topic "openlake_connect_statuses" compact

while IFS= read -r topic; do
  [[ -z "${topic}" || "${topic}" =~ ^# ]] && continue
  create_topic "${topic}"
done < "infra/kafka/topics.txt"

"${KAFKA_BIN}/kafka-topics.sh" --bootstrap-server "${BOOTSTRAP_SERVERS}" --list | sort
