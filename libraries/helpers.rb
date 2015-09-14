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
  module Helpers
    require 'digest/sha1'

    def mysql_instance
      klass = if defined?(Chef::ResourceResolver)
                r = Chef::ResourceResolver
                r.respond_to?(:resolve) && r.resolve(:mysql_service)
      end
      klass ||= Chef::Resource::MysqlService
      run_context.resource_collection.select { |r| r.is_a?(klass) && r.name == new_resource.name }.first
    end

    def mysql_socket
      provider_class = Chef::ProviderResolver.new(node, mysql_instance, :create).resolve
      provider_class.new(mysql_instance, run_context).socket_file
    end

    def mysql_password(password)
      '*' + Digest::SHA1.hexdigest(Digest::SHA1.digest(password)).upcase
    end
  end
end

Chef::Recipe.send(:include, MysqlReplication::Helpers)
Chef::Resource.send(:include, MysqlReplication::Helpers)
Chef::Provider.send(:include, MysqlReplication::Helpers)
