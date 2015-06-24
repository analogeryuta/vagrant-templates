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
  "rubygems"
]

package { $development_packages:
  ensure => latest,
  require => Exec["apt-get upgrade"]
}

### Install dependency RubyGem
package { "bundler":
  provider => "gem",
  require => Package[$development_packages]
}
