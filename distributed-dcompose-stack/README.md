# Distributed RADAR-Docker deployment

This is a very simple deployment of components of RADAR-base platform on distributed hosts in docker containers. This enable the platform to be horizontally scalable and also to plugin in services which are not part of RADAR stack to components in the RADAR stack.
This is simple to use and does not require any special expertise (like kubernetes or terraform) and can be deployed anywhere.

## Current limitations

- There is no provisioning system involved. All the hardware will need to be provisioned manually or by using a third-party tool like Terraform or Vagrant on the cloud provider of your choice (aws, gcp, openstack, etc). On the plus side, this enables distributed deployments on bare-metal hardwares.

- There is limited security at the application level. So, for instance, there is no security in Kafka brokers and it's clients or in the HDFS cluster. Security can be added externally using IP address restrictions, Security Groups, Firewalls and others.

## Description

The following table describes each of the components of the distributed stack.

| Component                             | Description                                                                                                                                                                                                                             | Services                                                                                                                                         | Open Ports                                                                                       | Pre-requisites                                                 | Dependencies                                                                                                                                      | Recommended Disks                                                                                                                                                                                     |
|---------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------|----------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| [kafka-brokers](/kafka-brokers)       | Consists of exposed Kafka brokers and Zookeeper ensemble                                                                                                                                                                                | kafka-1, kafka-2, kafka-3, zookeeper-1, zookeeper-2, zookeeper-3                                                                                 | Internal Network - 9092, 9093, 9094, 2181, 2182, 2183 External Network - None                    | Docker, Docker Compose                                         | None                                                                                                                                              | Mount a single block device on docker path `/var/lib/docker` as zookeeper data is stored in docker volumes and 3 other block devices for each path of the kafka broker logs path as set in the `.env` file.                  |
| [connectors](/connectors)             | Consists of all the kafka-connect instances. HDFS connector, Fitbit Connector and Mongodb connector                                                                                                                                     | radar-mongodb-connector, radar-hdfs-connector,  radar-fitbit-connector                                                                           | None                                                                                             | Docker, Docker Compose                                         | [kafka-brokers](/kafka-brokers), [hdfs-namenode](/hdfs-namenode), [hdfs-datanode](/hdfs-datanode), [frontend](/frontend), [dashboard](/dashboard) | A small size block device mounted on docker path `/var/lib/docker` as Fitbit connector stores offsets in docker volumes.                                                                              |
| [hdfs-namenode](/hdfs-namenode)       | Hadoop File System Name Node                                                                                                                                                                                                            | hdfs-namenode                                                                                                                                    | Internal Network - 8020, 9870, 8022 External Network - None                                      | Docker, Docker Compose                                         | None                                                                                                                                              | Two small size block devices mounted on `HDFS_NAME_DIR_1=/usr/local/var/lib/docker/hdfs-name-1` `HDFS_NAME_DIR_2=/usr/local/var/lib/docker/hdfs-name-2` or whatever you configure the namenode paths. |
| [hdfs-datanode](/hdfs-datanode)       | Hadoop File System Data Nodes. This contains docker config for a single Datanode. These can be **deployed several times on different hosts** to add multiple data nodes.                                                                | hdfs-datanode                                                                                                                                    | Internal Network - 9864, 9866, 9867, 50010, 50020, 50475 External Network - None                             | Docker, Docker Compose                                         | [hdfs-namenode](/hdfs-namenode)                                                                                                                   | A single large size block device mounted on `HDFS_DATA_DIR_1=/usr/local/var/lib/docker/hdfs-data`  or wherever the data node path is configured.                                                      |
| [dashboard](/dashboard)               | Consists of services required to accumulate the data and display the dashboard. You can add more Streams applications on a different hosts and they will rebalance the computations between themselves making it horizontally scalable. | hotstorage, rest-api, dashboard, radar-backend-stream                                                                                            | Internal Network - 80, 8080, 27017 External Network - None                                       | Docker, Docker Compose                                         | [proxies](/proxies), [frontend](/frontend), [kafka-brokers](/kafka-brokers)                                                                       | A single large size block device mounted on `MONGODB_DIR=/usr/local/var/lib/docker/mongodb` or whatever you configure the MongoDb path. This will be used to store aggregated data.                   |
| [frontend](/frontend)                 | Consists of all the services which require user interaction in the frontend(through browsers). Services like Management Portal, Rest Source Authoriser and their backends. Also includes an SMTP mail server.                           | smtp, managementportal-app, radarbase-postgresql, catalog-server, radar-rest-sources-backend,  radar-rest-sources-authorizer, redcap-integration | Internal Network - 25, 8080, 8090, 9000, 9010 External Network - None (May expose in the future) | Docker, Docker Compose, Java (JDK or JRE required for keytool) | None                                                                                                                                              | A single medium size block device mounted on `MP_POSTGRES_DIR=/usr/local/var/lib/docker/postgres` or whatever you configure the postgres path.                                                        |
| [proxies](/proxies)                   | Consists of services used for proxying information like nginx reverse proxy, gateway, rest-proxy, etc. This also contains radar kafka-init for initialising the topics and schemas.                                                     | schema-registry-1, rest-proxy-1, kafka-init, gateway, webserver                                                                                  | Internal Network - 8081, 8082 External Network - 80, 443                                         | Docker, Docker Compose                                         | [kafka-brokers](/kafka-brokers), [frontend](/frontend), <All services that need to be  proxied by the webserver>                                  | None                                                                                                                                                                                                  |
| [data](/data)                         | Consists of services, utilities and wrappers for extracting and restructuring data from HDFS in RADAR platform. Provides the HDFS-Restructure application in 3 different configurations.                                                | radar-output                                                                                                                                     | None                                                                                             | Docker, Docker Compose                                         | [hdfs-namenode](/hdfs-namenode)                                                                                                                   | A single large size block device mounted on `RESTRUCTURE_OUTPUT_DIR=output`  or whatever the output path is configured. Alternatively, you can mount network storage at the path.                     |
| [admin-and-others](/admin-and-others) | Consists of all the services to monitor and manage the RADAR-base platform.                                                                                                                                                             | radar-backend-monitor, portainer, kafka-manager, netdata-master                                                                                  | Internal Network - 9000, 9001, 19999 External Network - None (May expose in future)              | Docker, Docker Compose                                         | [kafka-brokers](/kafka-brokers), [proxies](/proxies)                                                                                              | A small size block device mounted on docker path `/var/lib/docker` as some components store data in docker volumes.                                                                                   |


