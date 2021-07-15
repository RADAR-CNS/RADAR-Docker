#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")/.."

. ../commons/lib/util.sh

echo "OS version: $(uname -a)"
check_command_exists docker
check_command_exists docker-compose

check_config_present .env etc/env.template

. ./.env

check_parent_exists FEATURE_DB_DATA_DIR ${FEATURE_DB_DATA_DIR}

ensure_env_password HOSTNAME "Host Name is not set .env."
ensure_env_password KAFKA_1_HOST "Kafka host not set in .env."
ensure_env_password KAFKA_2_HOST "Kafka host not set in .env."
ensure_env_password KAFKA_3_HOST "Kafka host not set in .env."
ensure_env_password SCHEMA_REGISTRY_URL "Schema Registry URL not set in .env."

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