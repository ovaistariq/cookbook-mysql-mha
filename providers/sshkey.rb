#
# Cookbook Name:: mysql-mha
# Provider:: sshkey
#

include Chef::MySQLMHA::Helpers

use_inline_resources if defined?(use_inline_resources)

def whyrun_supported?
  true
end

def initialize(*args)
  super
  @action = :create
end

def chef_solo_search_installed?
  klass = ::Search::const_get('Helper')
  return klass.is_a?(Class)
rescue NameError
  return false
end

action :create do
  key_name      = new_resource.key_name
  key_contents  = new_resource.key_contents
  key_type      = key_contents.include?("BEGIN RSA PRIVATE KEY") ? "rsa" : "dsa"
  username      = new_resource.username
  user_ssh_dir  = get_ssh_dir_for_user(username)

  if user_ssh_dir != "/dev/null"
    converge_by("would create #{user_ssh_dir}") do
      directory user_ssh_dir do
        owner username
        group username
        mode "0700"
      end
    end

    template "#{user_ssh_dir}/#{key_name}" do
      source "private_key.erb"
      cookbook new_resource.cookbook
      owner username
      group username
      mode "0400"
      variables :private_key => key_contents
      only_if { key_contents }
    end
  end
end
