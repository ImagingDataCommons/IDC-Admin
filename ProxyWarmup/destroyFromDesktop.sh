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

ZONE="your_zone"
VM=proxy-warmup-machine
PROJECT="project-id"

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

echo "Deleting ${VM}"
gcloud compute instances delete "${VM}" --zone="${ZONE}" --project="${PROJECT}" --quiet
echo "---------STATUS for ${VM} was $?"
