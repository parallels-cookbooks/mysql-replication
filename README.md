# mysql-replication

## Description
This cookbook is a wrapper under the [mysql](https://supermarket.chef.io/cookbooks/mysql) cookbook is newer than version 6. It contains two lwrp which configures mysql master and mysql slave.

## Requirements

### Platforms
- amazon 2014
- redhat 6
- centos 6
- scientific 6
- fedora 18, 19
- debian 7
- ubuntu >= 12.04

### Cookbooks
- [mysql](https://supermarket.chef.io/cookbooks/mysql), ~> 6.0


## Resources/Providers

### mysql_master
configures mysql server as master.

#### Attributes

|Attribute|Description|Type|Default|
|---------|-----------|----|-------|
|:instance|This attribute should match with mysql_service name|String||
|:id|Server-id from mysql config|Integer||
|:log_bin|log-bin from mysql config|String|'mysql-bin'|
|:user|Name of replication user|String|'repl'|
|:host|Mask of the hosts which will be allowed replication|String|'%'|
|:password|Password for replication user|String||
|:binlog_do_db|binlog-do-db from mysql config|Array, String||
|:binlog_ignore_db|binlog-ignore-db from mysql config|Array, String||
|:binlog_format|binlog-format from mysql config|String|'MIXED'|
|:options|Hash of options which will be passed to config file|Hash||

### mysql_slave
configures mysql server as slave, does dump of specified databases and enables replication.

#### Attributes

|Attribute|Description|Type|Default|
|---------|-----------|----|-------|
|:instance|This attribute should match with mysql_service name|String||
|:id|Server-id from mysql config|Integer||
|:master_host|Master host's ip address or fqdn|String||
|:master_port|Master host's mysql port|Integer||
|:user|Name of replication user|String|'repl'|
|:password|Password for replication user|String||
|:database|List of databases, which will be dumped and replicated.|String, Array||
|:replicate_ignore_db|replicate-ignore-db from mysql config|Array, String||
|:timeout|Timeout for operations getting and uploading the dump|Integer|3600|
|:options|Hash of options which will be passed to config file|Hash||


## Examples
You may see examples in fixture cookbook: [test/fixtures/lwrp_test/recipes/default.rb](test/fixtures/lwrp_test/recipes/default.rb)

## Authors
- Author:: Pavel Yudin (pyudin@parallels.com)
