FROM apache/zeppelin:0.7.3

EXPOSE 8080

ENV ZEPPELIN_LOG_DIR /log
ENV ZEPPELIN_NOTEBOOK_DIR /notebook

WORKDIR ${Z_HOME}
ADD private_key.pem .
ADD interpreter.json conf/interpreter.json
RUN chmod 400 private_key.pem
CMD ssh -v -i private_key.pem -o StrictHostKeyChecking=no -NTL 9007:169.254.76.1:9007 glue@$ENDPOINT_ADDRESS & \
    bin/zeppelin.sh