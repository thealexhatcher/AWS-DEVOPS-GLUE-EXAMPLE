#!/bin/bash
set -e

echo "Standing up VPC stack for environment '${AWS_ENV}'"

echo "Validating templates..."
./cfn.py validate --template "../cfn/vpc.yml"

echo "Creating VPC..."
./cfn.py up \
    --stack-name "vpc" \
    --template "../cfn/vpc.yml" \