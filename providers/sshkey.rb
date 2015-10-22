#
# Cookbook Name:: mysql-mha
# Provider:: sshkey
#

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

  # Set home_basedir based on platform_family
  case node['platform_family']
  when 'mac_os_x'
      home_basedir = '/Users'
  when 'debian', 'rhel', 'fedora', 'arch', 'suse', 'freebsd'
      home_basedir = '/home'
  end


  # First we try to read the user's home directory from the username
  # If that fails then we manually handle the home directory path generation
  begin
    home_dir = ::File.expand_path("~#{username}")
  rescue
    # Set home to a reasonable default ($home_basedir/$user).
    # Root user is a special use case
    if username == "root"
      home_dir = "/#{username}"
    else
      home_dir = "#{home_basedir}/#{username}"
    end
  end

  if home_dir != "/dev/null"
    converge_by("would create #{home_dir}/.ssh") do
      directory "#{home_dir}/.ssh" do
        owner username
        group username
        mode "0700"
      end
    end

    template "#{home_dir}/.ssh/#{key_name}" do
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
