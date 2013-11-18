# lxc.pp
#
# LibVirt+LXC installation

class tsacha_containers::lxc {
   Exec { path => [ "/opt/libvirt/bin", "/opt/libvirt/sbin", "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/" ] }

   apt::force { "lxc":
     release => "testing",
     require => Apt::Source["testing"]
   }

   package { 'pm-utils':
     ensure => installed
   }

   package { 'libnl1':
     ensure => installed
   }

   package { 'libnuma1':
     ensure => installed
   }
   
   package { 'libdevmapper1.02.1':
     ensure => installed
   }

   service { "dbus":
     ensure => running
   }

   file { "/etc/rc.local":
     owner   => root,
     group   => root,
     mode    => 540,
     ensure  => present,
     content => template('tsacha_containers/rc.local')
   }

   exec { "mount-cgroup":
     command => 'mount -a',
     unless => "mount | grep cgroup",
   }

   file { "/tmp/libvirt_1.1.4_amd64.deb":
     owner   => root,
     group   => root,
     mode    => 600,
     ensure  => present,
     source  => "puppet:///modules/tsacha_containers/libvirt_1.1.4_amd64.deb"
   }
  
   package { "libvirt":
     require => File["/tmp/libvirt_1.1.4_amd64.deb"],
     ensure => installed,
     source => "/tmp/libvirt.deb",
     provider => dpkg
   }

   file { "/etc/init.d/libvirt":
     owner   => root,
     group   => root,
     mode    => 755,
     ensure  => present,
     content => template('tsacha_containers/libvirt.initd')
   }

   service { "libvirt":
     ensure => running,
     enable => true,
     hasstatus => true,
     hasrestart => true,
     require => [File['/etc/init.d/libvirt'],Package['libvirt'],Package['libnl1'],Package['libnuma1']]
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

   file { "/srv/generate_container.sh":
     owner   => root,
     group   => root,
     mode    => 755,
     ensure  => present,
     content => template('tsacha_containers/generate_container.sh.erb')
   }

}