class tsacha_dns::tremoureux {

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

}
