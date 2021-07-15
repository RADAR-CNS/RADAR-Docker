# Connectors

This component comprises of all the components needed to run the real time Grafana dashboard.

## Services

Services included are-

1. [radar-jdbc-connector](https://github.com/RADAR-base/RADAR-JDBC-Connector) - This connector is based on Confluent's Kafka JDBC connector with additional functionalities to support TimescaleDB databases.
2. [radar-grafana](https://github.com/RADAR-base/RADAR-Grafana) - Grafana dashboard based on the original Grafana docker image with pre-defined dashboards and datasources (timescaledb).
3. [timescaledb](https://docs.timescale.com/) - TimescaleDB is an open-source relational database for time-series data.

## Configuration

This component can be configured in the following steps -

1. Copy the `./etc/env.template` to `./.env`
2. Specify the required values according to your deployment.

### JDBC/TimescaleDB Connector

You must modify the `.env` file..

## Usage

After configuring the values above, run the services by -

```shell
sudo ./bin/install.sh
```
