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

export MY_VENV=~/pyVenvForThree
export PYTHONPATH=.:${MY_VENV}/lib

export PROXY_HOST=__FILL_IN_HOST__
export BQ_TABLE=__FILL_IN_BQ__
export THREAD_COUNT=__FILL_IN_THREAD__
export REPORT_INCREMENT=__FILL_IN_REPORT__
#OPTIONAL, for testing:
#export REQUEST_LIMIT=100

cd ~
pushd ${MY_VENV} > /dev/null
source bin/activate
popd > /dev/null
python3 ~/proxyWarmup.py
deactivate
