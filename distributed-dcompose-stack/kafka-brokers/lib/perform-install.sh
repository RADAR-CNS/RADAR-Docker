#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")/.."

. ../commons/lib/util.sh

echo "OS version: $(uname -a)"
check_command_exists docker
check_command_exists docker-compose

check_config_present .env etc/env.template

. ./.env

check_parent_exists KAFKA_BROKER_1_LOGS_PATH ${KAFKA_BROKER_1_LOGS_PATH}
check_parent_exists KAFKA_BROKER_2_LOGS_PATH ${KAFKA_BROKER_2_LOGS_PATH}
check_parent_exists KAFKA_BROKER_3_LOGS_PATH ${KAFKA_BROKER_3_LOGS_PATH}

ensure_env_password HOSTNAME "Host Name is not set .env."

echo "==> Configuring Netdata Host monitoring"
if [[ -n "${NETDATA_MASTER_HOST}" ]]; then
  cp "../commons/etc/netdata/slave/stream.conf.template" "etc/netdata/slave/stream.conf"
  cp "../commons/etc/netdata/slave/netdata.conf.template" "etc/netdata/slave/netdata.conf"
  inline_variable "destination[[:space:]]=[[:space:]]" "${NETDATA_MASTER_HOST}" "etc/netdata/slave/stream.conf"
  inline_variable "api[[:space:]]key[[:space:]]=[[:space:]]" "${NETDATA_STREAM_API_KEY}" "etc/netdata/slave/stream.conf"
else
  echo "NetData Master not configured. Not setting up host monitoring."
fi

sudo-linux docker-compose up -d
echo "==> Getting Topic List..."
KAFKA_TOPIC_LIST=$(docker-compose exec -T kafka-1 bash -c 'kafka-topics --list --bootstrap-server localhost:9092')

printf '«%s»\n' "${KAFKA_TOPIC_LIST[@]}"

SCHEMA_TOPIC_EXISTS=(contains-element "_schemas" "${KAFKA_TOPIC_LIST[@]}")

if [[ $SCHEMA_TOPIC_EXISTS -eq 1 ]]; then
  echo "==> Creating _schemas topics as it does not exist..."
  KAFKA_CREATE_SCHEMA_TOPIC_COMMAND='kafka-topics --create --topic _schemas --replication-factor 3 --partitions 1 --bootstrap-server localhost:9092'
  sudo-linux docker-compose exec -T kafka-1 bash -c "${KAFKA_CREATE_SCHEMA_TOPIC_COMMAND}"
else
  echo "==> _schemas topic already exists."
fi

KAFKA_SCHEMA_RETENTION_MS=${KAFKA_SCHEMA_RETENTION_MS:-5400000000}
KAFKA_SCHEMA_RETENTION_CMD='kafka-configs --zookeeper "${KAFKA_ZOOKEEPER_CONNECT}" --entity-type topics --entity-name _schemas --alter --add-config min.compaction.lag.ms='${KAFKA_SCHEMA_RETENTION_MS}',cleanup.policy=compact'
sudo-linux docker-compose exec -T kafka-1 bash -c "$KAFKA_SCHEMA_RETENTION_CMD"

contains-element () {
  local e match="$1"
  shift
  for e; do [[ "$e" == "$match" ]] && return 0; done
  return 1
}
