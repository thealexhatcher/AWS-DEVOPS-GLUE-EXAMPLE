#!/bin/bash

DATALAKE_STACKNAME="etl-pipeline-glue-test"
DATA_STACKNAME="etl-pipeline-data-test"
DDB_STACKNAME="etl-ddb"

S3_BUCKET=$(./cfn.py output --stack-name $DATA_STACKNAME --output Bucket)

echo "Deleting glue jobs..."
./cfn.py down --stack-name "$DATALAKE_STACKNAME"

./stack/empty_bucket.py  $S3_BUCKET

echo "Deleting local stack infra..."
./cfn.py down --stack-name "$DATA_STACKNAME"
./cfn.py down --stack-name "$DDB_STACKNAME"