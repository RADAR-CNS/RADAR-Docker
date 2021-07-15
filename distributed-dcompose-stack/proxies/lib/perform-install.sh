#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")/.."

. ../commons/lib/util.sh

echo "OS version: $(uname -a)"
check_command_exists docker
check_command_exists docker-compose

check_config_present .env etc/env.template
copy_template_if_absent etc/webserver/ip-access-control.conf

. ./.env

# Checking provided passwords and environment variables
ensure_env_default SERVER_NAME localhost

echo "==> Checking docker external volumes"
if ! sudo-linux docker volume ls -q | grep -q "^certs$"; then
  sudo-linux docker volume create --name=certs --label certs
fi
if ! sudo-linux docker volume ls -q | grep -q "^certs-data$"; then
  sudo-linux docker volume create --name=certs-data --label certs
fi

if [[ "${1}" == "--register-schemas" ]]; then
  # Initializing Kafka
  echo "==> Setting up topics"
  sudo-linux docker-compose run --rm kafka-init
else
  echo "Not registering Schemas and topics. To register please run again with '--register-schemas' flag"
fi

echo "==> Configure gateway"
# if [[ (-f etc/managementportal/config/keystore.jks) || (-f etc/managementportal/config/keystore.p12) ]]; then
#   ./bin/keys-init
# else
#   echo "No Keystore File Found. Configuring using publicKeyEndpoint..."
#   copy_template_if_absent etc/gateway/radar-is.yml
#   inline_variable 'publicKeyEndpoints:[[:space:]]*' "${MANAGEMENT_PORTAL_URL}managementportal/oauth/token_key" etc/gateway/radar-is.yml
# fi
inline_variable 'managementPortalUrl:[[:space:]]*' "${MANAGEMENT_PORTAL_URL}managementportal" etc/gateway/gateway.yml

echo "==> Configuring nginx"
if [ "${ENABLE_HTTPS:-yes}" = yes ]; then
  cp etc/webserver/nginx.conf.template etc/webserver/nginx.conf
  if ! grep -q 443 etc/webserver/nginx.conf; then
    echo "NGINX configuration does not contain HTTPS configuration. Update the config"
    echo "to template etc/webserver/nginx.conf.template or set ENABLE_HTTPS=no in .env."
    exit 1
  fi
else
  cp etc/webserver/nginx.nossl.conf.template etc/webserver/nginx.conf
  if grep -q 443 etc/webserver/nginx.conf; then
    echo "NGINX configuration does contains HTTPS configuration. Update the config"
    echo "to template etc/webserver/nginx.nossl.conf.template or set ENABLE_HTTPS=yes in .env."
    exit 1
  fi
fi

# Set proper urls
sed_i 's|\${MANAGEMENT_PORTAL_URL}|'"${MANAGEMENT_PORTAL_URL}"'|' etc/webserver/nginx.conf
sed_i 's|\${PORTAINER_URL}|'"${PORTAINER_URL}"'|' etc/webserver/nginx.conf
sed_i 's|\${KAFKA_MANAGER_URL}|'"${KAFKA_MANAGER_URL}"'|' etc/webserver/nginx.conf
sed_i 's|\${RADAR_REST_SOURCES_URL}|'"${RADAR_REST_SOURCES_URL}"'|' etc/webserver/nginx.conf
sed_i 's|\${RADAR_REST_SOURCES_BACKEND_URL}|'"${RADAR_REST_SOURCES_BACKEND_URL}"'|' etc/webserver/nginx.conf
sed_i 's|\${REDCAP_INTEGRATION_APP_URL}|'"${REDCAP_INTEGRATION_APP_URL}"'|' etc/webserver/nginx.conf
sed_i 's|\${NETDATA_MASTER_HOST}|'"${NETDATA_MASTER_HOST}"'|' etc/webserver/nginx.conf
sed_i 's|\${HDFS_NAMENODE_UI_URL}|'"${HDFS_NAMENODE_UI_URL}"'|' etc/webserver/nginx.conf
sed_i 's|\${APPSERVER_ALPHA_URL}|'"${APPSERVER_ALPHA_URL}"'|' etc/webserver/nginx.conf
sed_i 's|\${APPSERVER_URL}|'"${APPSERVER_URL}"'|' etc/webserver/nginx.conf
sed_i 's|\${PUSH_ENDPOINT_URL}|'"${PUSH_ENDPOINT_URL}"'|' etc/webserver/nginx.conf
sed_i 's|\${MLFLOW_URL}|'"${MLFLOW_URL}"'|' etc/webserver/nginx.conf
sed_i 's|\${GRAFANA_DASHBOARD_URL}|'"${GRAFANA_DASHBOARD_URL}"'|' etc/webserver/nginx.conf


