#!/bin/bash
set -e

ENDPOINT_NAME="glue-dev-endpoint"
ENDPOINT_ADDRESS=$(aws glue get-dev-endpoint --endpoint-name $ENDPOINT_NAME --query DevEndpoint.PublicAddress --output text)
ssh -i $SSH_PRIVATE_KEY -o StrictHostKeyChecking=no glue@$ENDPOINT_ADDRESS
