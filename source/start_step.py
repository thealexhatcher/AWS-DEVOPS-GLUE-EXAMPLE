from __future__ import absolute_import, print_function

import os
import json
import boto3

from datetime import datetime

SQS = boto3.client('sqs')
SFN = boto3.client('stepfunctions')
S3 = boto3.client('s3')

def handler(event, context):
    print(event)
    record = event["Records"][0]
    handle = record['receiptHandle']
    arn_tokens = record['eventSourceARN'].split(':', 5)
    queue_name = arn_tokens[5]
    account = arn_tokens[4]
    
    print(queue_name)
    print(account)
    
    queue_url = SQS.get_queue_url(QueueName=queue_name, QueueOwnerAWSAccountId=account)["QueueUrl"]
    message = json.loads(record['body'])
    
    if 'Records' in message:
        s3_event = message["Records"][0]
        bucket_name = s3_event['s3']['bucket']['name']
        object_key = s3_event['s3']['object']['key']
        
        resp = S3.get_object(Bucket=bucket_name, Key=object_key)
        raw = resp['Body'].read()
        manifest = json.loads(raw.decode("utf-8-sig"))
        
        sfnarn = os.environ['GLUE_SFN_ARN']
        sfnname = os.environ['GLUE_SFN_NAME']
        sfninput = json.dumps({"manifest": manifest})
        
        ts=datetime.now().strftime("%Y-%m-%d-%H-%M-%S")
        name = "{}__partition-{}__cycle-{}".format(ts, manifest["partition_code"], manifest["cycle_date"])
        SFN.start_execution(stateMachineArn=sfnarn, name=name, input=sfninput)
    
    SQS.delete_message(QueueUrl=queue_url, ReceiptHandle=handle)
    