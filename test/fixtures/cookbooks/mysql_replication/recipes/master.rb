#
# Cookbook Name:: mysql_replication
# Recipe:: master
#

# Set attributes that need to be set differently for the master
node.default["mysql"]["server"]["read_only"] = 0

# Include the base recipe that sets up and configures the MySQL server
include_recipe "mysql_replication::_server"

# During the first converge of master we run 'FLUSH LOGS' to start a fresh
# binlog file that the slaves then can use
bash 'binary logs :flush during first run' do
  user 'root'
  code <<-EOH
  /usr/bin/mysqladmin flush-logs
  EOH
  notifies :create, 'file[/tmp/master_flush_logs_done]', :immediately
  not_if { File.exist?('/tmp/master_flush_logs_done') }
end

file '/tmp/master_flush_logs_done' do
  owner 'root'
  group 'root'
  mode 0755
  action :nothing
end
