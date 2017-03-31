#
# Cookbook Name:: mysql-replication
# Library:: helpers
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

module MysqlReplication
  #
  module Helpers
    require 'digest/sha1'
    require 'mixlib/shellout'

    def mysql_instance
      klass = if defined?(Chef::ResourceResolver)
                res = Chef::ResourceResolver
                res.respond_to?(:resolve) && res.resolve(:mysql_service)
              end
      klass ||= Chef::Resource::MysqlService
      run_context.root_run_context.resource_collection.select { |r| r.is_a?(klass) && r.name == new_resource.name }.first
    end

    def mysql_socket
      provider_class = Chef::ProviderResolver.new(node, mysql_instance, :create).resolve
      provider_class.new(mysql_instance, run_context).socket_file
    end

    def mysql_password(password)
      '*' + Digest::SHA1.hexdigest(Digest::SHA1.digest(password)).upcase
    end

    def replication_enabled?(socket, root_password)
      result = Mixlib::ShellOut.new("echo 'show slave status\\G' | mysql -S #{socket}", env: { 'MYSQL_PWD' => root_password })
      result.run_command
      slave_sql_running_string = result.stdout.each_line.find { |a| a.include?('Slave_SQL_Running') }
      return false unless slave_sql_running_string
      slave_sql_running = slave_sql_running_string.split(':')[1].strip
      slave_sql_running == 'Yes'
    end

    def get_master_file_and_position(file)
      ::File.open(file).each_line do |line|
        result = /CHANGE MASTER TO MASTER_LOG_FILE='(.+)', MASTER_LOG_POS=(\d+);/.match(line)
        return result[1, 2] if result
      end
    end

    def mysql_master_connect
      connect_string = 'mysql --skip-column-names -rB'
      connect_string += " -h #{new_resource.master_host}"
      connect_string += " -u #{new_resource.user}"
      connect_string += " -P #{new_resource.master_port}" if new_resource.master_port
      connect_string
    end

    def master_databases
      result = Mixlib::ShellOut.new("echo 'show databases' | #{mysql_master_connect}", env: { 'MYSQL_PWD' => new_resource.password })
      result.run_command
      master_databases = result.stdout.each_line.map(&:strip).select { |a| a != 'information_schema' && a != 'performance_schema' }
      master_databases.select { |a| !new_resource.replicate_ignore_db.include?(a) }.map(&:strip)
    end
  end
end

Chef::Recipe.send(:include, MysqlReplication::Helpers)
Chef::Resource.send(:include, MysqlReplication::Helpers)
Chef::Provider.send(:include, MysqlReplication::Helpers)
