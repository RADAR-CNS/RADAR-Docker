#!/bin/bash

# Check if variables exist
if [ -z "$KAFKA_REST_PROXY" ]; then
    echo "KAFKA_REST_PROXY is not defined"
    exit 2
fi

if [ -z "$KAFKA_SCHEMA_REGISTRY" ]; then
    echo "KAFKA_SCHEMA_REGISTRY is not defined"
    exit 4
fi

KAFKA_BROKERS=${KAFKA_BROKERS:-3}

max_timeout=32

tries=10
timeout=1
while true; do
    IFS=, read -r -a array <<< $(curl -s "${KAFKA_REST_PROXY}/brokers" | sed 's/^.*\[\(.*\)\]\}/\1/')
    LENGTH=${#array[@]}
    if [ "$LENGTH" -eq "$KAFKA_BROKERS" ]; then
        echo "Kafka brokers available."
        break
    fi
    tries=$((tries - 1))
    if [ $tries -eq 0 ]; then
        echo "FAILED: KAFKA BROKERs NOT READY."
        exit 5
    fi
    echo "Kafka brokers or Kafka REST proxy not ready. Retrying in ${timeout} seconds."
    sleep $timeout
    if [ $timeout -lt $max_timeout ]; then
        timeout=$((timeout * 2))
    fi
done

tries=10
timeout=1
while true; do
    if wget --spider -q "${KAFKA_SCHEMA_REGISTRY}/subjects" 2>/dev/null; then
        break
    fi
    tries=$((tries - 1))
    if [ $tries -eq 0 ]; then
        echo "FAILED TO REACH SCHEMA REGISTRY. SCHEMAS NOT REGISTERED."
        exit 6
    fi
    echo "Failed to reach schema registry. Retrying in ${timeout} seconds."
    sleep $timeout
    if [ $timeout -lt $max_timeout ]; then
        timeout=$((timeout * 2))
    fi
done


echo "Kafka is available. Ready to go!"
