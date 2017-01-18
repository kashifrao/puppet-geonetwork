# == Class: project::geonetwork
# === Copyright
#
# All Rights Reserved.
# 

class project::geonetwork (
  $dbuser = 'geonetwork',
  $dbname = 'geonetwork',
  $dbpass = 'geonet',
  $warfile_url = 'https://sourceforge.net/projects/geonetwork/files/GeoNetwork_opensource/v3.2.0/geonetwork.war',
) {

  

  class { 'postgresql::globals':
    version => '9.3',
    manage_package_repo => true,
  }->
  class { 'postgresql::server':
    listen_addresses => '*',
  }->
  class { 'pkg::python::psycopg2':
  }

  postgresql::server::db { $dbname:
    user     => $dbuser,
    password => $dbpass,
  }

  postgresql::server::pg_hba_rule { 'geonetwork slaves':
    type        => 'host',
    database    => 'all',
    user        => 'geonetwork',
    address     => 'xxxxxxxxxxx',
    auth_method => 'trust',
  }

  
   
  include tomcat

  $heap = floor($::memory['system']['total_bytes']*0.75/1024/1024)

  tomkat::javaopts { 'geonetwork':
    appname   => 'geonetwork',
    java_opts => "-Xms${heap}m -Xmx${heap}m -XX:MaxPermSize=128m",
  }

  $app_dir     = "/usr/share/tomcat/webapps/geonetwork"
  $web_inf_dir = "${app_dir}/WEB-INF"

  file { $app_dir:
    ensure => directory,
    owner  => 'tomcat',
    group  => 'tomcat',
    mode   => '0755',
  }

  nci::untar { 'geonetwork warfile':
    source     => $warfile_url,
    target_dir => $app_dir,
    notify     => Service['tomcat'],
  }

  exec { 'tomcat must own all the webapp dir':
    command     => "/bin/chown -R tomcat:tomcat ${app_dir}",
    subscribe   => Nci::Untar['geonetwork warfile'],
    refreshonly => true,
    notify      => Service['tomcat'],
  }

  file { "${web_inf_dir}/config-node/srv.xml":
    ensure  => file,
    owner   => 'tomcat',
    group   => 'tomcat',
    mode    => '0600',
    source  => 'puppet:///modules/bundle/project/geonetwork/srv.xml',
    require => Nci::Untar['geonetwork warfile'],
    notify  => Service['tomcat'],
  }

   
  file { "${web_inf_dir}/config-db/jdbc.properties":
    ensure  => file,
    owner   => 'tomcat',
    group   => 'tomcat',
    mode    => '0600',
    content => template('bundle/project/geonetwork/jdbc.properties.erb'),
    require => Nci::Untar['geonetwork warfile'],
    notify  => Service['tomcat'],
  }

   
 include pkg::python::devel
  include pkg::postgresql::devel
 include pkg::mysql::python 

 
  
  


}
