FROM conda/miniconda3:latest

ARG SERVER_PORT
ARG SERVER_HOST
ARG DB_URI
ARG AWS_BUCKET_NAME

ENV MLFLOW_HOME=/opt/mlflow
ENV SERVER_PORT=${SERVER_PORT}
ENV SERVER_HOST=${SERVER_HOST}
ENV DB_URI=${DB_URI}
ENV ARTIFACT_STORE=s3://${AWS_BUCKET_NAME}/

RUN apt-get update && apt-get install -y \
    build-essential \
    python3-dev \
    libpq-dev

RUN apt-get -y install python-pip

RUN pip install --upgrade pip

RUN pip install mlflow sqlalchemy psycopg2-binary && \
    mkdir -p ${MLFLOW_HOME}/scripts && \
    #mkdir -p ${FILE_STORE} && \
    mkdir -p ${ARTIFACT_STORE}

COPY ./start.sh ${MLFLOW_HOME}/script/start.sh

RUN chmod +x ${MLFLOW_HOME}/script/start.sh


EXPOSE ${SERVER_PORT}/tcp

#VOLUME ["${MLFLOW_HOME}/scripts/", "${FILE_STORE}", "${ARTIFACT_STORE}"]
VOLUME ["${MLFLOW_HOME}/scripts/", "${ARTIFACT_STORE}"]

WORKDIR ${MLFLOW_HOME}

ENTRYPOINT ["./script/start.sh"]