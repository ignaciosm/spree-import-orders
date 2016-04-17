Spree Import Orders
=================

A Spree extension to allow admins to upload Orders from a CSV file.

Installation
------------

Add spree_import_orders to your Gemfile:

```ruby
# for importing orders data using csv
gem 'spree_import_orders', :git => 'git://github.com/rohitnick/spree-import-orders.git'
```

Bundle your dependencies and run the installation generator:

```shell
bundle
bundle exec rails g spree_import_orders:install
```

I simply implemented this feature as a Spree extension to help out someone else needing this sort of basic funcionality as part of work on a project, rather than specifically aiming to build it as a complete extension - therefore, I can vouch that it works for me, and should work for you, but if you need to change anything about which fields are exported or how the extension works there is no sort of configuration - fork the extension, and implement whatever you need to on your copy.

Enjoy :-)

rohitnick

Contributing
------------
    Fork it
    Create your feature branch (git checkout -b my-new-feature)
    Commit your changes (git commit -am 'Add some feature')
    Push to the branch (git push origin my-new-feature)
    Create new Pull Request


Copyright (c) 2016 Rohit Agarwal, released under the MIT License
