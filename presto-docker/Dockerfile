FROM stag-reg.llsops.com/library/java:8
MAINTAINER jack "jack@hacker.com"

LABEL os="debian"
LABEL app="presto"
LABEL version="0.180"

RUN echo 'deb http://mirrors.aliyun.com/debian/ jessie main non-free contrib\n\
deb http://mirrors.aliyun.com/debian/ jessie-proposed-updates main non-free contrib\n\
deb-src http://mirrors.aliyun.com/debian/ jessie main non-free contrib\n\
deb-src http://mirrors.aliyun.com/debian/ jessie-proposed-updates main non-free contrib\n'\  >/etc/apt/sources.list

RUN java -version

# install python
RUN apt-get update
RUN apt-get install -y python2.7
RUN mv /usr/bin/python2.7 /usr/bin/python
RUN python --version

# install mysql no password prompt
RUN apt-get install -y debconf-utils
# set password same as that in presto catalog below
RUN echo 'mysql-server mysql-server/root_password password 123456' | debconf-set-selections
RUN echo 'mysql-server mysql-server/root_password_again password 123456' | debconf-set-selections
RUN apt-get update && apt-get -y install mysql-server
RUN mysql --version
RUN apt-get install -y mysql-client

# change user root to mysql in order to start mysql properly
RUN touch /var/run/mysqld/mysqld.sock
RUN chown -R mysql:mysql /var/run/mysqld
RUN chown -R mysql:mysql /var/lib/mysql


ENV PRESTO_VERSION 0.180
ENV PRESTO_DIR /opt/presto
ENV PRESTO_ETC_DIR /opt/presto/etc
ENV PRESTO_DATA_DIR /data


RUN mkdir -p ${PRESTO_DIR} ${PRESTO_ETC_DIR}/catalog \
 && curl -s https://repo1.maven.org/maven2/com/facebook/presto/presto-server/${PRESTO_VERSION}/presto-server-${PRESTO_VERSION}.tar.gz \
 | tar --strip 1 -vxzC ${PRESTO_DIR}

WORKDIR ${PRESTO_DIR}
RUN pwd

# config node.properties
RUN echo "node.environment=ci\n\
node.id=faaaafffffff-ffff-ffff-ffff-ffffffffffff\n\
node.data-dir=${PRESTO_DATA_DIR}\n"\ > ${PRESTO_ETC_DIR}/node.properties

# config jvm.config
RUN echo '-server\n\
-Xmx1G\n\
-XX:+UseG1GC\n\
-XX:G1HeapRegionSize=32M\n\
-XX:+UseGCOverheadLimit\n\
-XX:+ExplicitGCInvokesConcurrent\n\
-XX:+HeapDumpOnOutOfMemoryError\n\
-XX:+ExitOnOutOfMemoryError\n'\ > ${PRESTO_ETC_DIR}/jvm.config

# config log.properties
RUN echo 'coordinator=true\n\
node-scheduler.include-coordinator=true\n\
http-server.http.port=8888\n\
query.max-memory=0.4GB\n\
query.max-memory-per-node=0.2GB\n\
discovery-server.enabled=true\n\
discovery.uri=http://127.0.0.1:8888\n'\ > ${PRESTO_ETC_DIR}/config.properties

# config log.properties
RUN echo 'com.facebook.presto=WARN\n'\ > ${PRESTO_ETC_DIR}/log.properties

# Set the following mysql catalog values: password same as mysql-server installation above
# bind the port to 3307 to avoid port has been used invalid in local env 
RUN echo 'connector.name=mysql\n\
connection-url=jdbc:mysql://127.0.0.1:3307\n\
connection-user=root\n\
connection-password=123456\n'\ > ${PRESTO_ETC_DIR}/catalog/mysql.properties

RUN echo "change mysql port from 3306 to 3307 ..."
RUN sed -i 's/^\(port\s*=\s*\).*$/\13307/' /etc/mysql/my.cnf

COPY ./presto_docker_entrypoint.sh /presto_docker_entrypoint.sh
COPY ./test_presto_catalog_init.sql /test_presto_catalog_init.sql
ENTRYPOINT ["bash", "/presto_docker_entrypoint.sh"]
