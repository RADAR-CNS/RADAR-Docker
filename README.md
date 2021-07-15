# RADAR-Docker 2.2.0

[![Build Status](https://github.com/RADAR-base/RADAR-Docker/actions/workflows/main.yml/badge.svg?branch=master)](https://github.com/RADAR-base/RADAR-Docker/actions/workflows/main.yml?query=branch%3Amaster)

The dockerized RADAR stack for deploying the RADAR-base platform. Component repositories can be found at [RADAR-base DockerHub org](https://hub.docker.com/u/radarbase/dashboard/)

## Installation instructions 
To install RADAR-base stack, do the following: 

1. Install [Docker Engine](https://docs.docker.com/engine/installation/)
2. Install `docker-compose` using the [installation guide](https://docs.docker.com/compose/install/) or by following our [wiki](https://github.com/RADAR-base/RADAR-Docker/wiki/How-to-set-up-docker-on-ubuntu#install-docker-compose).
3. Verify the Docker installation by running on the command-line:

    ```shell
    docker --version
    docker-compose --version
    ```
    This should show Docker version 1.12 or later and docker-compose version 1.9.0 or later.
4. Install [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git) for your platform.
    1. For Ubuntu

        ```shell
        sudo apt-get install git
        ```
	
5. Clone [RADAR-Docker](https://github.com/RADAR-base/RADAR-Docker) repository from GitHub.

    ```shell
    git clone https://github.com/RADAR-base/RADAR-Docker.git
    ```

6. Install required component stack following the instructions below.

## Usage

RADAR-Docker currently offers two component stacks to run.

1. A Docker-compose for components from [Confluent Kafka Platform](http://docs.confluent.io/3.1.0/) community 
2. A Docker-compose for components from RADAR-base platform.

> **Note**: on macOS, remove `sudo` from all `docker` and `docker-compose` commands in the usage instructions below.

### Confluent Kafka platform
Confluent Kafka platform offers integration of the basic components for streaming such as Zookeeper, Kafka brokers, Schema registry and REST-Proxy. 

Run this stack in a single-node setup on the command-line:

```shell
cd RADAR-Docker/dcompose-stack/radar-cp-stack/
sudo docker-compose up -d
```

To stop this stack, run:

```shell
sudo docker-compose down
```

### RADAR-base platform

In addition to Confluent Kafka platform components, RADAR-base platform offers

* RADAR-HDFS-Connector - Cold storage of selected streams in Hadoop data storage,
* RADAR-MongoDB-Connector - Hot storage of selected streams in MongoDB,
* [RADAR-Dashboard](https://github.com/RADAR-base/RADAR-Dashboard),
* RADAR-Streams - real-time aggregated streams,
* RADAR-Monitor - Status monitors,
* [RADAR-HotStorage](https://github.com/RADAR-base/RADAR-HotStorage) via MongoDB, 
* [RADAR-REST API](https://github.com/RADAR-base/RADAR-RestApi),
* A Hadoop cluster, and
* An email server.
* Management Portal - A web portal to manage patient monitoring studies.
* RADAR-Gateway - A validating gateway to allow only valid and authentic data to the platform
* Catalog server - A Service to share source-types configured in the platform.
To run RADAR-base stack in a single node setup:

1. Navigate to `radar-cp-hadoop-stack`:

    ```shell
    cd RADAR-Docker/dcompose-stack/radar-cp-hadoop-stack/
    ```
2. Follow the README instructions there for correct configuration.

### Logging

Set up a logging service by going to the `dcompose-stack/logging` directory and follow the README there.

## Work in progress

The two following stacks will not work on with only Docker and docker-compose. For the Kerberos stack, the Kerberos image is not public. For the multi-host setup, also docker-swarm and Docker beta versions are needed.

### Kerberized stack

In this setup, Kerberos is used to secure the connections between the Kafka brokers, Zookeeper and the Kafka REST API. Unfortunately, the Kerberos container from Confluent is not publicly available, so an alternative has to be found here.

```shell
$ cd wip/radar-cp-sasl-stack/
$ docker-compose up
```

### Multi-host setup
While the singlehost deloyment found in this repository will not provide the scalability beyond a certain limited context, additional options are available for scaling-out the platform components:

For multi-host setups please refer to the repositories here:
#### Kubernetes
To deploy RADAR-base containers on a Kubernetes cluster: 
[RADAR-Kubernetes](https://github.com/RADAR-base/RADAR-Kubernetes)

#### Teraform
To deploy RADAR-base components on separate VM Docker hosts in a variety of public and private cloud providers example Teraform scripts are available here:
[RADAR-Terraform](https://github.com/RADAR-base/RADAR-Terraform)



