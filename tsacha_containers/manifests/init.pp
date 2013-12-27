class tsacha_containers {
   require tsacha_system
   class { 'tsacha_containers::network': } ->
   class { 'tsacha_containers::lxc': } ->
   class { 'tsacha_containers::dns': }
}