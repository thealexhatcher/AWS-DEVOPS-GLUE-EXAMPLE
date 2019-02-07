#!/bin/bash
set -e

echo "Validating templates..."
#./cfn.py validate --template "../cfn/pipe_resources.yml"
#./cfn.py validate --template "../cfn/pipe.yml"

echo "Creating ETL pipeline resources..."
./cfn.py up \
    --stack-name "etl-pipeline-resources" \
    --template "../cfn/pipe_resources.yml" \

echo "Creating ETL pipeline..."
./cfn.py up \
    --stack-name "etl-pipeline" \
    --template "../cfn/pipe.yml" \
    --iam \
    --parameters - \
<<PARAMETERS
---
VpcId: "vpc-0fae16458f9ddb014"
SubnetIds: "subnet-05e67718fe6577af6"
CodeRepo: "AWS-DEVOPS-GLUE-EXAMPLE"
PARAMETERS
