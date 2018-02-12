#!/bin/bash

current_dir=`cd $(dirname $0);pwd`

cd $current_dir/../

echo "init environment variables for dev & unit test..."
export DOCKER_COMPOSE=1
export SQL_BUFFET_UNIT_TEST=1
export S3_PORT=4572
export S3_HOST=localstack

echo "start sqlbuffet worker..."
export C_FORCE_ROOT="true"
MYSQL_HOST='mysql'
bash sbin/wait-for.sh $MYSQL_HOST:3306 -t 120
bash sbin/wait-for.sh $S3_HOST:$S3_PORT -t 60

echo "init localstack aws s3 bucket if not exists..."
aws s3api --endpoint http://$S3_HOST:4572  create-bucket --bucket sqlbuffet
aws s3 --endpoint http://$S3_HOST:4572 ls

celery -A app.query.query_worker worker --loglevel=INFO
