#!/bin/bash
cd ..

ZEPPELIN_IMAGE_NAME=${ZEPPELIN_IMAGE_NAME:-dev-zeppelin}
ZEPPELIN_CONTAINER_NAME=${ZEPPELIN_CONTAINER_NAME:-dev-zeppelin}
ENDPOINT_ADDRESS=$(aws glue get-dev-endpoint --endpoint-name $ENDPOINT_NAME --query DevEndpoint.PublicAddress --output text)

mkdir -p tools/zeppelin/logs
mkdir -p tools/zeppelin/notebooks

echo "Starting zeppelin container '$ZEPPELIN_CONTAINER_NAME', connecting '$ENDPOINT_ADDRESS'..."

docker container inspect "$ZEPPELIN_CONTAINER_NAME" &>/dev/null
if  [ "$?" == "0" ]; then
    echo "container already running, restarting it"
    docker stop "$ZEPPELIN_CONTAINER_NAME" &>/dev/null
    docker rm "$ZEPPELIN_CONTAINER_NAME" &>/dev/null
fi

docker run -d \
    -p 8080:8080 \
    -e ENDPOINT_ADDRESS=$ENDPOINT_ADDRESS \
	-v ${PWD}/tools/zeppelin/logs:/logs \
	-v ${PWD}/tools/zeppelin/notebooks:/notebook \
	--name $ZEPPELIN_CONTAINER_NAME \
	$ZEPPELIN_IMAGE_NAME

docker logs $ZEPPELIN_CONTAINER_NAME --follow
