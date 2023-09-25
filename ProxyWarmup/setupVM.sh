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
# Setup the VM for the manifest script, if it is new:
#

if [ ! -d "${HOME}/pyVenvForThree" ]; then

    #
    # Shut up terminal complaints:
    #

    echo 'debconf debconf/frontend select Noninteractive' | sudo debconf-set-selections
    sudo apt-get install -y locales # gonna get Perl locale complaints while doing this
    sudo localedef -i en_US -f UTF-8 en_US.UTF-8 # shuts up further Perl locale complaints

    sudo apt-get update
    sudo apt-get upgrade -y

    sudo apt-get install -y wget
    sudo apt-get install -y	git

    #
    # Create a virtual environment Python3 stuff:
    #
    # Do not use pip3 to upgrade pip. Does not play well with Debian pip
    #

    sudo apt-get install -y python3-pip

    #
    # We want venv:
    #

    sudo apt-get install -y python3-venv

    #
    # Google packages get the infamous "Failed building wheel for ..." message. SO suggestions
    # for this situation:
    # https://stackoverflow.com/questions/53204916/what-is-the-meaning-of-failed-building-wheel-for-x-in-pip-install
    #
    # pip3 install wheel
    # OR:
    # pip install <package> --no-cache-dir.
    #
    # Using the first option
    #

    cd ~
    python3 -m venv pyVenvForThree
    source pyVenvForThree/bin/activate
    python3 -m pip install --upgrade pip
    python3 -m pip install wheel
    python3 -m pip install requests
    python3 -m pip install google-api-python-client
    python3 -m pip install google-cloud-bigquery
    python3 -m pip install tqdm
    deactivate
fi
