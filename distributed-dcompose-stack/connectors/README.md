# Connectors

This component comprises of all the Kafka Connectors (Source and Sink) that are part of the RADAR-base platform.

## Services

Services included are-
1. [radar-mongodb-connector](https://github.com/RADAR-base/MongoDb-Sink-Connector) - Connects kafka with mongodb. Used for sinking all the aggregated data from kafka-topics into MongoDb. This is then exposed by rest-api.
2. [radar-hdfs-connector](https://github.com/RADAR-base/RADAR-HDFS-Sink-Connector) - Connects kafka to HDFS (hadoop). Used to dump all the raw topic data from Kafka into HDFS. This is later extracted from the HDFS and restructured.
3. [radar-fitbit-connector](https://github.com/RADAR-base/RADAR-REST-Connector) - Connects Fitbit Web Api to Kafka. This is a source connector used to pull data from Fitbit web API (the source) and put it in Kafka.
4. [netdata-slave](https://docs.netdata.cloud/streaming/) - Sends monitoring metrics to the Netdata master instance deployed in `admin-and-others` component.


## Configuration
This component can be configured in the following steps -

1. Copy the `./etc/env.template` to `./.env`
2. Specify the required values according to your deployment.

### Fitbit Connector
For using Fitbit connector, You will need to configure the `FITBIT_API_CLIENT_ID` and `FITBIT_API_CLIENT_SECRET` in the `.env` file. These can be obtained from Fitbit when you register your app.

After that you will need to configure the users. By default, these are configured to be read from the [Rest Source Authoriser](https://github.com/RADAR-base/RADAR-Rest-Source-Auth) which is deployed as part of the `frontend` component. Please register the users there and point the fitbit connector to that by changing the following in the [source-fitbit.properties.template](./etc/fitbit-connector/docker/source-fitbit.properties.template) file-

```
# Set this to the URL of your deployment of RADAR Rest Authoriser (in the frontend component)
fitbit.user.repository.url=http://radar-rest-sources-backend:8080/
```

## Usage

After configuring the values above, run the services by -

```shell
sudo ./bin/install.sh
```

