# Dashboard

This Component is now Deprecated. Please use the `realtime-dashboard` component.
-


This component comprises of all the services which are required directly or indirectly for working of the [RADAR Realtime Dashboard](https://github.com/RADAR-base/RADAR-Dashboard).

## Services

Services included are-
1. `hotstorage` - Currently this is a MongoDb instance which is used for storing windowed aggregated data which is exposed by the Rest-Api.
2. `rest-api` - Exposes the aggregate data in MongoDb using REST endpoints.
3. `dashboard` - The Web Interface for displaying the aggregate data obtained using the `rest-api`.
4. `radar-backend-stream` - The [Kafka Streams]() application for aggregating the raw data into windowed aggregates. These are stored back into kafka which is then consumed by the mongodb-connector.
5. [netdata-slave](https://docs.netdata.cloud/streaming/) - Sends monitoring metrics to the Netdata master instance deployed in `admin-and-others` component.

## Configuration
This component can be configured in the following steps -

1. Copy the `./etc/env.template` to `./.env`
2. Specify the required values according to your deployment.

### RADAR Backend Streams
Copy the `./etc/radar-backend/radar.yml.template` file to `./etc/radar-backend/radar.yml` and edit the configuration as required. For more information on how to configure it, please take a look at the [README](https://github.com/RADAR-base/RADAR-Backend#radar-backend-streams).

### Rest API
Most of the configuration of Rest API is done automatically based on the values provided in the `.env` file.
By default, it will use the public key endpoint of the management portal to get the public keys for verification of the tokens. But if you want to use the actual keys just copy over the `keystore` file into `etc/managementportal/config` and run the `./bin/install.sh` command.