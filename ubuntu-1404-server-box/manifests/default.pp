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
  "ntp",
  "zsh",
  "vim",
  "git",
  "ruby",
  "emacs"
]

package { $development_packages:
  ensure => latest,
  require => Exec["apt-get upgrade"]
}

### Install dependency RubyGem
#package { "bundler":
#  provider => "gem",
#  require => Package[$development_packages]
#}

### Fetch rbenv environment (on vagrant user.)
$user = "vagrant"
$home = "/home/${user}"
$rbenv_repo = "https://github.com/sstephenson"

file { "${home}/.bash_profile":
  ensure => present,
  content => template('bash_profile')
}

exec { "fetch-rbenv-repos":
  user => $user,
  cwd => $home,
  command => "git clone ${rbenv_repo}/rbenv.git ${home}/.rbenv",
  unless => "[ -d ${home}/.rbenv ]",
  require => Package[$development_packages]
}

### Fetch ruby-build repos(rbenv's plugin).
exec { "fetch-ruby-build":
  user => $user,
  cwd => $home,
  command => "git clone ${rbenv_repo}/ruby-build.git ${home}/.rbenv/plugins/ruby-build",
  unless => "[ -d ${home}/.rbenv/plugins/ruby-build ]",
  require => Exec["fetch-rbenv-repos"]
}

### rehash path after making .bash_profile and fetching ruby-build
# exec { "rehash-path":
#   user => $user,
#   cwd => $home,
#   subscribe => File["${home}/.bash_profile"],
#   command => "bash -c 'source ${home}/.bash_profile'",
#   require => Exec["fetch-ruby-build"]
# }

### Install ruby environment from rbenv
# exec { "install-ruby":
#   user => $user,
#   cwd => $home,
# #  path => '${path}:${home}/.rbenv/bin:${home}/.rbenv/shim',
# #  command => "su -l ${user} -c \"bash --login -c 'rbenv install -v 2.1.1'\"",
#   command => "rbenv install -v 2.1.1",
# #  require => Exec["fetch-ruby-build", "rehash-path"]
#   require => Exec["fetch-ruby-build"]
# }
