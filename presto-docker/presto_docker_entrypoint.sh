#!/bin/bash

echo "change own of mysql ..."
chown -R mysql:mysql /var/lib/mysql

echo "start mysql ..."
/etc/init.d/mysql start

echo "restore dbdump ..."
mysql --port 3306 --user root -p123456 < /test_presto_catalog_init.sql

echo "start presto ..."
./bin/launcher run
