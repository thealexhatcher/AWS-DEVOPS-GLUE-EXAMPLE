#!/bin/bash
set -e

status="NONE"
while true; do
    status="$(aws stepfunctions list-executions --state-machine-arn $1 --query executions[0].status --output text)"
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