# Class: ageto_elasticsearch
#
# AGETO ElasticSearch management via Puppet
#
# Parameters:
#   parent_dir
#   user
#   group
#   version
#   elasticsearch_home
#   elasticsearch_log_dir
#   elasticsearch_myid
#
# Actions:
#   create elasticsearch users
#   deploy elasticsearch
#   deploy elasticsearch configuration
#
# Requires:
#  "repo" file share in Puppet to pull tar from
#  see Modulefile
#
# Sample Usage:
#   include ageto_elasticsearch
#
class ageto_elasticsearch (
  $version,
  $parent_dir  = $ageto_elasticsearch::defaults::parent_dir,
  $home        = $ageto_elasticsearch::defaults::home,
  $user        = $ageto_elasticsearch::defaults::user,
  $group       = $ageto_elasticsearch::defaults::group,
  $clustername = $ageto_elasticsearch::defaults::clustername,
  $config_dir  = $ageto_elasticsearch::defaults::config_dir,
  $data_dir    = $ageto_elasticsearch::defaults::data_dir,
  $plugin_dir  = $ageto_elasticsearch::defaults::plugin_dir,
  $work_dir    = $ageto_elasticsearch::defaults::work_dir,
  $log_dir     = $ageto_elasticsearch::defaults::log_dir,
  $pid_dir     = $ageto_elasticsearch::defaults::pid_dir) inherits ageto_elasticsearch::defaults {
  #
  class { 'ageto_elasticsearch::create_user':
    parent_dir => $parent_dir,
    user       => $user,
    group      => $group
  }

  class { 'ageto_elasticsearch::deploy':
    version     => $version,
    parent_dir  => $parent_dir,
    home        => $home,
    user        => $user,
    group       => $group,
    clustername => $clustername,
    config_dir  => $config_dir,
    data_dir    => $data_dir,
    plugin_dir  => $plugin_dir,
    work_dir    => $work_dir,
    log_dir     => $log_dir,
    pid_dir     => $pid_dir
  }

  class { 'ageto_elasticsearch::deploy_configuration':
    parent_dir  => $parent_dir,
    home        => $home,
    user        => $user,
    group       => $group,
    clustername => $clustername,
    config_dir  => $config_dir,
    data_dir    => $data_dir,
    plugin_dir  => $plugin_dir,
    work_dir    => $work_dir,
    log_dir     => $log_dir,
    pid_dir     => $pid_dir
  }

  class { 'ageto_elasticsearch::deploy_service':
    parent_dir  => $parent_dir,
    home        => $home,
    user        => $user,
    group       => $group,
    clustername => $clustername,
    config_dir  => $config_dir,
    data_dir    => $data_dir,
    plugin_dir  => $plugin_dir,
    work_dir    => $work_dir,
    log_dir     => $log_dir,
    pid_dir     => $pid_dir
  }
}

class ageto_elasticsearch::create_user (
  $parent_dir = $ageto_elasticsearch::defaults::parent_dir,
  $user       = $ageto_elasticsearch::defaults::user,
  $group      = $ageto_elasticsearch::defaults::group) inherits ageto_elasticsearch::defaults {
  #
  # create system group
  group { $group:
    ensure => present,
    system => true,
  }

  #
  # create system user
  user { $user:
    comment => 'ElasticSearch System User',
    ensure  => present,
    home    => $parent_dir,
    gid     => $group,
    shell   => '/bin/false',
    system  => true,
    require => Group[$group],
  }
}

class ageto_elasticsearch::deploy (
  $version,
  $parent_dir  = $ageto_elasticsearch::defaults::parent_dir,
  $home        = $ageto_elasticsearch::defaults::home,
  $user        = $ageto_elasticsearch::defaults::user,
  $group       = $ageto_elasticsearch::defaults::group,
  $clustername = $ageto_elasticsearch::defaults::clustername,
  $config_dir  = $ageto_elasticsearch::defaults::config_dir,
  $data_dir    = $ageto_elasticsearch::defaults::data_dir,
  $plugin_dir  = $ageto_elasticsearch::defaults::plugin_dir,
  $work_dir    = $ageto_elasticsearch::defaults::work_dir,
  $log_dir     = $ageto_elasticsearch::defaults::log_dir,
  $pid_dir     = $ageto_elasticsearch::defaults::pid_dir) inherits ageto_elasticsearch::defaults {
  #
  # mandatory parameters
  if !$version {
    fail("Please specify parameter 'version'!")
  }

  # create parent directory
  file { $parent_dir:
    path   => $parent_dir,
    owner  => 'root',
    group  => 'root',
    mode   => 644,
    ensure => directory,
    backup => false,
  }

  # pull tar file from a "repo" file share
  file { "elasticsearch-${version}.tar.gz":
    path   => "${parent_dir}/elasticsearch-${version}.tar.gz",
    source => "puppet:///files/elasticsearch/elasticsearch-${version}.tar.gz",
    owner  => $user,
    group  => $group,
    backup => false,
  }

  # extract tar
  exec { 'elasticsearch_untar':
    command => "tar xzf elasticsearch-${version}.tar.gz;",
    cwd     => $parent_dir,
    require => File["elasticsearch-${version}.tar.gz"],
    creates => "${parent_dir}/elasticsearch-${version}",
  }

  # fix ownership
  file { 'elasticsearch-reown-build':
    path    => "${parent_dir}/elasticsearch-${version}",
    recurse => true,
    owner   => $user,
    group   => $group,
    require => Exec['elasticsearch_untar'],
    backup  => false,
  }

  # symlink home dir to untarred elasticsearch dir
  file { "${home}":
    target  => "${parent_dir}/elasticsearch-${version}",
    ensure  => symlink,
    require => File['elasticsearch-reown-build'],
    owner   => $user,
    group   => $group,
    backup  => false,
  }

  # create logs directory
  file { 'elasticsearch_log_folder':
    path   => $log_dir,
    owner  => $user,
    group  => $group,
    mode   => 644,
    ensure => directory,
    backup => false,
  }

  # create pid directory
  file { 'elasticsearch_pid_folder':
    path   => $pid_dir,
    owner  => $user,
    group  => $group,
    mode   => 644,
    ensure => directory,
    backup => false,
  }

  # create data store
  file { 'elasticsearch_data_dir':
    path   => $data_dir,
    ensure => directory,
    owner  => $user,
    group  => $group,
    mode   => 644,
    backup => false,
  }

  # create plugin dir
  file { 'elasticsearch_plugin_dir':
    path   => $plugin_dir,
    ensure => directory,
    owner  => $user,
    group  => $group,
    mode   => 644,
    backup => false,
  }

  # create work dir
  file { 'elasticsearch_work_dir':
    path   => $work_dir,
    ensure => directory,
    owner  => $user,
    group  => $group,
    mode   => 644,
    backup => false,
  }
}

