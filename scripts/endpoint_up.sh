#!/bin/bash
set -e
SUBNET_IDS
VPC_ID

ENDPOINT_NAME="glue-dev-endpoint"

chmod 400 $SSH_PRIVATE_KEY
SSH_PUBLIC_KEY=$(ssh-keygen -f $SSH_PRIVATE_KEY -y | cut -d ' ' -f 2)

./cfn.py up \
    --stack-name "$ENDPOINT_STACKNAME" \
    --template "../cfn/glue_endpoint.yml" \
    --iam \
    --parameters - \
<<PARAMETERS
---
SubnetId: "$SUBNET_IDS"
VpcId: "$VPC_ID"
Name: "$ENDPOINT_NAME"
SSHPubKey: "$SSH_PUBLIC_KEY"
DPUs: "10"
PARAMETERS
