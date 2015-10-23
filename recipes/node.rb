#
# Cookbook Name:: mysql-mha
# Recipe:: node
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

include_recipe "mysql-mha::base"

## Setup configuration
# The global configuration is read from the data bag while node specific
# configuration is read from the node attributes
pod_config = get_single_mysql_pod(node['mysql_mha']['pod_name'])

# Create the system user that the MHA manager users to execute commands on the
# nodes
user_account pod_config['remote_user']['id'] do
  uid pod_config['remote_user']['uid']
  create_group true
  ssh_keys pod_config['remote_user']['ssh_keys']
  ssh_keygen false
  action :create
end

# Create the necessary group that the user above belongs to
pod_config['remote_user']['groups'].each do |grp|
  group grp  do
    action :create
    members pod_config['remote_user']['id']
    append true
  end
end

## The working directory on the nodes being managed by MHA
# Create the base working directory used by MHA Manager
# The directory used by MHA Manager as its working directory
directory node['mysql_mha']['manager']['working_dir_base'] do
  owner 'root'
  group 'root'
  mode 0755
  action :create
end

# Create the pod specific working directory where MHA Manager generates
# related status files
remote_workdir = ::File.join(node['mysql_mha']['manager']['working_dir_base'], node['mysql_mha']['pod_name'])
directory remote_workdir do
  owner pod_config['remote_user']['id']
  group pod_config['remote_user']['id']
  mode 0755
  action :create
end
