#!/usr/bin/env python
import boto3
import click
import json
import os
import sys
import yaml
import logging
   
logging.getLogger('botocore').setLevel(logging.DEBUG)
logging.getLogger('boto3').setLevel(logging.DEBUG)

from botocore.exceptions import ClientError

client = boto3.client("cloudformation")


@click.group()
def cli():
    pass

@cli.command()
@click.option("--stack-name", "-n", help="CloudFormation stack name", required=True)
@click.option("--template", "-t", help="Path to cloudformation template",
              required=True, type=click.File('r'))
@click.option("--parameters", "-p", help="Path to cloudformation parameters",
              required=False, type=click.File('r'))
@click.option('--iam/--no-iam', default=False)
def up(stack_name, template, parameters, iam):
    args = {"StackName": stack_name}
    
    args["TemplateBody"] = template.read()
    
    params = None
    if parameters:
        data = parameters.read()
        
        if data.startswith("---"):
            params = yaml.load(data)
        else:
            params = json.loads(data)
            
        # if given a normal object, convert it to cfn format
        # otherwise assume it is right
        if isinstance(params, dict):
            args["Parameters"] = [{"ParameterKey":k, "ParameterValue":v} for k,v in params.items()]
        else:
            args["Parameters"] = params
            
    if iam:
        args["Capabilities"] = ['CAPABILITY_IAM']
        
    try:
        client.describe_stacks(StackName=stack_name)
    except:
        action = "create"
    else:
        action = "update"
    
    try:
        deploy_fn = getattr(client, "%s_stack" % action)
        deploy_fn(**args)
        print("'{}' is being {}d".format(stack_name, action))
        if params:
            print("Parameters:")
            print(json.dumps(params, indent=2))
    except ClientError as ex:
        if str(ex).endswith("No updates are to be performed."):
            print("No updates are to be performed on '{}'".format(stack_name))
        else:
            raise ex
    else:
        print("Waiting for {} to finish...".format(action))
        waiter = client.get_waiter("stack_%s_complete" % action)
        waiter.wait(StackName=stack_name)
        print("{} complete".format(action))


@cli.command()
@click.option("--template", "-t", help="Path to cloudformation template",
              required=True, type=click.File('r'))
def validate(template):
    client.validate_template(TemplateBody=template.read())
    

@cli.command()
@click.option("--stack-name", "-n", help="CloudFormation stack name", required=True)
def down(stack_name):
    client.delete_stack(StackName=stack_name)
    waiter = client.get_waiter("stack_delete_complete")
    waiter.wait(StackName=stack_name)
    
@cli.command()
@click.option("--stack-name", "-n", help="CloudFormation stack name", required=True)
@click.option("--output", "-o", help="Specific output value to returne", required=False)
def output(stack_name, output):
    resp = client.describe_stacks(StackName=stack_name)
    outputs = resp["Stacks"][0]["Outputs"]
    
    outputs = dict([(o["OutputKey"], o["OutputValue"]) for o in outputs])
    
    if output is None:
        print(json.dumps(outputs, indent=2))
    else:
        print(outputs[output])


if __name__ == "__main__":
    cli()