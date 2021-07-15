# Admin And Others

This component comprises of all the services which aid in the administration of the RADAR-base platform.

## Services

Services included are-
1. [radar-backend-monitor](https://github.com/RADAR-base/RADAR-Backend) - For monitoring topics in kafka for different data streams and sending Email notifications to project admins in case of breaking a rule (a rule could be a threshold value).
2. [portainer](https://portainer.readthedocs.io/en/stable/) - For monitoring Docker containers through a web-based interface. Since this is distributed setup additional configuration may be required to set up monitoring of multiple docker remote hosts. Please refer to the [configuration section](#configuration)
3. [kafka-manager](https://github.com/yahoo/kafka-manager) - For managing and monitoring kafka brokers and it's clients. Once running you will need to configure the kafka cluster in the web interface. This will need the URL of the zookeeper nodes.
4. [netdata-master](https://www.netdata.cloud/) - NetData master node for monitoring different hosts. All other hosts are configured as Netdata slaves and stream the metrics to this master. This master is then responsible for exposing this information through a web interface and also for alarms and alerting.

## Configuration

This component can be configured in the following steps -

1. Copy the `./etc/env.template` to `./.env`
2. Specify the required values according to the following table.

| Properties                                                 | Description                                                                                                                                                  | Defaults                         |
|------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------|----------------------------------|
| `ZOOKEEPER_1_HOST`, `ZOOKEEPER_2_HOST`, `ZOOKEEPER_3_HOST` | The zookeeper host urls for the deployed zookeeper ensemble. These are deployed in the `kafka-brokers` component and are available at ports 2181, 2182, 2183 | None                             |
| `SCHEMA_REGISTRY_URL`                                      | The url for schema registry. This deployed in the `proxies` component and should be available at port 8081                                                   | None                             |
| `REST_PROXY_URL`                                           | The url for schema registry. This deployed in the `proxies` component and should be available at port 8082                                                   |                                  |
| `PORTAINER_PASSWORD_HASH`                                  | Password hash to be used for authentication in portainer. This can left out.                                                                                 | Will be prompted during install. |
| `SMTP_SERVER_HOST`                                         | The host name for the SMTP server.  This is deployed in the `frontend` component and should be available at port 25                                              | None                             |
| `NETDATA_STREAM_API_KEY`                                   | A unique key used to identify this particular netdata master instance for Streaming metrics. Can be generated using `uuid` program in linux.                 | None                             |
| `MAINTAINER_EMAIL`                                         | The email address of the server admin or maintainer that will receive the alerts.                                                                            | None                             |
| `NETDATA_ALERT_SLACK_*`                                    | Please refer to Netdata section below for configuring netdata related options.                                                                               | NA                               |

### Radar Backend Monitor

1. Copy the `./etc/radar-backend/radar.yml.template` file to `./etc/radar-backend/radar.yml`
2. Edit the configuration as required. Most of the properties are self-explanatory and also have some limited documentation.

### Netdata
By default, the metrics in netdata are stored in RAM and only 1 hour of history is available. To change that, edit the file [stream.conf.template](/etc/netdata/master/stream.conf.template) as follows -

```ini
# one hour of data for each of the slaves. Change this to your desired value
default history = 3600

# do not save slave metrics on disk. Change this to persist the data.
default memory = ram
```
All the options and their documentation is available [here](https://github.com/netdata/netdata/blob/master/streaming/stream.conf)

#### Alerting
By default, Alerting in Netdata is provided by email. To configure it, add the following to the `.env` file -
```shell
MAINTAINER_EMAIL=
SMTP_SERVER_HOST=
```
These are the same configs as mentioned in the table above.

Alerts can also be received through Slack. But these are disabled by default. To enable and configure, add the following to the `.env` file -
```shell
NETDATA_ALERT_SLACK_ENABLE=YES
NETDATA_ALERT_SLACK_WEBHOOK=https://hooks.slack.com/services/XXXXXXXX/XXXXXXXX/XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
NETDATA_ALERT_SLACK_CHANNEL="# #netdata-alarms"
```
Replace the `NETDATA_ALERT_SLACK_WEBHOOK` with the actual webhook that you generate from slack. For more info, take a look at [official docs](https://docs.netdata.cloud/health/notifications/slack/).

## Usage

After configuring the options as stated above, just run the services using -

```shell
sudo ./bin/install.sh
```



