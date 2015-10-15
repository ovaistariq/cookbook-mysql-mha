#
# Cookbook Name:: mysql-mha
# Attributes:: default
#

# Packages
default["mysql_mha"]["manager"]["package"] = value_for_platform(
  ['centos', 'redhat'] => {
    '>= 5.0' => 'mha4mysql-manager-0.56-0.el5.noarch',
    '>= 6.0' => 'mha4mysql-manager-0.56-0.el6.noarch',
    '>= 7.0' => 'mha4mysql-manager-0.57-0.el7.noarch'
  }
)

default["mysql_mha"]["node"]["package"] = value_for_platform(
  ['centos', 'redhat'] => {
    '>= 5.0' => 'mha4mysql-node-0.56-0.el5.noarch',
    '>= 6.0' => 'mha4mysql-node-0.56-0.el6.noarch',
    '>= 7.0' => 'mha4mysql-node-0.57-0.el7.noarch'
  }
)

default["mysql_mha"]["node"]["additional_packages"] = %w(perl-DBD-MySQL)

# Repository
default["mysql_mha"]["repo"]["prod"] = value_for_platform(
  ['centos', 'redhat', 'ubuntu', 'debian'] => {
    'default' => 'twindb/main'
  },
  'amazon' => 'twindb/amzn_main'
)

default["mysql_mha"]["repo"]["develop"] = value_for_platform(
  ['centos', 'redhat', 'ubuntu', 'debian'] => {
    'default' => 'twindb/develop'
  },
  'amazon' => 'twindb/amzn_develop'
)
