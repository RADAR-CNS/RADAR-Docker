#!/bin/bash


# uncomment below when you see any issue with db...
#mlflow db upgrade $DB_URI

mlflow server \
    --backend-store-uri $DB_URI \
    --default-artifact-root $ARTIFACT_STORE \
    --host $SERVER_HOST \
    --port $SERVER_PORT