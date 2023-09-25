#!/usr/bin/env bash

#
# Copyright 2023 Institute for Systems Biology
#
# Licensed under the Apache License, Version 2.0 (the 'License');
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an 'AS IS' BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

ADMIN_PROJECT=project_for_alert
METRIC_NAME=name_of_log_metric
STAFFER=alerting_channel_staffer

if [ -f "${HOME}/.bash_profile" ]; then
    source ${HOME}/.bash_profile
fi

# Private, local values for above variables set here:

ENV_FILE="./googleBQLogAlert-SetEnv.sh"

if [ -f "${ENV_FILE}" ]; then
    source "${ENV_FILE}"
fi


cat <<'__WJRL_END_OF_HERE__' > /tmp/raw_alert.json
{
  "displayName": "Failure of query on PDP",
  "documentation": {
    "content": "PDP Query Failure",
    "mimeType": "text/markdown"
  },
  "conditions": [
    {
      "conditionThreshold": {
        "aggregations": [
          {
            "alignmentPeriod": "60s",
            "perSeriesAligner": "ALIGN_COUNT"
          }
        ],
        "comparison": "COMPARISON_GT",
        "duration": "0s",
        "filter": "resource.type = \"cloud_run_revision\" AND metric.type = \"logging.googleapis.com/user/___METRIC_NAME___\"",
        "thresholdValue": 0.95,
        "trigger": {
          "count": 1
        }
      },
      "displayName": "logging/user/___METRIC_NAME___"
    }
  ],
  "combiner": "OR",
  "enabled": true,
  "notificationChannels": [
     "___ALERT_ONE___",
     "___ALERT_TWO___"
  ],
  "alertStrategy":
  {
    "autoClose": "86400s"
  }
}
__WJRL_END_OF_HERE__


# Get the obscure names to use for the alert notifications. Note this uses a python script, so be
# sure to run "gcloud auth application-default login --billing-project xxx-xxx",
# followed by "gcloud auth application-default revoke" when done.

ALERT_1=`./launchBQAlertNotifications.sh "${ADMIN_PROJECT}" "sms" "${STAFFER}"`
ALERT_2=`./launchBQAlertNotifications.sh "${ADMIN_PROJECT}" "email" "${STAFFER}"`

echo ${ALERT_1}
echo ${ALERT_2}

cat /tmp/raw_alert.json | sed -e "s/___METRIC_NAME___/${METRIC_NAME}/g" | \
                          sed -e "s#___ALERT_ONE___#${ALERT_1}#" | \
                          sed -e "s#___ALERT_TWO___#${ALERT_2}#" > /tmp/alert.json

gcloud alpha monitoring policies create --policy-from-file="/tmp/alert.json" --project ${ADMIN_PROJECT}
rm -f /tmp/raw_alert.json /tmp/alert.json

