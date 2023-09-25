#!/usr/bin/env bash
#
# Copyright 2020-2022, Institute for Systems Biology
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

USER=warmup
ZONE="your_zone"
VM=proxy-warmup-machine
PROJECT="project-id"

USER_AND_MACHINE=${USER}@${VM}

if [ -f "${HOME}/.bash_profile" ]; then
    source ${HOME}/.bash_profile
fi

ENV_FILE="./ProxyWarmup-SetEnv.sh"

if [ -f "${ENV_FILE}" ]; then
    source "${ENV_FILE}"
fi

cat runWarmup.sh | sed "s#__FILL_IN_HOST__#${PROXY_HOST}#" \
    | sed "s#__FILL_IN_BQ__#${BQ_TABLE}#" \
    | sed "s#__FILL_IN_THREAD__#${THREAD_COUNT}#" \
    | sed "s#__FILL_IN_REPORT__#${REPORT_INCREMENT}#" > runWarmup-SetEnv.sh

echo "Uploading scripts to ${VM}"
echo "proxyWarmup.py..."
gcloud compute scp proxyWarmup.py ${USER_AND_MACHINE}: --zone ${ZONE} --project ${PROJECT}
echo "runWarmup.sh..."
gcloud compute scp runWarmup-SetEnv.sh ${USER_AND_MACHINE}: --zone ${ZONE} --project ${PROJECT}
gcloud compute ssh --project ${PROJECT} --zone ${ZONE} ${USER_AND_MACHINE} --command 'chmod u+x runWarmup-SetEnv.sh'

echo "Running warmup script on ${VM}"
gcloud compute ssh --project ${PROJECT} --zone ${ZONE} ${USER_AND_MACHINE} --command './runWarmup-SetEnv.sh'
echo "---------STATUS for ${VM} was $?"

rm runWarmup-SetEnv.sh
