# lxc.pp
#
# LibVirt+LXC installation

class tsacha_containers::lxc {
   Exec { path => [ "/opt/libvirt/bin", "/opt/libvirt/sbin", "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/" ] }

   apt::force { "lxc":
     release => "testing",
     require => Apt::Source["testing"]
   }

   $libvirt_dep = [ "libaudit0", "libavahi-client3", "libavahi-common3", "libcap-ng0", "libnetcf1", "libnl1", "libnuma1", "libparted0debian1", "libpcap0.8", "libpciaccess0", "libsanlock-client1", "pm-utils", "libdevmapper1.02.1", "ebtables" ]

   package { $libvirt_dep: ensure => "installed" } ->

   package { "dnsmasq":
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
     command => 'bash /etc/rc.local',
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
     require => [File["/tmp/libvirt_1.1.4_amd64.deb"],Package["dnsmasq"]],
     ensure => installed,
     source => "/tmp/libvirt_1.1.4_amd64.deb",
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
   
   service { "dnsmasq":
     ensure => stopped,
     require => Package["dnsmasq"]
   }

   service { "libvirt":
     ensure => running,
     enable => true,
     hasstatus => true,
     hasrestart => true,
     require => [File['/etc/init.d/libvirt'],File["/etc/libvirt/libvirtd.conf"],File["/etc/libvirt/libvirt.conf"],Package['libvirt'],Package['libnl1'],Package['libnuma1'],Service['dnsmasq']]
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