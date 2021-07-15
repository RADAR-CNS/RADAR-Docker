#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")/.."

. ../commons/lib/util.sh

echo "OS version: $(uname -a)"
check_command_exists docker
check_command_exists docker-compose

check_config_present .env etc/env.template
copy_template_if_absent etc/mongodb-connector/sink-mongo.properties
copy_template_if_absent etc/hdfs-connector/sink-hdfs.properties
copy_template_if_absent etc/fitbit-connector/docker/source-fitbit.properties

. ./.env
echo "==> Configuring MongoDB Connector"
# Update sink-mongo.properties
ensure_variable 'mongo.username=' $HOTSTORAGE_USERNAME etc/mongodb-connector/sink-mongo.properties
ensure_variable 'mongo.password=' $HOTSTORAGE_PASSWORD etc/mongodb-connector/sink-mongo.properties
ensure_variable 'mongo.database=' $HOTSTORAGE_NAME etc/mongodb-connector/sink-mongo.properties
ensure_variable 'mongo.host=' $HOTSTORAGE_HOST etc/mongodb-connector/sink-mongo.properties
ensure_variable 'mongo.port=' $HOTSTORAGE_PORT etc/mongodb-connector/sink-mongo.properties

echo "==> Configuring Fitbit Connector"
ensure_variable 'fitbit.api.client=' $FITBIT_API_CLIENT_ID etc/fitbit-connector/docker/source-fitbit.properties
ensure_variable 'fitbit.api.secret=' $FITBIT_API_CLIENT_SECRET etc/fitbit-connector/docker/source-fitbit.properties

KAFKA_INIT_DOCKER_PATH=../../dcompose-stack/radar-cp-hadoop-stack/images/radar-kafka-init
sudo-linux docker build ${KAFKA_INIT_DOCKER_PATH} -t radarbase/kafka-init:${RADAR_SCHEMAS_VERSION}

KAFKA_INIT_OPTS=(
    --rm -v "$PWD/etc/schema:/schema/conf"
    radarbase/kafka-init:${RADAR_SCHEMAS_VERSION}
  )

# Set topics
if [ -z "${COMBINED_AGG_TOPIC_LIST}"]; then
  COMBINED_AGG_TOPIC_LIST=$(sudo-linux docker run "${KAFKA_INIT_OPTS[@]}" list_aggregated.sh 2>/dev/null | tail -n 1)
  if [ -n "${RADAR_AGG_TOPIC_LIST}" ]; then
    COMBINED_AGG_TOPIC_LIST="${RADAR_AGG_TOPIC_LIST},${COMBINED_AGG_TOPIC_LIST}"
  fi
fi
ensure_variable 'topics=' "${COMBINED_AGG_TOPIC_LIST}" etc/mongodb-connector/sink-mongo.properties

echo "==> Configuring HDFS Connector"
ensure_variable 'hdfs.url=' $HDFS_NAMENODE_URL etc/hdfs-connector/sink-hdfs.properties
ensure_variable 'hdfs.url=' $HDFS_NAMENODE_URL etc/hdfs-connector/sink-hdfs-high.properties
ensure_variable 'hdfs.url=' $HDFS_NAMENODE_URL etc/hdfs-connector/sink-hdfs-low.properties
ensure_variable 'hdfs.url=' $HDFS_NAMENODE_URL etc/hdfs-connector/sink-hdfs-med.properties

if [ -z "${COMBINED_RAW_TOPIC_LIST}"]; then
  COMBINED_RAW_TOPIC_LIST=$(sudo-linux docker run "${KAFKA_INIT_OPTS[@]}" list_raw.sh 2>/dev/null | tail -n 1)
  if [ -n "${RADAR_RAW_TOPIC_LIST}" ]; then
    COMBINED_RAW_TOPIC_LIST="${RADAR_RAW_TOPIC_LIST},${COMBINED_RAW_TOPIC_LIST}"
  fi
fi
ensure_variable 'topics=' "${COMBINED_RAW_TOPIC_LIST}" etc/hdfs-connector/sink-hdfs.properties

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
