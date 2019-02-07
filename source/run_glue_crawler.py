"""

NOTE:  Crawlers are used as a way to create the tables after a glue job is run, 
it would be better to create/update the tables directly from the jobs themselves.
"""

from __future__ import absolute_import, print_function

import boto3
import jmespath
import json
import os
import time

from rde.lambdas.continuation import Continuation, Sleep, with_continuation

glue = boto3.client("glue")


def prev_execution_id(resp):
    "Use log prefix for previous execution id"
    return resp["Crawler"].get("LastCrawl", {}).get("MessagePrefix", "missing")


@with_continuation
def handler(event, cont, context):
    "Runs a glue crawler and waits for the crawler state becomes ready"
    name = os.environ["CRAWLER"]
    
    if cont is None:
        resp = glue.get_crawler(Name=name) 
        
        if resp["Crawler"]["State"] == "READY":
            print("Starting crawler...")
            prev_exec_id = prev_execution_id(resp)
            glue.start_crawler(Name=name)
            time.sleep(10)
            raise Continuation(prev_exec_id)
        else:
            print("Waiting for crawler to be ready...")
            print("sleeping...")
            raise Sleep()
    else:
        prev_exec_id = cont
        resp = glue.get_crawler(Name=name) 
        
        # if the execution id hasn't changed, it hasn't ended
        print ("Prev id " + prev_exec_id)
        if prev_exec_id == prev_execution_id(resp):
            raise Sleep()
       
        state = resp["Crawler"]["LastCrawl"]["Status"]
        if state == "SUCCEEDED":
            return event
        else:
            raise Exception(resp)
