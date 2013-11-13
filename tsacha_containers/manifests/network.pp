# network.pp
#
# Prepare networking for LXC usage

class tsacha_containers::network {
   Exec { path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/" ] }

   # Containers will be attached on an OVS switch
   package { 'openvswitch-switch':
     ensure => installed
   }

   package { 'ethtool':
     ensure => installed
   }

   # Empty service : we will refresh it if network is modified
   service { 'networking':
   }

   # Modified init script to ensure that OVS bridges are started first
   file { "/etc/init.d/openvswitch-switch":
     owner   => root,
     group   => root,
     mode    => 755,
     ensure  => present,
     content => template('tsacha_containers/ovs-init.erb'),
     require => Package['openvswitch-switch']
   } ~>


   # Update rc levels
   exec { "rm-lsb-ovs":
     command => "update-rc.d -f openvswitch-switch remove",
     onlyif => "bash -c 'ls /etc/rc[1-5].d/*openvswit*'",
   }

   exec { "insserv":
     command => "insserv openvswitch-switch",
     subscribe => Exec["rm-lsb-ovs"],
     refreshonly => true
   }
   
   exec { "enable-lsb-ovs":
     command => "update-rc.d openvswitch-switch enable",
     subscribe => Exec["insserv"],
     refreshonly => true
   }   

   service { 'openvswitch-switch':
     ensure => running,
     require => Exec["enbale-lsb-ovs"]
   }

   # IP forward
   exec { "ip_forward_temp":
     command => "sysctl -w net.ipv4.ip_forward=1",
     unless => "sysctl net.ipv4.ip_forward | grep 'net.ipv4.ip_forward = 1'",
   }

   exec { "ip_forward":
     command => "sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf",
     onlyif => "grep '#net.ipv4.ip_forward=1' /etc/sysctl.conf"
   }

   # Compute node will use controller node to resolv dns
   file { "/etc/resolv.conf":
     owner   => root,
     group   => root,
     mode    => 644,
     ensure  => present,
     content => template('tsacha_containers/resolv.conf.erb'),
   }  
   
   # Postrouting, masquerade
   file { "/etc/iptables.up.rules":
     owner   => root,
     group   => root,
     mode    => 600,
     ensure  => present,
     content => template('tsacha_containers/iptables.up.rules.erb'),
   } ~>
   
   exec { 'iptables-restore':
     command => "iptables-restore < '/etc/iptables.up.rules'",
     refreshonly => true
   }
     
   file { "/etc/network/if-pre-up.d/iptables":
     owner   => root,
     group   => root,
     mode    => 700,
     ensure  => present,
     content => template('tsacha_containers/network_iptables.erb'),
   }

   # External bridge
   exec { "create-bridge":
     command => "ovs-vsctl add-br br-ex",
     unless => "ovs-vsctl br-exists br-ex",
     require => Service['openvswitch-switch']
   }

   exec { "up-bridge":
     command => "ip link set br-ex up",
     unless => "ip link show br-ex | grep UP",
     require => Exec["create-bridge"]
   }

   # Add current IP address to the bridge
   exec { "addr-bridge":
     command => "ip address add $ip_address/$cidr dev br-ex",
     unless => "ip address show br-ex | grep $ip_address/$cidr",
     require => Exec["create-bridge"]
   }

   # Add current IPv6 address to the bridge
   exec { "addr6-bridge":
     command => "ip -6 address add $ip6_address/$cidr6 dev br-ex",
     unless => "ip -6 address show br-ex | grep $ip6_address/$cidr6",
     require => Exec["create-bridge"]
   }

   # Link bridge to the physical interface
   exec { "phys-bridge":
     command => "ovs-vsctl add-port br-ex eth0",
     unless => "ovs-vsctl list-ports br-ex | grep -E '^eth0$'",
     require => Exec["addr-bridge"]
   }

   # Use bridge
   exec { "switch-bridge": 
     command => "ip route del default via $gateway dev eth0 && ip route add default via $gateway dev br-ex",
     unless => "ip route list 0/0 | grep br-ex",
     require => Exec["phys-bridge"]
   }

   # Use bridge with IPv6
   exec { "switch6-bridge": 
     command => "ip -6 route del default via $gateway6 dev eth0 && ip route add default via $gateway6 dev br-ex",
     unless => "ip -6 route list | grep default | grep br-ex",
     require => Exec["phys-bridge"]
   }

   # Internal bridge
   exec { "create-bridge-int":
     command => "ovs-vsctl add-br br-int",
     unless => "ovs-vsctl br-exists br-int",
     require => Service['openvswitch-switch']
   }

   exec { "up-bridge-int":
     command => "ip link set br-int up",
     unless => "ip link show br-int | grep UP",
     require => Exec["create-bridge-int"]
   }

   # Add current address to the internal bridge
   exec { "addr-bridge-int":
     command => "ip address add $ip_private_address/$cidr_private dev br-int",
     unless => "ip address show br-int | grep $ip_private_address/$cidr_private",
     require => Exec["up-bridge-int"]
   }

   file { "/etc/network/interfaces":
     owner   => root,
     group   => root,
     mode    => 644,
     ensure  => present,
     content => template('tsacha_containers/network_conf.erb'),
     require => [Exec["switch-bridge"],Exec["switch6-bridge"],Exec['addr-bridge-int']],
     notify => Service['networking'],
   }
}