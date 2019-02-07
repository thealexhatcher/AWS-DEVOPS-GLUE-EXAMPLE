#!/bin/bash

#user=$(aws sts get-caller-identity --query 'UserId' --output text) 
#ID="${user##*:}"
#ID="${ID//-}"
#echo $ID

stackdatalake="etl-datalake"
stackdata="etl-data"
stacktable="etl-ddb"

STP_ARN="$(aws cloudformation describe-stacks --stack-name $stackdatalake --query 'Stacks[0].Outputs[?OutputKey==`ProcessDcStateMachine`].OutputValue' --output text)"
DDB="$(aws cloudformation describe-stacks --stack-name $stacktable --query 'Stacks[0].Outputs[?OutputKey==`TableName`].OutputValue' --output text)"

manifest=$(aws s3 cp s3://rde-datalake-raw/qa/dc_psp/manifest/2018-12-07.json - | cat)
INPUT="{\"manifest\":${manifest:1}}"
echo $INPUT
aws stepfunctions start-execution --state-machine-arn $STP_ARN --input $INPUT

sleep 15
echo "waiting..."
status="NONE"
while true; do
    status="$(aws stepfunctions list-executions --state-machine-arn $STP_ARN --query executions[0].status --output text)"
    if [ $status = "FAILED" ] || [ $status = "TIMED_OUT" ] || [ $status = "ABORTED" ]; then
        echo $status
        exit 1
    elif [ $status = "RUNNING" ] ; then
        printf "." 
        sleep 30
    else
        echo $status
        break
    fi
done

echo "DDB Item Count:" $(aws dynamodb describe-table --table-name $DDB --query 'Table.ItemCount' --output text)