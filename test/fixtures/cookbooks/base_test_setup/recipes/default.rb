#
# Cookbook Name:: base_test_setup
# Recipe:: default
#

node['hosts_list'].each do |host|
  hostsfile_entry host['ip'] do
    hostname  host['hostname']
  end
end
