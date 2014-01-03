# repo.pp
#
# Prepare aptitude

class tsacha_system::repo {
   Exec { path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/" ] }

  include apt

  apt::source { 'puppetlabs':
    location          => 'http://apt.puppetlabs.com',
    release           => 'wheezy',
    repos             => 'main',
    include_src       => true
  }

  apt::source { 'puppetlabs-dep':
    location          => 'http://apt.puppetlabs.com',
    release           => 'wheezy',
    repos             => 'dependencies',
    include_src       => true
  }
  
  apt::source { 'stable':
    location          => 'http://ftp.fr.debian.org/debian',
    release           => 'stable',
    repos             => 'main contrib non-free',
    include_src       => true
  }

  apt::source { 'testing':
    location          => 'http://ftp.fr.debian.org/debian',
    release           => 'testing',
    repos             => 'main contrib non-free',
    include_src       => true
  }      

  apt::pin { "puppetlabs":
    priority => 700,
    originator => Puppetlabs
  }
  
  apt::pin { "stable":
    priority => 700
  }

  apt::pin { "testing":
    priority => 400
  }

  apt::key { 'puppetlabs':
    key        => '4BD6EC30',
    key_source => 'http://apt.puppetlabs.com/pubkey.gpg',
  }

  package { 'puppet':
    ensure => installed
  }
}  
