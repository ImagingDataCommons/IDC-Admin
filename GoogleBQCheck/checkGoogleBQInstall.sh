#!/usr/bin/env bash

#
# Copyright 2023 Institute for Systems Biology
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#


ADMIN_PROJECT=project_where_function_is_installed

BQ_PROJECT=project_of_bq_table_to_check
BQ_DATASET=dataset_of_bq_table_to_check
BQ_TABLE=table_name_to_check
REGION=region_to_use
SA_NAME=service_account_name
FUNCTION_NAME=function_nam
TIME_ZONE=e_g_America/Los_Angeles
SCHEDULE="e.g.: 0 6 * * *"

DO_SETUP_APIS=FALSE
DO_SERVICE_ACCOUNT=FALSE
DO_SERVICE_ACCOUNT_AS_INVOKER=FALSE
DO_ADDED_ROLES=FALSE
DO_FUNCTION_DEPLOY=TRUE
DO_FUNCTION_TEST=FALSE
DO_SETUP_SCHEDULER=FALSE
#
# This appears to be unnecessary; do not use
#
DO_ENABLE_SCHEDULER_SA=FALSE
DO_SCHEDULER_TEST=FALSE

if [ -f "${HOME}/.bash_profile" ]; then
    source ${HOME}/.bash_profile
fi

# Private, local values for above variables set here:

ENV_FILE="./checkGoogleBQInstall-SetEnv.sh"

if [ -f "${ENV_FILE}" ]; then
    source "${ENV_FILE}"
fi


function setup_schedule {

    SCHEDULE_OP=$1
    # NOTE! For a gen-2 function, you need to provide the non-deterministic URL for the function!
    FUNC_URL=`gcloud functions describe ${FUNCTION_NAME} \
              --gen2 --region ${REGION} --format="value(serviceConfig.uri)" --project ${ADMIN_PROJECT}`

    # Change SCHEDULE_OP to update if you just want to change things after it is created:
    gcloud scheduler jobs ${SCHEDULE_OP} http ${FUNCTION_NAME}-trigger \
      --location ${REGION} \
      --schedule "${SCHEDULE}" \
      --time-zone "${TIME_ZONE}" \
      --uri ${FUNC_URL} \
      --http-method POST \
      --message-body '{"purpose": "scheduled check"}' \
      --oidc-service-account-email ${SA_NAME}@${ADMIN_PROJECT}.iam.gserviceaccount.com \
      --project ${ADMIN_PROJECT}

}


# Enable Cloud Functions, Cloud Build, Artifact Registry, Cloud Run, and Logging APIs.

if [ "${DO_SETUP_APIS}" == "TRUE" ]; then
    echo "---------------------------- CHECKING ENABLED APIs ----------"
    #
    # If you need more APIs enabled, set them up in the same way as below
    #
    echo "Assuming Cloud Functions, Cloud Build, and Logging APIs are already enabled"

    RUN_IS_ENABLED=`gcloud services list --enabled --project=${ADMIN_PROJECT} | grep run.googleapis.com`

    if [ -z "${RUN_IS_ENABLED}" ]; then
      echo "Need to enable Cloud Run"
      gcloud services enable run.googleapis.com --project=${ADMIN_PROJECT}
      echo "Waiting 120 seconds......"
      sleep 120
      echo "Done. Checking...."
      RUN_IS_ENABLED=`gcloud services list --enabled --project=${ADMIN_PROJECT} | grep run.googleapis.com`
      if [ -z "${RUN_IS_ENABLED}" ]; then
        echo "Enabling Cloud Run failed"
        exit 1
      fi
      echo "Cloud Run is now enabled"
    else
      echo "Cloud Run is enabled"
    fi

    REG_IS_ENABLED=`gcloud services list --enabled --project=${ADMIN_PROJECT} | grep artifactregistry.googleapis.com`

    if [ -z "${REG_IS_ENABLED}" ]; then
      echo "Need to enable Artifact Registry"
      gcloud services enable artifactregistry.googleapis.com --project=${ADMIN_PROJECT}
      echo "Waiting 120 seconds......"
      sleep 120
      echo "Done. Checking...."
      REG_IS_ENABLED=`gcloud services list --enabled --project=${ADMIN_PROJECT} | grep artifactregistry.googleapis.com`
      if [ -z "${REG_IS_ENABLED}" ]; then
        echo "Enabling Artifact Registry failed"
        exit 1
      fi
      echo "Artifact Registry is now enabled"
    else
      echo "Artifact Registry is enabled"
    fi
fi


if [ "${DO_SERVICE_ACCOUNT}" == "TRUE" ]; then
    echo "---------------------------- CREATE SERVICE ACCOUNT ----------"
    gcloud iam service-accounts create ${SA_NAME} \
         --display-name "Used to call cloud functions from scheduler" \
         --project ${ADMIN_PROJECT}
fi

