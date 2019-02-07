#!/bin/bash
set -e

cd ../tools/zeppelin
ZEPPELIN_IMAGE_NAME=${ZEPPELIN_IMAGE_NAME:-dev-zeppelin}
docker build -t $ZEPPELIN_IMAGE_NAME .