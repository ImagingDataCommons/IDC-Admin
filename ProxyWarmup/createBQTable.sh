#!/usr/bin/env bash

PROJECT="project-id"

#table of ip, method, resource:
BQ_TABLE_SOURCE="project:dataset.table-for-startup-requests"
BQ_TABLE_PROJECT=${PROJECT}
BQ_TABLE_DATASET="your_table_dataset"
BQ_TABLE_TABLE="your-table-name"

if [ -f "${HOME}/.bash_profile" ]; then
    source ${HOME}/.bash_profile
fi

# Private, local values for above variables set here:

ENV_FILE="./ProxyWarmup-SetEnv.sh"

if [ -f "${ENV_FILE}" ]; then
    source "${ENV_FILE}"
fi

bq --location=US mk --dataset ${PROJECT}:${BQ_TABLE_DATASET}

bq cp ${BQ_TABLE_SOURCE} ${PROJECT}:${BQ_TABLE_DATASET}.${BQ_TABLE_TABLE}

