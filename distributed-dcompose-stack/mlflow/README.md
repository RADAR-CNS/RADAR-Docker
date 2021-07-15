# MLFlow Tracking

This is a deployment of MLFlow tracking service. It uses **Postgresql** where metadata of training models would be stored and **minio s3** where actual models ([artifacts](https://mlflow.org/docs/latest/concepts.html#artifact-locations)) would be stored.


## Usage

1. Clone this repository on the host.
2. `cd` into the directory of the component you want to install on this particular host.
3. Copy the `etc/env.template` file into `.env` and fill out all the configuration properties.
4. Run the Infrastructure by this one line:

```shell
$ docker-compose up -d
```

5. Now to add bucket in minio s3, go to `etc/s3`.
6. Copy the `env.template` file into `.env` and fill out all the configuration properties.
7. Run
   ```shell
   bash run_create_bucket.sh
   ```
