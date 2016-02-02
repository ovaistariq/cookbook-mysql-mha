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

# Manager specific packages
node["mysql_mha"]["manager"]["additional_packages"].each do |pkg|
  package pkg do
    action :install
  end
end

package node["mysql_mha"]["manager"]["package"] do
  version node["mysql_mha"]["manager"]["version"]
  action :install
end

package node["mysql_mha"]["helper"]["package"] do
  version node["mysql_mha"]["helper"]["version"]
  action :install
end

# Tha MHA Manager config directory
directory node['mysql_mha']['manager']['config_dir'] do
  owner 'root'
  group 'root'
  mode 0755
  action :create
end

# The MHA Helper config directory
directory node['mysql_mha']['manager']['helper_config_dir'] do
  owner 'root'
  group 'root'
  mode 0755
  action :create
end

# The directory used by MHA Manager as its working directory
directory node['mysql_mha']['manager']['working_dir_base'] do
  owner 'root'
  group 'root'
  mode 0755
  action :create
end

## Setup configuration
# The global configuration is read from the data bag while node specific
# configuration is read from the node attributes
mysql_pods = get_mysql_pods()
pp mysql_pods

mysql_pods.each do |pod_config|
  next if pod_config['nodes'].empty?

  pod_name = pod_config['id']

  # These are the MHA and MHA Helper configuration files, one per each MySQL pod
  mha_config_file = ::File.join(node['mysql_mha']['manager']['config_dir'], "#{pod_name}.conf")
  mha_helper_config_file = ::File.join(node['mysql_mha']['manager']['helper_config_dir'], "#{pod_name}.conf")

  # The directory and log used by MHA to log what it is doing
  manager_workdir = ::File.join(node['mysql_mha']['manager']['working_dir_base'], pod_name)
  manager_log = ::File.join(node['mysql_mha']['manager']['working_dir_base'], pod_name, "#{pod_name}.log")

  # Working directory full path that MHA Manager generates related status files.
  directory manager_workdir do
    owner 'root'
    group 'root'
    mode 0755
    action :create
  end

  # Full path file name that MHA Manager generates logs.
  file manager_log do
    owner 'root'
    group 'root'
    mode 0644
    action :create_if_missing
  end

  # Setup the SSH private key file that is used by MHA manager to connect to
  # the nodes
  ssh_key_name = "id_mha_#{pod_name}_rsa"
  ssh_key_path = ::File.join(get_ssh_dir_for_user('root'), ssh_key_name)
  mysql_mha_sshkey 'mha ssh private key :create' do
    key_name ssh_key_name
    key_contents pod_config['remote_user']['ssh_private_key']
    username 'root'
  end

  # The working directory on the remote nodes being managed by MHA
  remote_workdir = ::File.join(node['mysql_mha']['manager']['working_dir_base'], pod_name)

  # Now we build the MHA INI config file, one per each pod
  # We start off the config with the section [server default]
  mha_config_ini = IniFile.new
  mha_config_ini['server default']['user']                            = pod_config['mysql']['user']
  mha_config_ini['server default']['password']                        = pod_config['mysql']['password']
  mha_config_ini['server default']['ssh_user']                        = pod_config['remote_user']['id']
  mha_config_ini['server default']['repl_user']                       = pod_config['mysql']['repl_user']
  mha_config_ini['server default']['repl_password']                   = pod_config['mysql']['repl_password']
  mha_config_ini['server default']['remote_workdir']                  = remote_workdir
  mha_config_ini['server default']['manager_workdir']                 = manager_workdir
  mha_config_ini['server default']['manager_log']                     = manager_log
  mha_config_ini['server default']['master_ip_failover_script']       = node['mysql_mha']['manager']['master_ip_failover_script']
  mha_config_ini['server default']['master_ip_online_change_script']  = node['mysql_mha']['manager']['master_ip_online_change_script']
  mha_config_ini['server default']['report_script']                   = node['mysql_mha']['manager']['report_script']

  # Next we build the MHA Helper config file
  mha_helper_config_ini = IniFile.new
  mha_helper_config_ini['default']['writer_vip_cidr']   = pod_config['writer_vip_cidr']
  mha_helper_config_ini['default']['vip_type']          = pod_config['vip_type']
  mha_helper_config_ini['default']['report_email']      = pod_config['report_email']
  mha_helper_config_ini['default']['smtp_host']         = pod_config['smtp_host']
  mha_helper_config_ini['default']['requires_sudo']     = pod_config['requires_sudo']
  mha_helper_config_ini['default']['super_read_only']   = pod_config['super_read_only']
  mha_helper_config_ini['default']['cluster_interface'] = pod_config['cluster_interface']

  # Next we have a section per node in the pod [server1], [server2], ..., [serverN]
  i = 0
  pod_config['nodes'].each do |mysql_node|
    # Create the [server1], [server2], ..., [serverN] sections in INI file
    # one per node in the pod
    i += 1
    server_name = "server#{i}"
    mha_config_ini[server_name]['hostname']           = mysql_node['hostname']
    mha_config_ini[server_name]['ip']                 = mysql_node['ipaddress']
    mha_config_ini[server_name]['port']               = mysql_node['mysql_mha']['node']['mysql_port']
    mha_config_ini[server_name]['master_binlog_dir']  = mysql_node['mysql_mha']['node']['mysql_binlog_dir']
    mha_config_ini[server_name]['ssh_port']           = mysql_node['mysql_mha']['node']['ssh_port']
    mha_config_ini[server_name]['candidate_master']   = mysql_node['mysql_mha']['node']['candidate_master'] || node['mysql_mha']['node']['candidate_master']
    mha_config_ini[server_name]['no_master']          = mysql_node['mysql_mha']['node']['no_master'] || node['mysql_mha']['node']['no_master']
    mha_config_ini[server_name]['check_repl_delay']   = mysql_node['mysql_mha']['node']['check_repl_delay'] || node['mysql_mha']['node']['check_repl_delay']

    # Right now we don't have anything in host specific sections in MHA
    # Helper config so we just create empty sections in INI file
    mha_helper_config_ini[mysql_node['hostname']] = Hash.new

    # For each of the hosts we add the remote user and ssh private key path
    # to ssh config so that password-less SSH login works
    [ mysql_node['hostname'], mysql_node['fqdn'], mysql_node['ipaddress'] ].each do |host|
      ssh_config host do
        options 'User' => pod_config['remote_user']['id'], 'IdentityFile' => ssh_key_path
        user 'root'
      end
    end
  end

  # Write the MHA config file for the replication cluster
  file mha_config_file do
    content mha_config_ini.to_s
    owner 'root'
    group 'root'
    mode 0644
    action :create
  end

  # Write the MHA Helper config file for the replication cluster
  file mha_helper_config_file do
    content mha_helper_config_ini.to_s
    owner 'root'
    group 'root'
    mode 0644
    action :create
  end
end


# Keep the MHA Manager config directories cleaned up so that they only have
# relevant configuration files
zap_directory node['mysql_mha']['manager']['config_dir'] do
  pattern '*.conf'
end

zap_directory node['mysql_mha']['manager']['helper_config_dir'] do
  pattern '*.conf'
end
