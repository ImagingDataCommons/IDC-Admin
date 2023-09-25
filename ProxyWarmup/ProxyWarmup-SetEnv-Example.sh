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
ZONE=your-vm-zone
VM=proxy-warmup-machine
PROJECT=your-project_id

MACHINE_DESC="Spools up proxy instances"
USER_AND_MACHINE=${USER}@${VM}

#source table of ip, method, resource driving the calls:
BQ_TABLE_SOURCE="source_project:source_dataset.table-for-startup-requests"
BQ_TABLE_PROJECT=${PROJECT}
BQ_TABLE_DATASET="your_table_dataset"
BQ_TABLE_TABLE="your-table-name"

#
# Parameters sent to VM:
#

# Use the first one to point to production:
PROXY_HOST=https://your-proxy-host.example.com/
BQ_TABLE=${BQ_TABLE_PROJECT}.${BQ_TABLE_DATASET}.${BQ_TABLE_TABLE}
THREAD_COUNT=40
REPORT_INCREMENT=500
