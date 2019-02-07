#!/bin/bash
JOB_SCRIPT=$(realpath $1)
set -e

DATALAKE_STACKNAME="etl-datalake"
DATA_STACKNAME="etl-data"
DDB_STACKNAME="etl-ddb"
JOB_RUNNER_STACKNAME="etl-job-runner"

SSH_ARGS="-i $SSH_PRIVATE_KEY -o StrictHostKeyChecking=no"
ENDPOINT_ADDRESS=$(aws glue get-dev-endpoint --endpoint-name $ENDPOINT_NAME --query DevEndpoint.PublicAddress --output text)

# package and push source to glue dev endpoint
./source/package.sh

OUTPUT_BUCKET=$(./cfn.py output --stack-name $DATA_STACKNAME --output Bucket)
GLUE_DATABSE=$(./cfn.py output --stack-name $DATALAKE_STACKNAME --output GlueDatabase)
JOB_ARGS=$@

scp $SSH_ARGS -r build/lib/* glue@$ENDPOINT_ADDRESS:~
scp $SSH_ARGS $JOB_SCRIPT glue@$ENDPOINT_ADDRESS:~/job.py
time ssh $SSH_ARGS glue@$ENDPOINT_ADDRESS -t gluepython job.py \
  --JOB_NAME test_job \
  --s3_bucket $OUTPUT_BUCKET \
  --s3_prefix $OUTPUT_PREFIX \
  --glue_database $GLUE_DATABSE \
  $JOB_ARGS