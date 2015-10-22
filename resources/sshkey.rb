#
# Cookbook Name:: mysql-mha
# Resources:: sshkey
#

actions :create

# :key_name is the filename of the SSH private key that will get created
# :key_contents is the content of the SSH private key that will get created
# :username is the name of the user who will own the SSH key
# :cookbook is the name of the cookbook that the private_key template should be found in
attribute :key_name,      :kind_of => String, :default => nil
attribute :key_contents,  :kind_of => String, :default => nil
attribute :username,      :kind_of => String, :default => "root"
attribute :cookbook,      :kind_of => String, :default => "mysql-mha"

def initialize(*args)
  super
  @action = :create
end
