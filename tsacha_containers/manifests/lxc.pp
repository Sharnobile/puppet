# lxc.pp
#
# LibVirt+LXC installation

class tsacha_containers::lxc {
   Exec { path => [ "/opt/libvirt/bin", "/opt/libvirt/sbin", "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/" ] }

   apt::force { "lxc":
     release => "testing",
     require => Apt::Source["testing"]
   }

   $libvirt_dep = [ "libaudit0", "libavahi-client3", "libavahi-common3", "libcap-ng0", "libnetcf1", "libnl1", "libnuma1", "libparted0debian1", "libpcap0.8", "libpciaccess0", "libsanlock-client1", "pm-utils", "libdevmapper1.02.1", "libxenstore3.0", "libyajl2", "ebtables" ]

   package { $libvirt_dep: ensure => "installed" } ->

   package { "dnsmasq":
     ensure => installed
   }

   file { "/etc/rc.local":
     owner   => root,
     group   => root,
     mode    => 540,
     ensure  => present,
     content => template('tsacha_containers/rc.local')
   }

   exec { "mount-cgroup":
     command => 'bash /etc/rc.local',
     unless => "mount | grep cgroup",
   }

   file { "/opt/libvirt_1.1.4_amd64.deb":
     owner   => root,
     group   => root,
     mode    => 600,
     ensure  => present,
     source  => "puppet:///modules/tsacha_containers/libvirt_1.1.4_amd64.deb"
   }
  
   package { "libvirt":
     require => [File["/opt/libvirt_1.1.4_amd64.deb"],Package["dnsmasq"]],
     ensure => installed,
     source => "/opt/libvirt_1.1.4_amd64.deb",
     provider => dpkg,
   }

   file { "/etc/init.d/libvirt":
     owner   => root,
     group   => root,
     mode    => 755,
     ensure  => present,
     content => template('tsacha_containers/libvirt.initd')
   }

   file { "/etc/libvirt/libvirtd.conf":
     owner   => root,
     group   => root,
     mode    => 644,
     ensure  => present,
     content => template('tsacha_containers/libvirtd.conf.erb'),
     require => Package["libvirt"]
   }

   file { "/etc/libvirt/libvirt.conf":
     owner   => root,
     group   => root,
     mode    => 644,
     ensure  => present,
     content => template('tsacha_containers/libvirt.conf.erb'),
     require => Package["libvirt"]
   }
   
   service { "libvirt":
     ensure => running,
     enable => true,
     hasstatus => true,
     hasrestart => true,
     require => [File['/etc/init.d/libvirt'],File["/etc/libvirt/libvirtd.conf"],File["/etc/libvirt/libvirt.conf"],Package['libvirt'],Package['libnl1'],Package['libnuma1']]
   }

   exec { "virsh-net-destroy":
     command => "virsh -c lxc:/// net-destroy default",
     onlyif => "virsh -c lxc:/// net-list | grep default",
     require => Service['libvirt']
   } ->

   exec { "virsh-net-undefine":
     command => "virsh -c lxc:/// net-undefine default",
     onlyif => "virsh -c lxc:/// net-list --all | grep default",
     require => Service['libvirt']
   }

   package { 'ruby-dev':
     ensure => installed
   }

   package { 'libvirt-dev':
     ensure => installed
   }

   exec { 'ruby-libvirt':
     command => 'gem install --no-rdoc --no-ri ruby-libvirt -- --with-opt-dir=/opt/libvirt/ --with-opt-include=/opt/libvirt/include/ --with-opt-lib=/opt/libvirt/lib/ --with-libvirt-include=/opt/libvirt/include/ --with-libvirt-lib=/opt/libvirt/lib/',
     require => [Package['ruby-dev'],Package['libvirt-dev'],Service['libvirt']],
     unless => "gem list ruby-libvirt | grep ruby-libvirt"
   }

   file { "/usr/sbin/libvirtd":
     ensure => 'link',
     target => '/opt/libvirt/sbin/libvirtd',
     require => Service['libvirt']
   }

   package { 'archive-tar-minitar':
     ensure => installed,
     provider => gem,
     require => [Package['ruby-dev']]
   }


   file { "/srv/generate_container.rb":
     owner   => root,
     group   => root,
     mode    => 755,
     ensure  => present,
     content => template('tsacha_containers/generate_container.rb.erb')
   }

}