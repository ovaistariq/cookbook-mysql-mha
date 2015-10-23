require 'shellwords'
require 'resolv'
require 'chef/search/query'

class Chef
  module MySQLMHA
    module Helpers
      extend self

      # Returns an array of data bag items or an empty array
      # Avoids unecessary calls to search by checking against
      # the list of known data bags.
      def get_data_bags(bag_name)
        results = []
        if Chef::DataBag.list.include?(bag_name)
          Chef::Search::Query.new.search(bag_name.to_s, '*:*') { |rows| results << rows }
        else
          Chef::Log.info "The #{bag_name} data bag does not exist."
        end
        results
      end

      # Returns an array of MySQL pod config objects
      def get_mysql_pods()
        # Loading all databag information
        mysql_mha_bags = get_data_bags(node['mysql_mha']['config_databag'])

        if mysql_mha_bags.empty?
          Chef::Log.info('No MySQL MHA config data bag found')
        end

        mysql_pods = []
        mysql_mha_bags.each do |item|
          pod_config = item.to_hash
          pod_name = pod_config['id']

          pod_secrets = Chef::EncryptedDataBagItem.load(node['mysql_mha']['secrets_databag'], pod_name).to_hash
          pod_config['mysql']['password'] = pod_secrets['mysql']['password']
          pod_config['mysql']['repl_password'] = pod_secrets['mysql']['repl_password']
          pod_config['remote_user']['ssh_private_key'] = pod_secrets['remote_user']['ssh_private_key']

          # Find nodes that are part of this pod.
          # Search in all environments if multi_environment_monitoring is enabled.
          Chef::Log.info("Beginning search for nodes that belong to pod #{pod_name}.")

          pod_config['nodes'] = []
          multi_env = node['mysql_mha']['monitored_environments']
          multi_env_search = multi_env.empty? ? '' : ' AND (chef_environment:' + multi_env.join(' OR chef_environment:') + ')'

          if node['mysql_mha']['multi_environment_monitoring']
            pod_config['nodes'] = search(:node, "mysql_mha_pod_name:#{pod_name}#{multi_env_search}")
          else
            pod_config['nodes'] = search(:node, "mysql_mha_pod_name:#{pod_name} AND chef_environment:#{node.chef_environment}")
          end

          if pod_config['nodes'].empty?
            Chef::Log.info("No nodes returned from search that belog to pod #{pod_name}.")
          end

          mysql_pods << pod_config
        end

        return mysql_pods
      end

      # Returns an array of MySQL pod config objects
      def get_single_mysql_pod(pod_name)
        # Loading the data bag configuration for a specifc pod
        item = data_bag_item(node['mysql_mha']['config_databag'], pod_name)

        if item.empty?
          Chef::Log.info("No MySQL MHA config data bag found for the pod #{pod_name}")
        end

        pod_config = item.to_hash
        pod_name = pod_config['id']

        pod_secrets = Chef::EncryptedDataBagItem.load(node['mysql_mha']['secrets_databag'], pod_name).to_hash
        pod_config['mysql']['password'] = pod_secrets['mysql']['password']
        pod_config['mysql']['repl_password'] = pod_secrets['mysql']['repl_password']
        pod_config['remote_user']['ssh_private_key'] = pod_secrets['remote_user']['ssh_private_key']

        return pod_config
      end

      # Returns the SSH directory path for the given username
      # The user must exist
      def get_ssh_dir_for_user(username)
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

        return "#{home_dir}/.ssh"
      end
    end
  end
end
