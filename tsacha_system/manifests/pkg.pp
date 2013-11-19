# pkg.pp
#
# Generic packages

class tsacha_system::pkg {
   Exec { path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/" ] }
   
   package { 'emacs23-nox':
     ensure => installed
   }

   package { 'dbus':
     ensure => installed
   } ->
   
   service { 'dbus':
     ensure => running
   }
}  
