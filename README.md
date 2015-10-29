mysql-mha Cookbook
==================

[![Join the chat at https://gitter.im/ovaistariq/cookbook-mysql-mha](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/ovaistariq/cookbook-mysql-mha?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)
[![Cookbook Version](https://img.shields.io/cookbook/v/mysql-mha.svg)](https://supermarket.chef.io/cookbooks/mysql-mha)

Deploys [MHA](https://code.google.com/p/mysql-master-ha/) and [MHA Helper](https://github.com/ovaistariq/mha-helper) to manage failover of MySQL replication clusters. MHA helper is a Python module that supplements in doing proper failover using MHA.


Requirements
------------
#### Platforms
- RHEL / CentOS version 6.x

#### Chef
- Chef 11+

#### Cookbooks
- packagecloud
- ssh
- sudo
- user
- yum-epel
- zap


Usage
-----
On the manager node, which is the node which will manage the MySQL replication clusters, include the following recipe:

```ruby
include_recipe "mysql-mha::manager"
```

On all the other MySQL nodes (master and slave), include the following recipe:

```ruby
include_recipe "mysql-mha::node"
```

Use knife to create the required data bags.

```bash
$ knife data bag create mysql_mha_config
$ knife data bag create mysql_mha_secrets
```

The *mysql_mha_config* data bag contains the main configuration minus the sensitive items like user passwords.

Create cluster configuration in the data_bag/mysql_mha_config/ directory.

The latest version of knife supports reading data bags from a file and automatically looks in a directory called +data_bags+ in the current directory. The "bag" should be a directory with JSON files of each item.


```javascript
{
  "id": "test_pod",
  "comment": "MHA replication pod 'test_pod' configuration",
  "mysql": {
    "user": "mha",
    "repl_user": "repl"
  },
  "remote_user": {
    "id": "mha",
    "comment": "user used by MHA to login to managed nodes",
    "home": "/home/mha",
    "uid": "10011",
    "groups": ["mysql"],
    "ssh_keys": [
      "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAwHjA7iaA0/+TD0roAmyOqYFp3DMpuJ/Xee260gio5igLeV6DHyPBskHhcCOWFcZ+uCAOGIm+Yye9nxuspWFEWCa4L1SxniBEpRGtGyorbgz7Zmh/6VlcZOUBTe1GtaprokGAtzP2gaQbRpJ1c0oX3JZ4lVH6Oro3keCGyncZMFJ2nTu0hOgbJPA3XZkRwO0DhB/8IbPu6NwXVcDjaMfTmpj4kp722RFuEUgGrDBwx/vasakpcBMHF+a6QL0gAODHMttQB1kk1hCV4fQtiTSrbG97jldlcC7VvSqK79twpQNe9y06jnMah8xdvZ69mw/4k3Av+Vv3I4KHxvN9wE59Tw== root@manager-centos-66"
    ]
  },
  "vip_type": "metal",
  "writer_vip_cidr": "192.168.30.100/24",
  "report_email": "ovaistariq@gmail.com",
  "smtp_host": "localhost",
  "requires_sudo": "yes",
  "cluster_interface": "eth1"
}
```

For the above:

```bash
$ mkdir data_bags/mysql_mha_config
$ $EDITOR data_bags/mysql_mha_config/test_pod.json
```

Paste the user's public SSH key into the ssh_keys value. Also make sure the uid is unique.

Create cluster configuration in the data_bag/mysql_mha_secrets directory.

The *mysql_mha_secrets* data bag is an encrypted data bag that contains the secondary part of the configuration which includes the sensitive items like user passwords.

```javascript
{
  "id": "test_pod",
  "comment": "MHA replication pod 'test_pod' secrets",
  "mysql": {
    "password": "mha",
    "repl_password": "repl"
  },
  "remote_user": {
    "ssh_private_key": "-----BEGIN RSA PRIVATE KEY-----\nMIIEogIBAAKCAQEAwHjA7iaA0/+TD0roAmyOqYFp3DMpuJ/Xee260gio5igLeV6D\nHyPBskHhcCOWFcZ+uCAOGIm+Yye9nxuspWFEWCa4L1SxniBEpRGtGyorbgz7Zmh/\n6VlcZOUBTe1GtaprokGAtzP2gaQbRpJ1c0oX3JZ4lVH6Oro3keCGyncZMFJ2nTu0\nhOgbJPA3XZkRwO0DhB/8IbPu6NwXVcDjaMfTmpj4kp722RFuEUgGrDBwx/vasakp\ncBMHF+a6QL0gAODHMttQB1kk1hCV4fQtiTSrbG97jldlcC7VvSqK79twpQNe9y06\njnMah8xdvZ69mw/4k3Av+Vv3I4KHxvN9wE59TwIBIwKCAQEAlHpo8jr1qtsZrLYg\nsWmv4djcoo3eWzl6Vr60sKeYPIVKrhW1m63ekNO8ibUNYUFacMhFY2Lx9LhB0oMQ\nJ86xEM1pg5kbThjkf1bHXhk3cidFmCS6ci7+IfJ9WV9FLQ5wSfgENY58VWFW3qt/\nLQ1Fm4oFP/1pQz8yLrSFPRoMHfUgTAOxnM+mjfp1BcptF56R1x3UhnP16rU8Gc/I\n3GWHf9PKRZODDlPL7kxnOo0Uy2az2/mIV1AZAi6mUwDnQlR91un+EWHb9AxyJGZd\nSDCn3Cyf+Z7OG8d4+yfBW6evg/Mgdt3ilQBGzqiX5NCaf5+f/UNKpusD7fkVG0CM\n13hPswKBgQD3NgdgBX18pBN4bwO4RtcQqWfEqdYoaNa4yuU7XN4rSzitQoU3SRQ1\nunYNhm6OEN4b6jC00Yj91AW7pvpAhJkA2p4RYFAFrGX1nxPI2JYJcPgDZhRi7v+6\ncoArNtAGgUtJkcedDWO+CnqgFG0FZcK8h0WqZbtSoUf3k+C0adiZVQKBgQDHUITg\nCXnjCy/Ia9FQzT7p80WyMd8o53lACpVqyEmZ2RTcz/u23DtC8oHlHDpo8dGAS4DW\n2AXC67d8VBcJCdo/qfF6C8Mn9snmX4sbLR0wrqXrJwza4eopIYnNXq1NuwskM5tR\n3FraxsMLuXikFJrB/MBUNoL0v4Xmnff/zV6sEwKBgHgS7aOq5S3pS0kf+n4Tx4u/\n/zOi8v2vQ7jXk+miIsSSQBmj94/hqrsCy6ArWkUA4Oj8uJJXJUgWhnEWls7hUaFU\nPiWycALBc1oLcAJ309izNqKQqtD3vgoaW4K0OSe7JJFysWmKKSHKk1URPERzQVRB\ntB+Qf46I2dAF/22SfyXnAoGAbDMGTbwAVq5NI6g+bbE/aQ8Ik+8wAEMkkHrGJAZT\n1yyzjc/9rGjs+HUEr5L7IwbuEnIhXq/InQOeHuvR/ZeiXRMcr/fBtpvp8hab+M9Y\n/Sub5g3iaDF/HaR+AcWuiUhH4HPJWFMMv+g9/wzpuChxRLxoaDrZYEq2Zz/PxWDb\nnz0CgYEA6tj/84IihQ7tUrTpZRI2Ml5Ekzng+zXv27IY/1+7ukO6zlbtkZsdJcG/\n720B150vR1JXmYQlWLYNcgMVb/U/gfPeYI5hpxzl8DyGnSsEYJo7jr8wJ9hebqgf\nyNlZaURrwMLOm9DrnGih9qbWgtMMhHP2GHiQRqTpexhs20dm8U8=\n-----END RSA PRIVATE KEY-----"
  }
}
```

For the above:

```bash
$ mkdir data_bags/mysql_mha_secrets
$ knife data bag create mysql_mha_config test_pod -z --secret-file /path/to/encrypted_data_bag_secret
```


The data bag name is the name of the cluster and the following attribute must be set on all the nodes that belong to the same MySQL replication cluster:
```ruby
node['mysql_mha']['pod_name'] = 'test_pod'
```

Note how the attribute above matches the name of the data bag in the example above.


Every MySQL node that is the candidate master (including current active MySQL master and all the other nodes that can potentially become masters) must have the following attribute set:
```ruby
node['mysql_mha']['node']['candidate_master'] = '1'
```


You can optionally prevent MHA from checking for replication delay on a node, if you want the node to always act as a master irrespective if its the most latest slave or not:
```ruby
node['mysql_mha']['node']['check_repl_delay'] = '0'
```


If you do not want a MySQL node to every become a master, then you can set the following attribute:
```ruby
node['mysql_mha']['node']['no_master'] = '1'
```


The following attributes must be setup for MHA to function correctly:
```ruby
node['mysql_mha']['node']['mysql_port'] = '3306'
node['mysql_mha']['node']['mysql_binlog_dir'] = '/var/lib/mysql'
node['mysql_mha']['node']['ssh_port'] = '22'
```


Additionally following considerations must be taken into account:

 * The cookbook does not create the MySQL users you specify inside the
   configuration in the data bags. The must already exist.
 * The writer VIP (specified using the option 'writer_vip_cidr') must already
   be assigned when the recipe is run for the first time.


License & Authors
-----------------

**Author:** Ovais Tariq (<me@ovaistariq.net>)

**Copyright:** 2009-2015, Ovais Tariq <me@ovaistariq.net>.
```
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