if [ "${DO_SERVICE_ACCOUNT_AS_INVOKER}" == "TRUE" ]; then
    echo "---------------------------- ALLOW SERVICE ACCOUNT AS INVOKER ----------"
    #
    # We are setting up a generation 2 function, which operates via Cloud Run, so it needs
    # the run.invoker role (v1 uses cloudfunction.invoker)
    # I was unable to get the "gcloud functions add-iam-policy-binding" to work, so
    # am doing this at the *project* level
    #

    gcloud projects add-iam-policy-binding ${ADMIN_PROJECT} \
        --member serviceAccount:${SA_NAME}@${ADMIN_PROJECT}.iam.gserviceaccount.com \
        --role roles/run.invoker --project ${ADMIN_PROJECT}

    # Not working 3/22/23:
    # gcloud functions add-iam-policy-binding ${FUNCTION_NAME} --region=${REGION} \
    #    --member=serviceAccount:${SA_NAME}@${ADMIN_PROJECT}.iam.gserviceaccount.com \
    #    --role=roles/run.invoker --gen2 --project=${ADMIN_PROJECT}
    #
    # Also appears to not be working: 3/22/23:
    # gcloud functions add-invoker-policy-binding ${FUNCTION_NAME} --region=${REGION} \
    #    --member=serviceAccount:${SA_NAME}@${ADMIN_PROJECT}.iam.gserviceaccount.com --project=${ADMIN_PROJECT}

fi


#
# If specific roles are needed by the service account while running the function, add them here:
#

if [ "${DO_ADDED_ROLES}" == "TRUE" ]; then
    echo "---------------------------- ADD EXTRA ROLES ----------"
    gcloud projects add-iam-policy-binding ${ADMIN_PROJECT} \
        --member serviceAccount:${SA_NAME}@${ADMIN_PROJECT}.iam.gserviceaccount.com \
        --role roles/bigquery.jobUser \
        --project ${ADMIN_PROJECT}

fi


if [ "${DO_FUNCTION_DEPLOY}" == "TRUE" ]; then
    echo "---------------------------- DEPLOY FUNCTION ----------"
    gcloud functions deploy ${FUNCTION_NAME} \
      --gen2 \
      --trigger-http \
      --region ${REGION} \
      --source=. \
      --entry-point=web_trigger \
      --runtime python39 \
      --service-account ${SA_NAME}@${ADMIN_PROJECT}.iam.gserviceaccount.com \
      --no-allow-unauthenticated \
      --set-env-vars="BQ_PROJECT=${BQ_PROJECT},BQ_DATASET=${BQ_DATASET},BQ_TABLE=${BQ_TABLE}" \
      --project ${ADMIN_PROJECT} \
      --verbosity=info

fi

if [ "${DO_FUNCTION_TEST}" == "TRUE" ]; then
    echo "---------------------------- TEST FUNCTION ----------"
    FUNC_URL=`gcloud functions describe ${FUNCTION_NAME} \
             --gen2 --region ${REGION} --format="value(serviceConfig.uri)" --project ${ADMIN_PROJECT}`

    curl -m 70 -X POST ${FUNC_URL} \
      -H "Authorization: bearer $(gcloud auth print-identity-token)" \
      -H "Content-Type: application/json" \
      -d '{ "purpose": "Testing" }'

    echo " "
    echo "Waiting for log output"
    sleep 20
    gcloud beta run services logs read ${FUNCTION_NAME} --limit=10 --region ${REGION} --project ${ADMIN_PROJECT}

fi

if [ "${DO_SETUP_SCHEDULER}" == "TRUE" ]; then
    echo "---------------------------- SETUP SCHEDULER ----------"

    SCHEDULE_JOB_EXISTS=`gcloud scheduler jobs describe ${FUNCTION_NAME}-trigger --location ${REGION} --project ${ADMIN_PROJECT}`
    if [ -z "${SCHEDULE_JOB_EXISTS}" ]; then
        setup_schedule create
    else
        setup_schedule update
    fi
fi

if [ "${DO_ENABLE_SCHEDULER_SA}" == "TRUE" ]; then
    echo "---------------------------- ENABLE SCHEDULER SA ----------"
    #
    # This appears to be unnecessary:
    #
    PROJ_NUM=`gcloud projects describe ${ADMIN_PROJECT} --format="value(projectNumber)"`
    echo $PROJ_NUM

    gcloud iam service-accounts add-iam-policy-binding ${SA_NAME}@${ADMIN_PROJECT}.iam.gserviceaccount.com \
      --member=serviceAccount:service-${PROJ_NUM}@gcp-sa-cloudscheduler.iam.gserviceaccount.com \
      --role=roles/iam.serviceAccountUser --project ${ADMIN_PROJECT}
fi

if [ "${DO_SCHEDULER_TEST}" == "TRUE" ]; then
    echo "---------------------------- TEST SCHEDULER ----------"
    date
    gcloud scheduler jobs run ${FUNCTION_NAME}-trigger --location ${REGION} --project ${ADMIN_PROJECT}
    echo "Waiting for logs to propagate"
    sleep 20
    gcloud beta run services logs read ${FUNCTION_NAME} --limit=10 --region ${REGION} --project ${ADMIN_PROJECT}
fi
