Cookbook TESTING doc
====================

Testing Prerequisites
---------------------
Chef cookbooks require either a working ChefDK installation set as your system's default ruby or Ruby 2.0+ with bundler installed. Using ChefDK provides a consistent Ruby install, and is the suggested method. ChefDK can be downloaded at https://downloads.chef.io/chef-dk/

To ensure all gems are updated to their latest releases run `bundle install; bundle update` before running any Rake testing tasks.

Integration testing relies on both Hashicorp's [Vagrant](https://www.vagrantup.com/downloads.html) and Oracle's [Virtualbox](https://www.virtualbox.org/wiki/Downloads), which must be installed first.

Rakefile
--------
The Rakefile ships with a number of tasks, each of which can be ran
individually, or in groups. Typing "rake" by itself will perform style
checks with Rubocop and Foodcritic and integration with Test Kitchen
using the Vagrant driver.

```
$ rake -T
rake cleanup                     # Clean up generated files
rake cleanup:kitchen_destroy     # Destroy test-kitchen instances
rake integration                 # Run full integration
rake integration:vagrant_setup   # Setup the test-kitchen vagrant instances
rake integration:vagrant_verify  # Verify the test-kitchen vagrant instances
rake setup                       # Generate the setup
rake style                       # Run all style tests
rake style:foodcritic            # Run Foodcritic lint checks
rake style:rubocop               # Run RuboCop style and lint checks
```

Style Testing
-------------
Ruby style tests can be performed by Rubocop by issuing either
```
bundle exec rubocop
```
or
```
rake style:rubocop
```

Chef style/correctness tests can be performed with Foodcritic by issuing either
```
bundle exec foodcritic
```
or
```
rake style:foodcritic
```

Integration Testing
-------------------
Integration testing is performed by Test Kitchen. Test Kitchen will
use the Vagrant driver to instantiate machines and apply cookbooks.
After a successful converge, tests are uploaded and ran out of band
of Chef. Tests should be designed to ensure that a recipe has
accomplished its goal.

Integration Testing using Vagrant
---------------------------------
Integration tests can be performed on a local workstation using
Virtualbox or VMWare. Detailed instructions for setting this up can be
found at the [Bento](https://github.com/chef/bento) project web site.

Integration tests using Vagrant can be performed with
```
rake integration
```
