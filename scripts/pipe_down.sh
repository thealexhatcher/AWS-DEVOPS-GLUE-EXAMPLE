#!/bin/bash

echo "Tearing down pipeline stacks..."

./cfn.py down --stack-name "etl-pipeline-ddb-test"
./cfn.py down --stack-name "etl-pipeline-data-test"
./cfn.py down --stack-name "etl-pipeline-glue-test"

echo "Tearing down ETL pipeline ..."
./cfn.py down --stack-name "etl-pipeline" 

bucket=$(aws cloudformation describe-stacks --stack-name "etl-pipeline-resources"  --query 'Stacks[0].Outputs[?OutputKey==`ArtifactBucket`].OutputValue' --output text) 
if [ ! $bucket = "None" ]; then
    echo "Deleting ETL Artifact Bucket Contents..."
    aws s3 rb s3://$bucket --force 
fi

echo "Tearing down ETL pipeline resources..."
./cfn.py down --stack-name "etl-pipeline-resources" 