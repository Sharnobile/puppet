class tsacha_dns::install {

    Exec { path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/" ] }

    package { 'bind9':
      ensure => installed,
      notify => Service['bind9']
    } ->
    
    exec { 'kill-bind':
      command => "kill -9 $(cat /var/run/named/named.pid) && rm -Rf /var/run/named",
      onlyif => "stat /var/run/named/named.pid"
    }

    package { 'dnsutils':
      ensure => installed
    }

    $bindfolders = ["/var/lib/named/","/var/lib/named/etc/","/var/lib/named/etc/bind/","/var/lib/named/dev","/var/lib/named/var","/var/lib/named/var/cache","/var/lib/named/var/cache/bind"]

    file { $bindfolders:
      owner   => root,
      group   => bind,
      mode    => 750,
      ensure  => directory,
      require => [Package['bind9'],Exec['kill-bind']],
      notify  => Service['bind9']
    }

    file { ["/var/lib/named/var/log"]:
      owner   => bind,
      group   => bind,
      mode    => 750,
      ensure  => directory,
      notify => Service['bind9'],
      require => File[$bindfolders]
    }

    File {
      ensure => present,
      owner => root,
      group => bind,
      mode => 640,
      notify => Service['bind9'],
      require => File[$bindfolders]
    }
      

    file { "/var/lib/named/etc/bind/named.conf":
      content => template('tsacha_dns/named.conf.erb'),
    }

    file { "/var/lib/named/etc/bind/named.conf.default-zones":
      content => template('tsacha_dns/named.conf.default-zones.erb'),
    }

    file { "/var/lib/named/etc/bind/named.conf.local":
      content => template('tsacha_dns/named.conf.local.erb'),
    }

    file { "/var/lib/named/etc/bind/named.conf.options":
      content => template('tsacha_dns/named.conf.options.erb'),
    }

    file { "/var/lib/named/etc/bind/named.conf.log":
      content => template('tsacha_dns/named.conf.log.erb'),
    }

    file { "/var/lib/named/etc/bind/bind.keys":
      source => "/etc/bind/bind.keys",
    }

    file { "/var/lib/named/etc/bind/db.0":
      source => "/etc/bind/db.0",
    }

    file { "/var/lib/named/etc/bind/db.127":
      source => "/etc/bind/db.127",
    }

    file { "/var/lib/named/etc/bind/db.255":
      source => "/etc/bind/db.255",
    }

    file { "/var/lib/named/etc/bind/db.empty":
      source => "/etc/bind/db.empty",
    }

    file { "/var/lib/named/etc/bind/db.local":
      source => "/etc/bind/db.local",
    }

    file { "/var/lib/named/etc/bind/db.root":
      source => "/etc/bind/db.root",
    }

    file { "/var/lib/named/etc/bind/rndc.key":
      source => "/etc/bind/rndc.key",
    }

    file { "/var/lib/named/etc/bind/zones.rfc1918":
      source => "/etc/bind/zones.rfc1918",
    }

    file { "/etc/init.d/bind9":
      owner   => root,
      group   => root,
      mode    => 755,
      content => template('tsacha_dns/bind_init.erb'),
      notify => Service['bind9']
    }


    file { "/etc/default/bind9":
      owner => root,
      group => root,
      mode => 644,
      content => template('tsacha_dns/bind_default.erb'),
      notify => Service['bind9']
    }

    service { 'bind9':
      ensure => running
    }    
}