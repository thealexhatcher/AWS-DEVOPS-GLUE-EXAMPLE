#!/bin/bash
set -e

echo "Standing up VPC stack for environment '${AWS_ENV}'"

echo "Creating VPC..."
./cfn.py down \
    --stack-name "vpc" \