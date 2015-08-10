# test
#
# one machine setup with weblogic 10.3.6 with BSU
# needs jdk7, orawls, orautils, fiddyspence-sysctl, erwbgy-limits puppet modules
#

node 'admin.example.com' {

  include os
  include java, orawls::urandomfix
  include orawls::weblogic, orautils
  include bsu
  include fmw
  include opatch

  Class[java] -> Class[orawls::weblogic]
}

# operating settings for Middleware
class os {

  $default_params = {}
  $host_instances = hiera('hosts', {})
  create_resources('host',$host_instances, $default_params)

  # exec { "create swap file":
  #   command => "/bin/dd if=/dev/zero of=/var/swap.1 bs=1M count=8192",
  #   creates => "/var/swap.1",
  # }

  # exec { "attach swap file":
  #   command => "/sbin/mkswap /var/swap.1 && /sbin/swapon /var/swap.1",
  #   require => Exec["create swap file"],
  #   unless => "/sbin/swapon -s | grep /var/swap.1",
  # }

  # #add swap file entry to fstab
  # exec {"add swapfile entry to fstab":
  #   command => "/bin/echo >>/etc/fstab /var/swap.1 swap swap defaults 0 0",
  #   require => Exec["attach swap file"],
  #   user => root,
  #   unless => "/bin/grep '^/var/swap.1' /etc/fstab 2>/dev/null",
  # }

  service { iptables:
        enable    => false,
        ensure    => false,
        hasstatus => true,
  }

  group { 'oinstall' :
    ensure => present,
  }

  # http://raftaman.net/?p=1311 for generating password
  # password = oracle
  user { 'oracle' :
    ensure     => present,
    groups     => 'oinstall',
    shell      => '/bin/bash',
    password   => '$1$DSJ51vh6$4XzzwyIOk6Bi/54kglGk3.',
    home       => "/home/oracle",
    comment    => 'wls user created by Puppet',
    managehome => true,
    require    => Group['oinstall'],
  }

  $install = [
    'binutils.x86_64',
    'unzip.x86_64',
    'compat-libcap1.i686',
    'compat-libcap1.x86_64',
    'compat-libstdc++-33.i686',
    'compat-libstdc++-33.x86_64',
    'ksh.x86_64',
    'libaio.x86_64',
    'libaio-devel.x86_64',
    'libgcc.x86_64',
    'libstdc++.x86_64',
    'libstdc++-devel.x86_64',
    'make.x86_64',
    'gcc.x86_64',
    'gcc-c++.x86_64',
    'glibc.x86_64',
    'glibc.i686',
    'glibc-devel.i686',
    'glibc-devel.x86_64',
    'sysstat.x86_64',
    'unixODBC-devel',
    'libXext.i686',
    'libXtst.i686',
    'libXi.i686',
    'openmotif.x86_64',
    'openmotif22.x86_64',
    'xorg-x11-xauth.x86_64',
    'elfutils-libelf-devel',
    'redhat-lsb-core',
    ]

  package { $install:
    ensure  => present,
  }

  class { 'limits':
    config => {
               '*'       => {  'nofile'  => { soft => '2048'   , hard => '8192',   },},
               'oracle'  => {  'nofile'  => { soft => '65536'  , hard => '65536',  },
                               'nproc'   => { soft => '2048'   , hard => '16384',   },
                               'memlock' => { soft => '1048576', hard => '1048576',},
                               'stack'   => { soft => '10240'  ,},},
               },
    use_hiera => false,
  }

  sysctl { 'kernel.msgmnb':                 ensure => 'present', permanent => 'yes', value => '65536',}
  sysctl { 'kernel.msgmax':                 ensure => 'present', permanent => 'yes', value => '65536',}
  sysctl { 'kernel.shmmax':                 ensure => 'present', permanent => 'yes', value => '2588483584',}
  sysctl { 'kernel.shmall':                 ensure => 'present', permanent => 'yes', value => '2097152',}
  sysctl { 'fs.file-max':                   ensure => 'present', permanent => 'yes', value => '6815744',}
  sysctl { 'net.ipv4.tcp_keepalive_time':   ensure => 'present', permanent => 'yes', value => '1800',}
  sysctl { 'net.ipv4.tcp_keepalive_intvl':  ensure => 'present', permanent => 'yes', value => '30',}
  sysctl { 'net.ipv4.tcp_keepalive_probes': ensure => 'present', permanent => 'yes', value => '5',}
  sysctl { 'net.ipv4.tcp_fin_timeout':      ensure => 'present', permanent => 'yes', value => '30',}
  sysctl { 'kernel.shmmni':                 ensure => 'present', permanent => 'yes', value => '4096', }
  sysctl { 'fs.aio-max-nr':                 ensure => 'present', permanent => 'yes', value => '1048576',}
  sysctl { 'kernel.sem':                    ensure => 'present', permanent => 'yes', value => '250 32000 100 128',}
  sysctl { 'net.ipv4.ip_local_port_range':  ensure => 'present', permanent => 'yes', value => '9000 65500',}
  sysctl { 'net.core.rmem_default':         ensure => 'present', permanent => 'yes', value => '262144',}
  sysctl { 'net.core.rmem_max':             ensure => 'present', permanent => 'yes', value => '4194304', }
  sysctl { 'net.core.wmem_default':         ensure => 'present', permanent => 'yes', value => '262144',}
  sysctl { 'net.core.wmem_max':             ensure => 'present', permanent => 'yes', value => '1048576',}

}



class java {
  require os

  $remove = [ "java-1.7.0-openjdk.x86_64", "java-1.6.0-openjdk.x86_64" ]

  package { $remove:
    ensure  => absent,
  }

  include jdk7


  jdk7::install7{ 'jdk1.7.0_80':
      version                   => "7u80" ,
      fullVersion               => "jdk1.7.0_80",
      alternativesPriority      => 18000,
      x64                       => true,
      downloadDir               => "/var/tmp/install",
      urandomJavaFix            => true,
      rsakeySizeFix             => true,
      cryptographyExtensionFile => "UnlimitedJCEPolicyJDK7.zip",
      sourcePath                => "/software",
  }

}


class bsu{
  require orawls::weblogic
  $default_params = {}
  $bsu_instances = hiera('bsu_instances', {})
  create_resources('orawls::bsu',$bsu_instances, $default_params)
}

class fmw{
  require bsu
  $default_params = {}
  $fmw_installations = hiera('fmw_installations', {})
  create_resources('orawls::fmw',$fmw_installations, $default_params)
}

class forms_11g_patch{
  require fmw
  $default_params = {}
  $forms_11g_patches = hiera('forms_11g_patches', {})
  create_resources('orawls::utils::forms11gpatch',$forms_11g_patches, $default_params)
}

class opatch{
  require forms_11g_patch, fmw, bsu, orawls::weblogic
  $default_params = {}
  $opatch_instances = hiera('opatch_instances', {})
  create_resources('orawls::opatch',$opatch_instances, $default_params)
}

