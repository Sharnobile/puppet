# conf.pp
#
# Generic system configuration

class tsacha_system::conf{
   # Compute node will use controller node to resolv dns
   file { "/etc/resolv.conf":
     owner   => root,
     group   => root,
     mode    => 644,
     ensure  => present,
     content => template('tsacha_system/resolv.conf.erb'),
   }  
}