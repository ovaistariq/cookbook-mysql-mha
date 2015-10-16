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
