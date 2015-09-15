#
# Cookbook Name:: lwrp_test
# Recipe:: default
#
# Copyright 2015 Pavel Yudin
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

mysql_service 'default' do
  version '5.6'
  initial_root_password 'change_me'
  action [:create, :start]
end

mysql_master 'default' do
  binlog_do_db %w(test1 test2)
  password 'replication_password'
end

execute 'Create database test1' do
  command "echo 'create database if not exists test1;' | mysql -S /var/run/mysql-default/mysqld.sock -pchange_me"
end

execute 'Create database test2' do
  command "echo 'create database if not exists test2;' | mysql -S /var/run/mysql-default/mysqld.sock -pchange_me"
end

mysql_service 'slave' do
  version '5.6'
  initial_root_password 'change_me'
  port 3309
  action [:create, :start]
end

mysql_slave 'slave' do
  master_host '127.0.0.1'
  password 'replication_password'
  replicate_ignore_db 'mysql'
end
