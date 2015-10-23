#
# Cookbook Name:: mysql-mha
# Recipe:: base
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

include_recipe "yum-epel"

# Setup the repository
packagecloud_repo node["mysql_mha"]["repo"]["prod"] do
  case node["platform_family"]
  when "debian"
    type "deb"
  when "rhel", "fedora"
    type "rpm"
    priority 9
  end
end

# The MHA node packages have to be installed on all the nodes including the
# manager and the MySQL nodes
node["mysql_mha"]["node"]["additional_packages"].each do |pkg|
  package pkg do
    action :install
  end
end

package node["mysql_mha"]["node"]["package"] do
  version node["mysql_mha"]["node"]["version"]
  action :install
end
