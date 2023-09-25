"""

Copyright 2023, Institute for Systems Biology

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

"""

import sys

from googleapiclient import discovery

'''
By running "gcloud auth application-default login --billing-project xxx-xxx" on your laptop, that will use
your personal credentials instead of SA credentials for Python scripts.
Note gcloud auth login lets you do command-line stuff as yourself on your
laptop, but not run Python scripts.
Just don't run gcloud auth application-default login on a cloud VM,
since that starts using personal credentials on a VM. And don't
do gcloud auth activate-service-account on your laptop, since then
your personal laptop starts using an SA under the covers on thelaptop,
which is confusing to track down.

credentials location: /Users/xxxx/.config/gcloud/application_default_credentials.json

To switch back: gcloud auth application-default revoke
'''

def main(args):

    if len(args) != 4:
        print(" Usage : %s <admin_project> <type> <staffer>" % args[0])
        sys.exit(-1)

    project = args[1]
    channel_type = args[2]
    staffer = args[3]

    service = discovery.build("monitoring", "v3")
    request = service.projects().notificationChannels().list(name="projects/{}".format(project))
    response = request.execute()
    for channel in response['notificationChannels']:
        if (channel['displayName'].find(staffer) == 0) and (channel['type'] == channel_type.lower()):
            return channel['name']
    raise Exception("not found")

if __name__ == '__main__':
    print(main(sys.argv))