#!/bin/bash
set -e

ENDPOINT_NAME="glue-dev-endpoint"
ENDPOINT_STACKNAME="glue-dev-endpoint"

echo "Tearing down dev endpoint '$ENDPOINT_NAME'"
echo "deleting cloudformation stack '$ENDPOINT_STACKNAME'"
./cfn.py down --stack-name $ENDPOINT_STACKNAME