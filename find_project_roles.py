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


from googleapiclient import discovery
from googleapiclient.errors import HttpError
import httplib2
from oauth2client.client import GoogleCredentials
from googleapiclient.discovery import build
import sys

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

   credentials location: /Users/bill/.config/gcloud/application_default_credentials.json

   To switch back: gcloud auth application-default revoke
'''

def get_iam_resource():
    """Returns an Identity Access Management service client for calling the API.
    """
    IAM_SCOPES = [
        'https://www.googleapis.com/auth/iam'
    ]

    credentials = GoogleCredentials.get_application_default().create_scoped(IAM_SCOPES)
    http = httplib2.Http()
    http = credentials.authorize(http)
    service = build_with_retries('iam', 'v1', None, 2, http=http)
    return service


def build_with_retries(service_tag, version_tag, creds, num_retries, http=None):
    service = None
    retries = num_retries
    while (retries > 0) and (service is None):
        retries -= 1
        try:
            if http:
                service = discovery.build(service_tag, version_tag, http=http, cache_discovery=False)
            else:
                service = discovery.build(service_tag, version_tag, credentials=creds, cache_discovery=False)

        except Exception as e:
            print ('{0} (Unexpected) {1}  {2}'.format(service_tag, str(type(e)), str(e)))
            raise e

    return service


def get_crm_resource():
    """
    Returns: a Cloud Resource Manager service client for calling the API.
    """
    credentials = GoogleCredentials.get_application_default()
    return build('cloudresourcemanager', 'v1beta1', credentials=credentials, cache_discovery=False)


def execute_with_retries(req, task, num_retries, http=None):
    resp = None
    while (num_retries > 0) and (resp is None):
        num_retries -= 1
        try:
            # Still got a Deadline Exceeded with num_retries=3. Don't bother!
            if http:
                resp = req.execute(http=http)
            else:
                resp = req.execute()
        except HttpError as e:
            if e.resp.status == 404:
                return None
            else:
                raise e
        except Exception as e:
            print('{0} (Unexpected) {1}  {2}'.format(task, str(type(e)), str(e)))
            raise e

    return resp


def _get_policy(project_id, service, version=1):

    body = {"options": {"requestedPolicyVersion": version}}
    policy = service.projects().getIamPolicy(resource=project_id, body=body).execute()
    return policy

def get_project_roles(gcp_id, crm_service):

    req = crm_service.projects().getIamPolicy(resource=gcp_id, body={})
    iam_policy = execute_with_retries(req, 'GET_IAM_POLICY', 2)
    if isinstance(iam_policy, dict) and 'bindings' in iam_policy:
        bindings = iam_policy['bindings']
    else:
        print("No 'bindings' in iam_policy")
        return {}

    roles = {}

    for val in bindings:
        role = val['role']
        members = val['members']
        roles[role] = []

        for member in members:
            member_parse_list = member.split(':')
            if len(member_parse_list) != 2:
                member_type = member
                email = '__never_ever_a__valid_user_bogomail__@example.com'
            else:
                member_type = member_parse_list[0]
                email = member_parse_list[1].lower()

            roles[role].append({'type': member_type,
                                'email': email})

    return roles


def get_roles(gcp_id, crm_service, person):
    try:
        proj_roles = get_project_roles(gcp_id, crm_service)
    except HttpError as e:
        if e.resp.status == 404:
            return
        else:
            print('{0}: access {1}'.format(gcp_id, str(e.resp.status)))
            return

    for role_type, role_items in proj_roles.items():
        for item in role_items:
            if item['email'].find(person) != -1:
                print ("{} : {} : {}".format(gcp_id, role_type, item['email']), flush=True)

def list_projects(service):

    all_projects = []
    request = service.projects().list()

    while request is not None:
        response = request.execute()

        for project in response.get('projects', []):
            all_projects.append(project['projectId'])

        request = service.projects().list_next(previous_request=request, previous_response=response)

    return all_projects

def main(args):

    if len(args) != 2:
        print(" Usage : %s <google_user_id_fragment>" % args[0])
        sys.exit(-1)

    person = args[1]

    crm_service = get_crm_resource()

    #
    # Note this assumes the person running this has a view into all projects the person might be in:
    #
    project_list = list_projects(crm_service)

    for proj in project_list:
        print("Checking project {}".format(proj), flush=True)
        get_roles(proj, crm_service, person)


if __name__ == '__main__':
    main(sys.argv)
