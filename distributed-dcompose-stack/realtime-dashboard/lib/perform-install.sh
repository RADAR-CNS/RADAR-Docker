#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")/.."

. ../commons/lib/util.sh

echo "OS version: $(uname -a)"
check_command_exists docker
check_command_exists docker-compose

check_config_present .env etc/env.template
copy_template_if_absent etc/jdbc-connector/sink-timescale.properties

. ./.env
echo "==> Configuring JDBC Connector"
# Update sink-timescale.properties
ensure_variable 'connection.url=' "jdbc:postgresql://timescaledb:5432/$TIMESCALEDB_DB" etc/jdbc-connector/sink-timescale.properties
ensure_variable 'connection.password=' $TIMESCALEDB_PASSWORD etc/jdbc-connector/sink-timescale.properties
ensure_variable 'topics=' $DASHBOARD_TOPIC_LIST etc/jdbc-connector/sink-timescale.properties

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
