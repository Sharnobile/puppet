class tsacha_dns {
   require tsacha_system

   package { 'bind9':
     ensure => installed
   }
}