# deploy the elasticsearch configuration
class ageto_elasticsearch::deploy_configuration (
  $parent_dir  = $ageto_elasticsearch::defaults::parent_dir,
  $home        = $ageto_elasticsearch::defaults::home,
  $user        = $ageto_elasticsearch::defaults::user,
  $group       = $ageto_elasticsearch::defaults::group,
  $clustername = $ageto_elasticsearch::defaults::clustername,
  $config_dir  = $ageto_elasticsearch::defaults::config_dir,
  $data_dir    = $ageto_elasticsearch::defaults::data_dir,
  $plugin_dir  = $ageto_elasticsearch::defaults::plugin_dir,
  $work_dir    = $ageto_elasticsearch::defaults::work_dir,
  $log_dir     = $ageto_elasticsearch::defaults::log_dir,
  $pid_dir     = $ageto_elasticsearch::defaults::pid_dir) inherits ageto_elasticsearch::defaults {
  #
  # ElasticSearch configuration file
  #
  # requires a global elasticsearch cluster definition in the nodes section
  # 'key' is the server id (aka. 'myid')
  #
  #   $cluster_nodes = {
  #     '1' => { 'server' => 'node1.some.domain.com', 'serverPort' => '2888', 'leaderElectionPort' => '3888'},
  #     '2' => { 'server' => 'node2.another.domain.com', 'serverPort' => '2888', 'leaderElectionPort' => '3888' },
  #     '3' => { 'server' => 'node3.some.domain.com', 'serverPort' => '2888', 'leaderElectionPort' => '3888'}
  #   }
  #
  file { 'config/elasticsearch.yml':
    path    => "${home}/config/elasticsearch.yml",
    owner   => $user,
    group   => $group,
    mode    => 644,
    content => template('ageto_elasticsearch/config/elasticsearch.yml.erb'),
    require => File[$home],
  }

  # the logging configuration
  file { 'config/logging.yml':
    path    => "${home}/config/logging.yml",
    owner   => $user,
    group   => $group,
    mode    => 644,
    content => template('ageto_elasticsearch/config/logging.yml.erb'),
    require => File[$home],
  }
}

class ageto_elasticsearch::deploy_service (
  $parent_dir  = $ageto_elasticsearch::defaults::parent_dir,
  $home        = $ageto_elasticsearch::defaults::home,
  $user        = $ageto_elasticsearch::defaults::user,
  $group       = $ageto_elasticsearch::defaults::group,
  $clustername = $ageto_elasticsearch::defaults::clustername,
  $config_dir  = $ageto_elasticsearch::defaults::config_dir,
  $data_dir    = $ageto_elasticsearch::defaults::data_dir,
  $plugin_dir  = $ageto_elasticsearch::defaults::plugin_dir,
  $work_dir    = $ageto_elasticsearch::defaults::work_dir,
  $log_dir     = $ageto_elasticsearch::defaults::log_dir,
  $pid_dir     = $ageto_elasticsearch::defaults::pid_dir) inherits ageto_elasticsearch::defaults {
  #
  # init script location
  $init_d_path     = $operatingsystem ? {
    Darwin  => '/usr/bin/elasticsearch_service',
    default => '/etc/init.d/elasticsearch',
  }
  # init script template
  $init_d_template = $operatingsystem ? {
    /(?i-mx:ubuntu|debian)/        => 'ageto_elasticsearch/service/elasticsearch_service_debian.erb',
    /(?i-mx:centos|fedora|redhat)/ => 'ageto_elasticsearch/service/elasticsearch_service_redhat.erb',
    default => fail("No Init script template for ${operatingsystem}!"),
  }

  file { 'elasticsearch_init_script':
    path    => $init_d_path,
    content => template($init_d_template),
    ensure  => file,
    owner  => 'root',
    group  => 'root',
    mode    => 755
  }
}

class ageto_elasticsearch::defaults {
  $user        = 'elasticsearch'
  $group       = 'elasticsearch'
  $clustername = 'elasticsearch'

  $parent_dir  = '/srv/elasticsearch'
  $home        = '/srv/elasticsearch/current'

  $log_dir     = $operatingsystem ? {
    Darwin  => "/Users/$user/Library/Logs/elasticsearch/",
    default => "/var/log/elasticsearch",
  }
  $pid_dir     = '/var/run/elasticsearch'

  $config_dir  = "${home}/config"
  $plugin_dir  = "${home}/plugins"

  $data_dir    = "${parent_dir}/data"

  $work_dir    = '/tmp/elasticsearch'
}
