#
# Cookbook Name:: mysql_replication
# Recipe:: replication_user
#

# Setup credentials that are used by the database cook LWRPs
connection_info = {
  host: "127.0.0.1",
  username: "root",
  password: node["mysql"]["root_password"],
  port: node["mysql"]["server"]["port"]
}

# This is a prerequisite for the database cookbook
mysql2_chef_gem "default" do
  client_version node["mysql"]["version"]
  action :install
end

# Setup the grants for the slave users
# But create the users only if we are running on the master
mysql_database_user node["mysql"]["replication"]["user"] do
  connection connection_info
  password node["mysql"]["replication"]["password"]
  host '%'
  privileges [:"replication slave", :"replication client"]
  action :grant
end
