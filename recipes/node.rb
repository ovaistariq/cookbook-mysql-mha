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
pod_name      = node['mysql_mha']['pod_name']
pod_config    = get_single_mysql_pod(pod_name)
ssh_key_name  = "id_rsa"
ssh_key_path  = ::File.join(get_ssh_dir_for_user(pod_config['remote_user']['id']), ssh_key_name)

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

# Setup the SSH private key file that is used by MHA nodes to connect to
# each other
mysql_mha_sshkey 'mha ssh private key :create' do
  key_name ssh_key_name
  key_contents pod_config['remote_user']['ssh_private_key']
  username pod_config['remote_user']['id']
end

# Add host keys to known_hosts and ssh auth params to ssh-config
pod_config['nodes'].each do |mysql_node|
  # For each of the hosts we also add host keys to prevent prompts when the
  # host is accessed for the first time
  ssh_known_hosts mysql_node['fqdn'] do
    hashed true
    user pod_config['remote_user']['id']
  end

  # For each of the hosts we add the remote user and ssh private key path
  # to ssh config so that password-less SSH login works
  ssh_config mysql_node['fqdn'] do
    options 'User' => pod_config['remote_user']['id'], 'IdentityFile' => ssh_key_path
    user pod_config['remote_user']['id']
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
remote_workdir = ::File.join(node['mysql_mha']['manager']['working_dir_base'], pod_name)
directory remote_workdir do
  owner pod_config['remote_user']['id']
  group pod_config['remote_user']['id']
  mode 0755
  action :create
end

# Setup sudo access for the system user used by MHA Helper
sudo pod_config['remote_user']['id'] do
  user     pod_config['remote_user']['id']
  nopasswd true
  commands node['mysql_mha']['node']['sudo_cmds']
end
