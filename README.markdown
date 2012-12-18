# ageto_elasticsearch #

This is the ageto_elasticsearch puppet module. It provides elasticsearch installation and configuration capabilities.

```puppet
node 'elasticsearch-01' inherits default {
  # elasticsearch setup
  class {'ageto_elasticsearch':
    version => '0.20.1'
  }
}
```
