# lxc.pp
#
# LibVirt+LXC installation

class tsacha_containers::lxc {
   Exec { path => [ "/opt/libvirt", "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/" ] }

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

   file { "/opt/libvirt/":
     ensure => directory,
     owner => root,
     group => root,
     mode => 775,
   }

   file { "/tmp/libvirt.tar.xz":
     owner   => root,
     group   => root,
     mode    => 600,
     ensure  => present,
     source  => "puppet:///modules/tsacha_containers/libvirt.tar.xz"
   }
  
   exec { "deploy-libvirt":
     command => "tar -xvJf /tmp/libvirt.tar.xz",
     cwd => "/opt/libvirt",
     unless => "stat /opt/libvirt/sbin/libvirtd",
     require => File["/opt/libvirt"]
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
     require => [File['/etc/init.d/libvirt'],Exec['deploy-libvirt'],Package['libnl1'],Package['libnuma1']]
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