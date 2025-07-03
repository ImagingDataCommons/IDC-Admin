#!/usr/bin/env bash

#
# Copyright 2022 Institute for Systems Biology
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

MY_VENV="your python virtualenv path e.g. /Users/username/PythonVEs/googVM"
INSTALL_LIBS="TRUE OR FALSE"
PERSON_ID_FRAGMENT="Full or partial google ID"

ENV_FILE="./launchProjectRoles-SetEnv.sh"

if [ -f "${ENV_FILE}" ]; then
    source "${ENV_FILE}"
fi

export PYTHONPATH=${MY_VENV}/lib

# Install PIP + Dependencies. Make the test TRUE the first time you run this:
if [ "${INSTALL_LIBS}" = "TRUE" ]; then
  pushd ${MY_VENV} > /dev/null
  source bin/activate
  popd > /dev/null
  echo "Installing Python Libraries..."
  python3 -m pip install --upgrade pip
  python3 -m pip install --upgrade wheel
  python3 -m pip install --upgrade google-api-python-client
  python3 -m pip install --upgrade oauth2client
  echo ${PYTHONPATH}
  echo "Libraries Installed"
  deactivate
fi

pushd ${MY_VENV} > /dev/null
source bin/activate
popd > /dev/null
cd ..
pwd
python3 ./find_project_roles.py ${PERSON_ID_FRAGMENT}
deactivate