- For more information on the services in each component, you can explore through the `[component-name]/docker-compose.yml` file.
- For more information on Usage and Configuration of each component please look at the component's `[component-name]/README.md` file.

## Usage

The installation of each of the components has similar steps-

1. Clone this repository on the host.
2. `cd` into the directory of the component you want to install on this particular host.
3. Copy the `etc/env.template` file into `.env` and fill out all the configuration properties.
4. Configure any other component-specific parts which can be found under `README.md` in each component(eg - `kafka-brokers/README.md`)
5. Install the components by running `./bin/install.sh`. Note that some components may need root permissions to install.
   If you run into an error while installing, try running as root `sudo ./bin/install.sh`.

### Order of deployments

Although the dependencies mentioned in the table above should give a good idea of the order of deployment of each component. There can sometimes be cyclic dependencies, but these should not be bothered with much since the `restart` policy on docker containers is set to `always`, so if a service is failing because one of it's dependencies is not deployed yet (and hence unavailable), it will start working automatically when the dependency is deployed.

## Administration

The routine administration of services in each of the components can be done directly using `docker-compose` and `docker` commands.

## Monitoring

For the purpose of monitoring, [Netdata](https://github.com/netdata/netdata) is provided. Each of the components, runs a Netdata instance as a `slave` in `headless-collector` mode (no webserver or database). This does not keep record of the metrics locally but streams all the metrics to the `master` Netdata instance which can be found in the [admin-and-others](/admin-and-others) component.

First generate a new Random UUID to use a API key for streaming by using linux program `uuidgen`

After that, for the Netdata master in [admin-and-others](/admin-and-others) component set the `NETDATA_STREAM_API_KEY` in `.env` file and run `./bin/install.sh`. You may need to resart the `netdata-master` container if it's already running for the changes to take effect.

After that, for each of the components which are slaves (i.e - `kafka-brokers`, `connectors`, `dashboard`, `frontend`, `proxies`), configure the `NETDATA_MASTER_HOST` as the IP address of the host where [admin-and-others](/admin-and-others) component is installed and `NETDATA_STREAM_API_KEY` as the same key generated above. You may need to resart the `netdata-slave` container if it's already running for the changes to take effect.

Then you will be able to go to `<proxies-component-ip-or-url>/netdata` and monitor multiple hosts. These are available in the drop-down at the top-left of the Netdata panel as shown below.

![Netdata Multiple Hosts](/img/netdata.png)

## Alerting

### SMTP server
A common **SMTP server** is exposed in the [frontend](/frontend) component at port 25. This can be configured once and all other components can use this to relay the mails. The following alerting tools will use this to send alerting emails.

### Backend Monitor
The backend monitor is deployed in the [admin-and-others](/admin-and-others) component of the stack. It can be used to monitor different Kafka topics (and hence data streams) to alert when certain thresholds are passed. Currently, disconnection and battery level monitors are included. Please see the README in the component for more info.

### Health Check
A script for checking the health of docker containers(and notifying in case of unhealthy) is provided in `/commons/lib/check-health.sh`. It also comes bundled with `systemd` configuration for running as a systemd service. This can be configured and run on each component to monitor any downtimes/failures of services.

To enable system health notifications to Slack, install its [Incoming Webhooks app](https://api.slack.com/incoming-webhooks). With the webhook URL that you configure there, set in `/commons/.env`:

  ```shell
  HEALTHCHECK_SLACK_NOTIFY=yes
  HEALTHCHECK_SLACK_WEBHOOK_URL=https://...
  ```
To configure the Email health notifications settings, add the following in the `/commons/.env` file:
  ```shell
  SERVER_NAME=
  MAINTAINER_EMAIL=
  SMTP_SERVER_HOST=
  ```
where,
- `COMPONENT_NAME` is the your component name where you are configuring this. This should exactly match the component's name as in the path. For example `admin-and-others`.
- `MAINTAINER_EMAIL` is the email address to send the notification to.
- `SMTP_SERVER_HOST` is the IP/Hostname of the SMTP relay server. So in this case, the IP/Hostname of the [frontend](/frontend) component.

The script uses [swaks](http://www.jetmore.org/john/code/swaks/) to send mails through the SMTP relay provided in frontend component. So this will need to be installed on each host where the script is to be run. Installing is easy by running `sudo apt-get install -y swaks`.

To run as a `Systemd` service, run the `.commons/bin/install-systemd-wrappers.sh` to setup the systemd wrappers for health check.

If not running the script as a `systemd` service, it can also be run as a job in `crontab`.

### NetData Alerts
Alerting is also provided with Netdata Health Monitoring. These can be configured for the Netdata master instance provided in the [admin-and-others](/admin-and-others) component. By default, Alerting by email is provided. To configure it, add the following to the `.env` file -
  ```shell
  MAINTAINER_EMAIL=
  SMTP_SERVER_HOST=
  ```
These are the same configs as mentioned in the [Health Check section](#health-check)

Alerts can also be received through Slack. But these are disabled by default. To enable and configure, add the following to the `.env` file -
  ```shell
  NETDATA_ALERT_SLACK_ENABLE=YES
  NETDATA_ALERT_SLACK_WEBHOOK=https://hooks.slack.com/services/XXXXXXXX/XXXXXXXX/XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
  NETDATA_ALERT_SLACK_CHANNEL="# #netdata-alarms"
  ```
Replace the `NETDATA_ALERT_SLACK_WEBHOOK` with the actual webhook that you generate from slack. For more info, take a look at [official docs](https://docs.netdata.cloud/health/notifications/slack/).

## Updates

This section describes instructions on how to perform some of the most frequently required updates.

### Schemas

Since schemas are central part of RADAR-base platform, there are multiple places where changes are required in case of a version change for radar-schemas. Please respect the ordering of these updates -

- `[proxies](/proxies)` - Update the `RADAR_SCHEMAS_VERSION` in `.env` file to the desired version and run the `./bin/install.sh`. Here, radar-schemas are used by kafka-init.

- `[connectors](/connectors)` - Update the `RADAR_SCHEMAS_VERSION` in `.env` file to the desired version and run the `./bin/install.sh`. You may need to restart the containers for the config changes to take effect by running `docker-compose restart`. Here radar-schemas are used during connectors initialisation to determine the topics.

- `[frontend](/frontend)` - Update the `RADAR_SCHEMAS_VERSION` in `.env` file to the desired version and recreate the containers for the config changes to take effect by running `docker-compose up -d --force-recreate --no-deps catalog-server`. Here radar-schemas are used by catalog server.