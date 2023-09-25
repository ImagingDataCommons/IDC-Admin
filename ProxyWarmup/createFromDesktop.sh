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
ZONE="your-zone"
VM=proxy-warmup-machine
PROJECT="project-id"
MACHINE_DESC="Spools up proxy instances"
USER_AND_MACHINE=${USER}@${VM}

if [ -f "${HOME}/.bash_profile" ]; then
    source ${HOME}/.bash_profile
fi

ENV_FILE="./ProxyWarmup-SetEnv.sh"

if [ -f "${ENV_FILE}" ]; then
    source "${ENV_FILE}"
fi

#
# Spin up the VM:
#

echo "Creating ${VM}"
gcloud compute instances create "${VM}"  \
--description="${MACHINE_DESC}" \
--zone="${ZONE}" \
--machine-type="n2-standard-8" \
--image-project="debian-cloud" \
--image-family="debian-10" \
--project="${PROJECT}" \
--scopes="bigquery"

echo "Waiting 10 seconds..."
sleep 10

echo "Uploading scripts to ${VM}"
echo "setupVM.sh..."
gcloud compute scp setupVM.sh ${USER_AND_MACHINE}: --zone ${ZONE} --project ${PROJECT}
gcloud compute ssh --project ${PROJECT} --zone ${ZONE} ${USER_AND_MACHINE} --command 'chmod u+x setupVM.sh'

echo "Running setup script on ${VM}"
gcloud compute ssh --project ${PROJECT} --zone ${ZONE} ${USER_AND_MACHINE} --command './setupVM.sh'
echo "---------STATUS for ${VM} was $?"
