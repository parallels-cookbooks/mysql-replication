#
# Cookbook Name:: mysql-replication
# Resource:: mysql_master
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

require 'chef/resource/lwrp_base'

class Chef
  class Resource
    class MysqlMaster < Chef::Resource::LWRPBase
      provides :mysql_master
      resource_name :mysql_master

      default_action :create
      actions :create, :delete

      attribute :instance, kind_of: String, name_attribute: true
      attribute :id, kind_of: Integer
      attribute :log_bin, kind_of: String, default: 'mysql-bin'
      attribute :user, kind_of: String, default: 'repl'
      attribute :host, kind_of: String, default: '%'
      attribute :password, kind_of: String, required: true
      attribute :binlog_do_db, kind_of: [Array, String]
      attribute :binlog_ignore_db, kind_of: [Array, String]
      attribute :binlog_format, kind_of: String, default: 'MIXED'
      attribute :options, kind_of: Hash
    end
  end
end
