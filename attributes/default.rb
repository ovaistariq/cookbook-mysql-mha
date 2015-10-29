#
# Cookbook Name:: mysql-mha
# Attributes:: default
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

# Packages
default["mysql_mha"]["manager"]["package"] = 'mha4mysql-manager'
default["mysql_mha"]["node"]["package"] = 'mha4mysql-node'
default["mysql_mha"]["helper"]["package"] = 'python-mha_helper'

default["mysql_mha"]["manager"]["version"] = value_for_platform(
  ['centos', 'redhat'] => {
    '~> 5.0' => '0.56-0.el5',
    '~> 6.0' => '0.56-0.el6',
    '~> 7.0' => '0.57-0.el7'
  }
)

default["mysql_mha"]["node"]["version"] = value_for_platform(
  ['centos', 'redhat'] => {
    '~> 5.0' => '0.56-0.el5',
    '~> 6.0' => '0.56-0.el6',
    '~> 7.0' => '0.57-0.el7'
  }
)

default["mysql_mha"]["helper"]["version"] = '0.4.0-3'

default["mysql_mha"]["manager"]["additional_packages"] = %w(perl-Config-Tiny perl-Log-Dispatch perl-Parallel-ForkManager perl-Mail-Sendmail perl-Mail-Sender)
default["mysql_mha"]["node"]["additional_packages"] = %w(perl-DBD-MySQL)

# Repository
default["mysql_mha"]["repo"]["prod"] = value_for_platform(
  ['centos', 'redhat', 'ubuntu', 'debian'] => {
    'default' => 'twindb/main'
  },
  'amazon' => {
    'default' => 'twindb/amzn_main'
  }
)

default["mysql_mha"]["repo"]["develop"] = value_for_platform(
  ['centos', 'redhat', 'ubuntu', 'debian'] => {
    'default' => 'twindb/develop'
  },
  'amazon' => {
    'default' => 'twindb/amzn_develop'
  }
)

# Sudoers handling to enable the MHA Helper user to be able to execute
# commands using sudo when its a non-privileged user
default['authorization']['sudo']['include_sudoers_d'] = true

## Configuration
# Allow a MHA manager server to monitor MySQL servers in multiple environments
# By default only the nodes in the same chef environment as the manager node
# are monitored
default['mysql_mha']['multi_environment_monitoring'] = false
default['mysql_mha']['monitored_environments'] = []

default['mysql_mha']['config_databag'] = 'mysql_mha_config'
default['mysql_mha']['secrets_databag'] = 'mysql_mha_secrets'

default['mysql_mha']['manager']['config_dir'] = '/etc/mha'
default['mysql_mha']['manager']['helper_config_dir'] = '/etc/mha-helper'

default['mysql_mha']['manager']['working_dir_base'] = '/var/log/mha'
default['mysql_mha']['manager']['master_ip_failover_script'] = '/usr/bin/master_ip_hard_failover_helper'
default['mysql_mha']['manager']['master_ip_online_change_script'] = '/usr/bin/master_ip_online_failover_helper'
default['mysql_mha']['manager']['report_script'] = '/usr/bin/master_failover_report'

default['mysql_mha']['node']['candidate_master'] = '0'
default['mysql_mha']['node']['no_master'] = '0'
default['mysql_mha']['node']['check_repl_delay'] = '1'
default['mysql_mha']['node']['mysql_port'] = '3306'
default['mysql_mha']['node']['ssh_port'] = '22'
default['mysql_mha']['node']['mysql_binlog_dir'] = '/var/lib/mysql'
default['mysql_mha']['node']['sudo_cmds'] = ['/sbin/ip', '/sbin/arping']
