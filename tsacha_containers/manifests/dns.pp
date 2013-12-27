# dns.pp
#
# DNS container generation

class tsacha_containers::dns {
   Exec { path => [ "/srv", "/opt/libvirt/bin", "/opt/libvirt/sbin", "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/" ] }

  exec { "generate-dns-container":
    command => "ruby generate_container.rb --hostname dns --domain oslo.s.tremoureux.fr --ip 10.1.0.2 --cidr 16 --gateway 10.1.0.1 --ip6 2a01:4f8:151:7307:1::2 --cidr6 64 --gateway6 fe80::1 --dns 8.8.8.8 --puppet tromso.s.tremoureux.fr",
    unless => "virsh list --all | grep dns",
    timeout => 500
  }

  exec { "start-dns-container":
    command => "virsh start dns",
    unless => "virsh list | grep dns"
  }
}