# Split into IP and port if exists
NETDATA_MASTER_HOST_SPLIT=($(echo ${NETDATA_MASTER_HOST} | tr ":" "\n"))
sed_i 's|\${NETDATA_MASTER_HOST_IP}|'"${NETDATA_MASTER_HOST_SPLIT[0]}"'|' etc/webserver/nginx.conf

inline_variable 'server_name[[:space:]]*' "${SERVER_NAME};" etc/webserver/nginx.conf
if [ "${ENABLE_HTTPS:-yes}" = yes ]; then
  sed_i 's|\(/etc/letsencrypt/live/\)[^/]*\(/.*\.pem\)|\1'"${SERVER_NAME}"'\2|' etc/webserver/nginx.conf
  init_certificate "${SERVER_NAME}"
else
  # Fill in reverse proxy servers
  proxies=
  for PROXY in ${NGINX_PROXIES:-}; do
    proxies="${proxies}set_real_ip_from ${PROXY}; "
  done
  sed_i "s/^\(\s*\).*# NGINX_PROXIES/\1$proxies# NGINX_PROXIES/" etc/webserver/nginx.conf
fi


echo "==> Configuring Kafka-manager password"
ensure_env_default KAFKA_MANAGER_USERNAME kafkamanager-user
ensure_env_password KAFKA_MANAGER_PASSWORD "Kafka Manager password not set in .env."
sudo-linux docker run --rm httpd:2.4-alpine htpasswd -nbB "${KAFKA_MANAGER_USERNAME}" "${KAFKA_MANAGER_PASSWORD}" > etc/webserver/kafka-manager.htpasswd

echo "==> Configuring Netdata Host monitoring"
if [[ -n "${NETDATA_MASTER_HOST}" ]]; then
  cp "../commons/etc/netdata/slave/stream.conf.template" "etc/netdata/slave/stream.conf"
  cp "../commons/etc/netdata/slave/netdata.conf.template" "etc/netdata/slave/netdata.conf"
  inline_variable "destination[[:space:]]=[[:space:]]" "${NETDATA_MASTER_HOST}" "etc/netdata/slave/stream.conf"
  inline_variable "api[[:space:]]key[[:space:]]=[[:space:]]" "${NETDATA_STREAM_API_KEY}" "etc/netdata/slave/stream.conf"
else
  echo "NetData Master not configured. Not setting up host monitoring."
fi

echo "==> Configuring Netdata Master password"
ensure_env_default NETDATA_USERNAME netdata-user
ensure_env_password NETDATA_PASSWORD "Netdata password not set in .env."
sudo-linux docker run --rm httpd:2.4-alpine htpasswd -nbB "${NETDATA_USERNAME}" "${NETDATA_PASSWORD}" > etc/webserver/netdata.htpasswd

echo "==> Configuring ML Flow password"
ensure_env_default MLFLOW_USERNAME mlflow-user
ensure_env_password MLFLOW_PASSWORD "ML FLOW password not set in .env."
sudo-linux docker run --rm httpd:2.4-alpine htpasswd -nbB "${MLFLOW_USERNAME}" "${MLFLOW_PASSWORD}" > etc/webserver/mlflow.htpasswd

echo "==> Configuring HDFS namnode UI"
ensure_env_default HDFS_NAMENODE_UI_USER hdfsnamenode-user
ensure_env_password HDFS_NAMENODE_UI_PASSWORD "HDFS Namenode UI password not set in .env."
sudo-linux docker run --rm httpd:2.4-alpine htpasswd -nbB "${HDFS_NAMENODE_UI_USER}" "${HDFS_NAMENODE_UI_PASSWORD}" > etc/webserver/hdfs-namenode.htpasswd


echo "==> Configuring Rest Sources Authoriser"
ensure_env_default RADAR_REST_SOURCES_AUTH_USER rest-source-user
ensure_env_password RADAR_REST_SOURCES_AUTH_PASSWORD "Rest Sources authorizer password not set in .env."
sudo-linux docker run --rm httpd:2.4-alpine htpasswd -nbB "${RADAR_REST_SOURCES_AUTH_USER}" "${RADAR_REST_SOURCES_AUTH_PASSWORD}" > etc/webserver/rest-source-authorizer.htpasswd


sudo-linux docker-compose up -d

if [ "${ENABLE_HTTPS:-yes}" = yes ]; then
  request_certificate "${SERVER_NAME}" "${SELF_SIGNED_CERT:-yes}"
fi
