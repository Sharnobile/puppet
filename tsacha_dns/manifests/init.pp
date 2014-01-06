class tsacha_dns {
    require tsacha_system
    class { 'tsacha_dns::install': } ->
    class { 'tsacha_dns::tremoureux': }

}