系统中经常出现各种依赖的组件，比如mysql、hive、kafka等等，docker能够快速地将一个环境部署到其他机器上，节省了大量的安装环境的时间。只需要写一个“recipe”，docker就能如法炮制，复制一模一样的环境到你的机器上，让程序员更加专注于开发。
下面开始手把手建立一个presto的docker image。Presto是Facebook开源的一个SQL查询引擎, 不清楚presto是什么的可以查看https://prestodb.io
## Dockerfile制作
#### 1. 基础环境准备
```
FROM registry.docker-cn.com/library/java:8
MAINTAINER Jack "Jack@aaa.com"

LABEL os="debian"
LABEL app="presto"
LABEL version="0.180"

RUN echo 'deb http://mirrors.aliyun.com/debian/ jessie main non-free contrib\n\
deb http://mirrors.aliyun.com/debian/ jessie-proposed-updates main non-free contrib\n\
deb-src http://mirrors.aliyun.com/debian/ jessie main non-free contrib\n\
deb-src http://mirrors.aliyun.com/debian/ jessie-proposed-updates main non-free contrib\n'\  >/etc/apt/sources.list

RUN java -version
```
Dockerfile就像一个列表清单，告诉docker从头到尾建立一个项目都需要准备什么东西，最后怎么跑起来等。最开始我们要确定一个项目是基于什么环境的，比如presto依赖java开发环境，所以我们用 `From registry.docker-cn.com/library/java:latest` , 这样就不需要去搭建java环境了，比如有些开源组件是python写的，那么这个`FROM`就应该去docker registry搜索python相关的image。利用好`FROM` 可以让我们的docker制作过程快速很多，比如我可以先制作一个python flask web开发的环境，如果有其他的docker image也依赖这个基础环境, 就可以直接拿过来用了, 而且构建的速度快很多~


- [MAINTAINER](https://docs.docker.com/engine/reference/builder/#maintainer-deprecated) 设置docker镜像的作者信息. 已经deprecated, 官方建议使用[LABEL](https://docs.docker.com/engine/reference/builder/#label) 
- [LABEL](https://docs.docker.com/engine/reference/builder/#label) 是给这个docker image打上标签，标签的作用方面统一管理docker images, 可以打多个标签
- [RUN](https://docs.docker.com/engine/reference/builder/#run) RUN会执行任何shell命令, 并commit结果, 随后的命令就能够获取到该执行结果.
- 镜像加速: 国内的网速你懂的, 需要修改软件源为国内镜像加速, 把加速链接添加到`/etc/apt/sources.list`文件. [参考国内镜像加速goodrain.com/t/topic/236)

#### 2. 安装依赖
上一步做了一些基础的准备, 下面开始安装presto的依赖项.
```

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

```
Presto要求java8版本, 另外也需要python依赖, 修改`ENV PRESTO_VERSION 0.180`可以安装你指定的官方版本. 按照[Presto官方的deployment方法](https://prestodb.io/docs/current/installation/deployment.html) 将config文件在dockerfile中配置好, 我将presto的coordinator设置为master和worker共用, 另外在presto内部配一个mysql, 让presto的catalog能够访问到mysql的一些初始化的数据, 方便用于测试等. 在docker里安装mysql还是比较tricky的. 
- [ENTRYPOINT](https://docs.docker.com/engine/reference/builder/#entrypoint) 可以让容器启动之后执行指令. 如果在启动的时候想要执行多条执行, 可以把代码写到shell脚本中. 因为dockerfile只支持一个ENTRYPOINT 或 CMD.
