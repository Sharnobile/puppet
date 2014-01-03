# dns.pp
#
# DNS container generation

class tsacha_containers::dns {
   Exec { path => [ "/srv", "/opt/libvirt/bin", "/opt/libvirt/sbin", "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/" ] }

  define device_node($type="c",$major,$minor,$mode) {
    exec { "create-device-${name}":
      command => "mknod -m ${mode} ${name} ${type} ${major} ${minor}",
      path => "/bin",
      creates => $name,
    }
  }

  exec { "generate-dns-container":
    command => "ruby /srv/generate_container.rb --hostname $dns_hostname --domain $fqdn --ip $dns_ip --cidr $dns_cidr --gateway $ip_private_address --ip6 $dns_ip6 --cidr6 $dns_cidr --gateway6 $gateway6 --dns 8.8.8.8 --puppet $puppet_server",
    unless => "virsh list --all | grep dns",
    timeout => 500
  } ->

  file { ["/var/lib/lxc/dns/rootfs/var/lib/named/","/var/lib/lxc/dns/rootfs/var/lib/named/dev"]:
    ensure  => directory,
  } ->

  device_node { "/var/lib/lxc/dns/rootfs/var/lib/named/dev/null":
    type => c,
    major => 1,
    minor => 3,
    mode => 0666,
  } ->

  device_node { "/var/lib/lxc/dns/rootfs/var/lib/named/dev/random":
    type => c,
    major => 1,
    minor => 8,
    mode => 0666
  } ->

  exec { "start-dns-container":
    command => "virsh start dns",
    unless => "virsh list | grep dns",
    require => [Device_node["/var/lib/lxc/dns/rootfs/var/lib/named/dev/random","/var/lib/lxc/dns/rootfs/var/lib/named/dev/null"]]
  }
}