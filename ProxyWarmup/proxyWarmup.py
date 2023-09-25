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

from google.cloud import bigquery
import requests
import os
import threading
import tqdm

from google.api_core.exceptions import BadRequest

PROXY_HOST = os.environ["PROXY_HOST"]
BQ_TABLE = os.environ["BQ_TABLE"]
REQUEST_LIMIT_STR = os.getenv('REQUEST_LIMIT', None)
REQUEST_LIMIT = int(REQUEST_LIMIT_STR) if REQUEST_LIMIT_STR is not None else -1
THREAD_COUNT = int(os.environ["THREAD_COUNT"])
REPORT_INCREMENT = int(os.environ["REPORT_INCREMENT"])

'''
----------------------------------------------------------------------------------------------
A class that makes HTTP requests using the specified number of threads
'''

class FilePuller(object):
    """Multithreaded file puller"""
    def __init__(self, thread_count):
        self._lock = threading.Lock()
        self._threads = []
        self._thread_count = thread_count
        self._read_files = 0
        self._total_files = 0
        self._pb = None

    def __str__(self):
        return "FilePuller"

    def reset(self):
        self._threads.clear()
        self._read_files = 0
        self._total_files = 0
        self._pb = None

    def pull_from_source(self, pull_list):
        self._total_files = len(pull_list)
        size = self._total_files // self._thread_count
        size = size if self._total_files % self._thread_count == 0 else size + 1
        self._pb = tqdm.tqdm(total=self._read_files)
        chunks = [pull_list[pos:pos + size] for pos in range(0, self._total_files, size)]
        for i in range(0, self._thread_count):
            if i >= len(chunks):
                break
            th = threading.Thread(target=self._pull_func, args=(chunks[i],))
            self._threads.append(th)

        for i in range(0, len(self._threads)):
            self._threads[i].start()

        for i in range(0, len(self._threads)):
            self._threads[i].join()

        return

    def _pull_func(self, pull_list):
        for url in pull_list:
            make_a_request(url[0], url[1])
            self._bump_size()

    def _bump_size(self):
        with self._lock:
            self._read_files += 1
            self._pb.update(1)

def make_a_request(method, url):
    request_url = '{}{}'.format(PROXY_HOST, url)
    requests.request(method, request_url)
    return

def get_query_results(query):
    try:
        client = bigquery.Client()
        query_job = client.query(query)
        return query_job.result()
    except BadRequest:
        return None

def get_url_sql(url_table):

    return '''
        SELECT method, resource FROM `{}`
        '''.format(url_table)


def main(request):

    sql = get_url_sql(BQ_TABLE)
    res = get_query_results(sql)

    count = 0
    pull_list = []
    for request_row in res:
        if (REQUEST_LIMIT != -1) and (count >= REQUEST_LIMIT):
            print(count, flush=True)
            break
        pull_list.append((request_row[0], request_row[1]))
        if count % REPORT_INCREMENT == 0:
            print(count, flush=True)
        count += 1

    fp = FilePuller(THREAD_COUNT)
    print("Issuing requests", flush=True)
    fp.pull_from_source(pull_list)
    print("Done", flush=True)

    return "Completed"

if __name__ == "__main__":
    main("")