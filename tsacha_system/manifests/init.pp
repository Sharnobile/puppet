class tsacha_system {
   class { 'tsacha_system::repo': } ->
   class { 'tsacha_system::pkg': }
}
