create database IF NOT EXISTS test;
use test;

DROP TABLE IF EXISTS `sql_executions`;

CREATE TABLE `presto_info` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `username` varchar(50) DEFAULT NULL COMMENT 'user name',
  `status` smallint(6) DEFAULT NULL COMMENT '0: init, 1: succes, -1: failed',
  `error` mediumtext,
  `worker` varchar(30) DEFAULT NULL,
  `last_progress` float NOT NULL DEFAULT '0',
  `running_id` int(11) NOT NULL DEFAULT '0',
  `running_presto_id` varchar(30) DEFAULT NULL COMMENT 'running presto query id. used to kill query',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `create_time` timestamp NOT NULL,
  PRIMARY KEY (`id`),
  KEY `name_idx` (`username`),
  KEY `status_create_time_idx` (`status`,`create_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


insert into sql_executions(update_time, create_time)
values (now(), now());
insert into sql_executions(update_time, create_time)
values (now(), now());
insert into sql_executions(update_time, create_time)
values (now(), now());
