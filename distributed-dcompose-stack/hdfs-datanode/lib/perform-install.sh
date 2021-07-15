#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")/.."

. ../commons/lib/util.sh

echo "OS version: $(uname -a)"
check_command_exists docker
check_command_exists docker-compose

# Initialize and check all config files
check_config_present .env etc/env.template

. ./.env

check_parent_exists HDFS_DATA_DIR_1 ${HDFS_DATA_DIR_1}

ensure_env_password HDFS_NAMENODE_1_STATIC_IP "NAMENODE IP or host is not set .env."

sudo-linux docker-compose up -d
