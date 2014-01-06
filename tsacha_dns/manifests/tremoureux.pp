class tsacha_dns::tremoureux {

    Exec { path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/" ] }

    File {
      ensure => present,
      owner => root,
      group => bind,
      mode => 640,
     }

    file { "/var/lib/named/etc/bind/tremoureux.fr.ksk.private":
      source => "puppet:///modules/tsacha_private/tremoureux.fr.ksk.private",
      mode => 400
    }

    file { "/var/lib/named/etc/bind/tremoureux.fr.ksk.key":
      source => "puppet:///modules/tsacha_private/tremoureux.fr.ksk.key",
    }

    file { "/var/lib/named/etc/bind/tremoureux.fr.zsk.private":
      source => "puppet:///modules/tsacha_private/tremoureux.fr.zsk.private",
      mode => 400
    }

    file { "/var/lib/named/etc/bind/tremoureux.fr.zsk.key":
      source => "puppet:///modules/tsacha_private/tremoureux.fr.zsk.key",
    }

    file { "/var/lib/named/etc/bind/db.tremoureux.fr":
      source => "puppet:///modules/tsacha_dns/tremoureux.fr",
    } ~>

    exec { "sign-zone":
      command => "dnssec-signzone -e20160106150000 -p -t -g -k tremoureux.fr.ksk.key -o tremoureux.fr db.tremoureux.fr tremoureux.fr.zsk.key",
      cwd => "/var/lib/named/etc/bind",
      unless => "test $(cat db.tremoureux.fr.signed | grep -A1 'IN SOA' | tail -n 1 | awk '{print \$1}') -eq $(cat db.tremoureux.fr | grep -A1 'IN SOA' | tail -n 1 | awk '{print \$1}')",
      require => File["/var/lib/named/etc/bind/db.tremoureux.fr"]
    }

}
