class apache (
  $with_mods = []
) {
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

  exec { "force-reload-apache2":
      command => "/etc/init.d/apache2 force-reload",
      refreshonly => true,
  }
}