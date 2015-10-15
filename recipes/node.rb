#
# Cookbook Name:: mysql-mha
# Recipe:: node
#
# Copyright (c) 2015 Ovais Tariq <me@ovaistariq.net>, All Rights Reserved.

include_recipe "yum-epel"

# Setup the twindb repository
packagecloud_repo node["mysql_mha"]["repo"]["prod"] do
  case node["platform_family"]
  when "debian"
    type "deb"
  when "rhel", "fedora"
    type "rpm"
    priority 9
  end
end

node["mysql_mha"]["node"]["additional_packages"].each do |pkg|
  package pkg do
    action :install
  end
end

package node["mysql_mha"]["node"]["package"] do
  action :install
end
