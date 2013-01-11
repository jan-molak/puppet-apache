class apache (
  $with_mods = []
) {
  stage { 'apache2_post': require => Stage['main'] }
  class { 'apache2::post': stage => 'apache2_post'; }

  package { 'apache2':  ensure => present }

  group   { 'www-data': ensure => present }

  user    { 'www-data':
    ensure  => present,
    gid     => 'www-data',
    require => [ Group['www-data'], Package['apache2'] ],
  }

  $hosts_source = only_existing_sources([
    '/vagrant/files/apache/etc/hosts',
    'puppet:///modules/apache/etc/hosts'
  ])

  if $hosts_source != [] {
    file { '/etc/hosts':
      source  => $hosts_source,
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      mode    => 0644
    }
  }

  a2enmod { $with_mods: }

  define a2enmod() {
    exec { "a2enmod ${name}":
        require => Package["apache2"],
        notify  => Exec["force-reload-apache2"],
    }
  }
}

class apache2::post {
  $confd_source = only_existing_sources([
    '/vagrant/files/apache/etc/apache2/conf.d',
    'puppet:///modules/apache/etc/apache2/conf.d'
  ])

  if $confd_source != [] {
    file { "/etc/apache2/conf.d":
        ensure  => directory,
        recurse => true,
        force   => true,
        owner   => "root",
        group   => "root",
        mode    => 0644,
        source  => $confd_source,
        notify  => Exec["force-reload-apache2"],
    }
  }

  $sites_enabled_source = only_existing_sources([
    '/vagrant/files/apache/etc/apache2/sites-enabled',
    'puppet:///modules/apache/etc/apache2/sites-enabled'
  ])

  if $sites_enabled_source != [] {
    file { "/etc/apache2/sites-enabled":
      ensure  => directory,
      recurse => true,
      purge   => true,
      force   => true,
      owner   => "root",
      group   => "root",
      mode    => 0644,
      source  => $sites_enabled_source,
      notify  => Exec["force-reload-apache2"],
    }
  }

  exec { "force-reload-apache2":
      command => "/etc/init.d/apache2 force-reload",
      refreshonly => true,
  }
}