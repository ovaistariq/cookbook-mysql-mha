#
# Cookbook Name:: mysql-mha
# Recipe:: manager
#
# Copyright 2015, Ovais Tariq <me@ovaistariq.net>
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
#

# Include the library functions
Chef::Recipe.send(:include, Chef::MySQLMHA::Helpers)

# Additional gems needed to deal with ini-style configs used by MHA
chef_gem 'inifile'
require 'inifile'
require 'pp'

# The manager needs the node package to be installed as well
include_recipe "mysql-mha::base"
include_recipe "mysql-mha::node"

node["mysql_mha"]["manager"]["additional_packages"].each do |pkg|
  package pkg do
    action :install
  end
end

package node["mysql_mha"]["manager"]["package"] do
  version node["mysql_mha"]["manager"]["version"]
  action :install
end

directory node['mysql_mha']['config_dir'] do
  owner 'root'
  group 'root'
  mode 0755
  action :create
end

directory node['mysql_mha']['helper_config_dir'] do
  owner 'root'
  group 'root'
  mode 0755
  action :create
end

# Setup configuration
mysql_pods = get_mysql_pods()
pp mysql_pods
