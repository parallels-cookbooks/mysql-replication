#
# Cookbook Name:: mysql-replication
# Resource:: mysql_slave
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

property :instance, kind_of: String, name_attribute: true
property :id, kind_of: Integer
property :master_host, kind_of: String, required: true
property :master_port, kind_of: Integer, default: 3306
property :user, kind_of: String, default: 'repl'
property :password, kind_of: String, required: true
property :database, kind_of: [String, Array]
property :replicate_ignore_db, kind_of: [String, Array]
property :timeout, kind_of: Integer
property :options, kind_of: Hash

provides :mysql_slave
default_action :create

action :create do
  dump_file = ::File.join(Chef::Config[:file_cache_path], "#{new_resource.name}-dump.sql")

  databases = new_resource.database ? [new_resource.database].flatten : master_databases

  mysql_config 'slave' do
    cookbook 'mysql-replication'
    instance new_resource.name
    source 'slave.conf.erb'
    variables id: new_resource.id || node['ipaddress'].split('.').join(''),
              database: new_resource.database,
              replicate_ignore_db: new_resource.replicate_ignore_db,
              options: new_resource.options
    action :create
    notifies :restart, "mysql_service[#{new_resource.name}]", :immediately
  end

  execute 'Get dump' do
    command "mysqldump -h #{new_resource.master_host} -P #{new_resource.master_port} \
             -u #{new_resource.user} --master-data=2 --single-transaction \
             --databases #{databases.join(' ')} > #{dump_file}"
    environment 'MYSQL_PWD' => new_resource.password
    action :run
    not_if { replication_enabled?(mysql_socket, mysql_instance.initial_root_password) }
  end

  execute 'Upload dump' do
    command "cat #{dump_file} | mysql -S #{mysql_socket}"
    environment 'MYSQL_PWD' => mysql_instance.initial_root_password
    timeout new_resource.timeout if new_resource.timeout
    not_if { replication_enabled?(mysql_socket, mysql_instance.initial_root_password) }
  end

  ruby_block 'Start replication' do
    block do
      master_file, master_position = get_master_file_and_position(dump_file)

      command_master = %(
        CHANGE MASTER TO
        MASTER_HOST="#{new_resource.master_host}",
        MASTER_PORT=#{new_resource.master_port},
        MASTER_USER="#{new_resource.user}",
        MASTER_PASSWORD="#{new_resource.password}",
        MASTER_LOG_FILE="#{master_file}",
        MASTER_LOG_POS=#{master_position};
      )

      result = Mixlib::ShellOut.new("echo '#{command_master}' | mysql -S #{mysql_socket}", env: { 'MYSQL_PWD' => mysql_instance.initial_root_password })
      result.run_command
      result.error!

      result = Mixlib::ShellOut.new("echo 'start slave' | mysql -S #{mysql_socket}", env: { 'MYSQL_PWD' => mysql_instance.initial_root_password })
      result.run_command
      result.error!
    end
    not_if { replication_enabled?(mysql_socket, mysql_instance.initial_root_password) }
  end

  file dump_file do
    action :delete
  end
end
