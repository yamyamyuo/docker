#!/bin/bash

current_dir=`cd $(dirname $0);pwd`

cd $current_dir/../

echo "init environment variables for dev & unit test..."
export DOCKER_COMPOSE=1
export SQL_BUFFET_UNIT_TEST=1
export S3_PORT=4572
export S3_HOST=localstack
pip install -r requirements.txt

echo "init localstack aws s3 bucket..."
aws s3api --endpoint http://$S3_HOST:4572  create-bucket --bucket sqlbuffet
aws s3 --endpoint http://$S3_HOST:4572 ls

MYSQL_ROOT_PASSWORD='123456'
MYSQL_DATABASE='test'
MYSQL_HOST='mysql'
bash sbin/wait-for.sh $MYSQL_HOST:3306 -t 120
mysql --user=root --password="$MYSQL_ROOT_PASSWORD" --host=$MYSQL_HOST -P3306 "$MYSQL_DATABASE" < sql/ddl.sql
mysql --user=root --password="$MYSQL_ROOT_PASSWORD" --host=$MYSQL_HOST -P3306 "$MYSQL_DATABASE" < tests/test_data_prepare.sql

python manage.py

