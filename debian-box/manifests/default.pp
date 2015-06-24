### load path settings
Exec {
  path => "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
}

exec { "apt-get update":
  command => "apt-get update"
}

exec { "apt-get upgrade":
  command => "apt-get upgrade -y",
  require => Exec["apt-get update"]
}

### Install development packages
$development_packages = [
  "zsh",
  "wget",
  "vim"
]

package { $development_packages:
  ensure => latest,
  require => Exec["apt-get upgrade"]
}

### Install setting for legacy postgresql
file { "/etc/apt/sources.list.d/pgdg.list":
  content => template("pgdg.list"),
  mode => "0644"
}

exec { "postgres repos key":
  command => "wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -",
  require => [Package["wget"], Exec["apt-get update"]]
}

### Install dependency packages
$dependency_packages = [
  "ntp",
  "ruby1.8",
  "rubygems1.8",
  "postgresql-8.4",
  "apache2",
  "libapache2-mod-passenger",
  "git"
]

package { $dependency_packages:
  ensure => latest,
  require => Exec["apt-get upgrade"]
}

### Switch default ruby(1.9 => 1.8), gem(1.9 => 1.8)
exec { "switch alternative ruby":
  command => "ln -fs /usr/bin/ruby1.8 /etc/alternatives/ruby",
  require => Package["ruby1.8"]
}

exec { "switch alternative gem":
  command => "ln -fs /usr/bin/gem1.8 /etc/alternatives/gem",
  require => Package["rubygems1.8"]
}

### Install dependency RubyGem
package { "bundler":
  provider => "gem",
  require => Package[$dependency_packages]
}

### Settings for KaraHiMBO

### user settings
$karahi_user = "karahi"
$karahi_dir  = "/opt/KaraHiMBO"

exec { "git clone KaraHiMBO":
  command => "git clone git://github.com/gongo/KaraHiMBO.git ${karahi_dir}",
  creates => $karahi_dir,
  require => Package[$dependency_packages]
}

exec { "bundle-install":
  cwd => $karahi_dir,
  command => "bundle install --without development test",
  require => [Package["bundler"], Exec["git clone KaraHiMBO"]]
}

file { "${karahi_dir}/config/database.yml":
     content => template("database.yml"),
     mode => "0644",
     require => Exec["git clone KaraHiMBO"]
}

### Settings for PostgreSQL
file { "/etc/postgresql/8.4/main/pg_hba.conf":
  ensure => present,
  content => template("pg_hba.conf"),
  owner => "postgres",
  group => "postgres",
  mode => "0644",
  require => Package[$dependency_packages],
  notify => Service["postgresql"],
  backup => ".puppet-bak"
}

service { "postgresql":
  ensure => running,
  enable => true
}

### Karahi User(postgres and application's owner)
user { $karahi_user:
  ensure => "present",
  shell => "/bin/bash",
  home => "/home/karahi",
  managehome => true,
  password =>"$6$37.Sz8GZ$3bP2wfvjR.5S96/a9ewLSCBIOC.HkjDiLoR71KGC/kVD9g.zMx3SdkwdkWStp97cU4T5SdDztdpFs.ERYZ4hc1"
}

file { $karahi_dir:
  ensure => directory,
  owner => $karahi_user,
  group => $karahi_user,
  recurse => true,
  require => [User[$karahi_user], Exec["git clone KaraHiMBO"]]
}

exec { "postgres-createuser":
  command => "createuser -d -S -R ${karahi_user}",
  user => "postgres",
  unless => 'psql -qAt postgres -c "\du" | grep -q "karahi|Create DB"',
  require => Package[$dependency_packages]
}

### Apache settings
file { '/etc/apache2/sites-available/apache-mbo':
  ensure  => present,
  content => template('apache-mbo'),
  mode    => '0644',
  require => Package[$dependency_packages],
  notify  => Service['postgresql'],
  backup  => '.puppet-bak'
}

exec { 'enable apache mbo site configuration':
  command => 'a2ensite apache-mbo',
  unless  => 'readlink -e /etc/apache2/sites-enabled/apache-mbo',
  notify  => Service['apache2'],
  require => [Package['apache2'],
  File['/etc/apache2/sites-available/apache-mbo']]
}

exec { 'disable apache default site configuration':
  command => 'a2dissite 000-default',
  onlyif  => 'readlink -e /etc/apache2/sites-enabled/000-default',
  notify  => Service['apache2'],
  require => Package['apache2']
}

service { 'apache2':
  ensure => running,
  enable => true
}
