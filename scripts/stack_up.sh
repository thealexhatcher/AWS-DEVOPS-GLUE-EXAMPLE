#!/bin/bash
set -e

DATALAKE_STACKNAME="etl-datalake"
DATA_STACKNAME="etl-data"
DDB_STACKNAME="etl-ddb"

echo "Standing up development stack for environment '${AWS_ENV}'"

echo "Validating templates..."
./cfn.py validate --template "../cfn/data.yml"
./cfn.py validate --template "../cfn/ddb_table.yml"
./cfn.py validate --template "../cfn/glue_datalake.yml"


echo "Creating base stacks..."
./cfn.py up \
    --stack-name $DATA_STACKNAME \
    --template "../cfn/data.yml"
   
./cfn.py up \
    --stack-name $DDB_STACKNAME \
    --template "../cfn/ddb_table.yml"


S3_BUCKET=$(./cfn.py output --stack-name $DATA_STACKNAME --output Bucket)
OUTPUT_TABLE=$(./cfn.py output --stack-name $DDB_STACKNAME --output TableName)
QUEUE=$(./cfn.py output --stack-name $DATA_STACKNAME --output Queue)


echo "Copying code to bucket..."
./source/package.sh
UUID=$(uuidgen)
aws s3 cp build/pylib.zip s3://$S3_BUCKET/pylib-${UUID}.zip
for f in `find build/lib/rde/jobs/ -name "*.py" -not -name "__init__.py"`; do
    aws s3 cp $f s3://$S3_BUCKET/$(basename $f)
done
aws s3 cp ddb/dc_ddb_import.scala s3://$S3_BUCKET

echo "Setting up test data..."
aws s3 sync $DEV_DATASET s3://$S3_BUCKET/raw/ --include "*" --exclude "*.json"


echo "Creating Glue jobs..."
./cfn.py up \
    --stack-name "$DATALAKE_STACKNAME" \
    --template "../cfn/glue_datalake.yml" \
    --iam \
    --parameters - \
<<PARAMETERS
---
SourceBucket: $S3_BUCKET
ProcessQueueArn: $QUEUE
ProcessedBucket: $S3_BUCKET
ProcessedKeyPrefix: "datalake"
ProcessScript: "process.py"
ImportScript: "import.scala"
OutputTable: $OUTPUT_TABLE
PARAMETERS