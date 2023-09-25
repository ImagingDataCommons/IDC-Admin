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

import os
import time

from google.cloud import bigquery

import functions_framework


'''
----------------------------------------------------------------------------------------------
Trigger for HTTP
'''

@functions_framework.http
def web_trigger(request):
    retval = function_core()
    return retval

'''
----------------------------------------------------------------------------------------------
Function core. Log messages
'''

def function_core():
    bq_project = os.environ["BQ_PROJECT"]
    bq_dataset = os.environ["BQ_DATASET"]
    bq_table = os.environ["BQ_TABLE"]

    use_sql = _test_sql(bq_project, bq_dataset, bq_table)
    try:
        results = _bq_harness_with_result(use_sql, True)
        for row in results:
            print("BQ status check: Have result: {}".format(row))
        return "Success"
    except Exception as ex:
        print("BQ status check: FAILURE ALERT: {}".format(str(ex)))
        return "Failure"

'''
----------------------------------------------------------------------------------------------
Test SQL
'''

def _test_sql(project_id, dataset_id, table_name):

    sql = '''
        SELECT PatientID FROM `{}.{}.{}` LIMIT 1
        '''.format(project_id, dataset_id, table_name)
    return sql

'''
----------------------------------------------------------------------------------------------
Use to run queries where we want to get the result back to use (not write into a table)
'''

def _bq_harness_with_result(sql, do_batch):

    """
    Handles all the boilerplate for running a BQ job
    """

    client = bigquery.Client()
    job_config = bigquery.QueryJobConfig()
    if do_batch:
        job_config.priority = bigquery.QueryPriority.BATCH
    location = 'US'

    # API request - starts the query
    query_job = client.query(sql, location=location, job_config=job_config)

    # Query
    job_state = 'NOT_STARTED'
    while job_state != 'DONE':
        query_job = client.get_job(query_job.job_id, location=location)
        job_state = query_job.state
        if job_state != 'DONE':
            time.sleep(10)

    query_job = client.get_job(query_job.job_id, location=location)
    if query_job.error_result is not None:
        raise Exception("BQ JOB FAILED: {}".format(query_job.error_result))

    results = query_job.result()

    return results