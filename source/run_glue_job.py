from __future__ import absolute_import, print_function

import boto3
import jmespath
import json
import os

from rde.lambdas.continuation import Continuation, Sleep, with_continuation

glue = boto3.client("glue")


def get_arguments(event):
    mapping = json.loads(os.environ["JOB_ARGS"])
    args = {}
    for name,path in mapping.items():
        value = jmespath.search(path, event)
        print("%s is %s" % (path, type(value)))
        if not isinstance(value, str) and not isinstance(value, unicode):
            value = json.dumps(value)
        args[name] = value
    return args

def start_job(event):
    job_name = os.environ["JOB_NAME"]
    args = os.environ.get("JOB_ARGS")
    if "JOB_ARGS" in os.environ:
        return glue.start_job_run(JobName=job_name, Arguments=get_arguments(event))
    else:
        return glue.start_job_run(JobName=job_name)


@with_continuation
def handler(event, cont, context):
    "Runs a glue job and returns the job execution id as a continuation to check for completion"
    if cont is None:
        resp = start_job(event)
        raise(Continuation(resp["JobRunId"]))
    else:
        job_run_id = cont
        resp = glue.get_job_run(JobName=os.environ["JOB_NAME"], RunId=job_run_id)
        
        print(resp)
        state = resp["JobRun"]["JobRunState"]
        
        if state == "SUCCEEDED":
            return event
        elif state == "FAILED":
            raise Exception(resp)
        else:
            raise Sleep()