# Class: puppet::agent
#
# This class installs and configures the puppet agent
#
# Parameters:
#
# Actions:
# 
# Requires:
#
# Sample Usage:
#
class puppet::agent(
  $puppet_defaults,
  $puppet_agent_service,
  $puppet_agent_name,
  $puppet_conf,
  $puppet_server,
  $package_provider = undef,
  $version
) inherits puppet::params {
  
  if $kernel == "Linux" {
    file { $puppet_defaults:
      mode   => '0644',
      owner  => 'root',
      group  => 'root',
      source => "puppet:///modules/puppet/${puppet_defaults}",
    }
  }

  package { 'puppet':
    name     => $puppet_agent_name,
    ensure   => $version,
    provider => $package_provider,
  }

  if $package_provider == 'gem' {
    exec { 'puppet_agent_start':
      command   => '/usr/bin/nohup puppet agent &',
      refresh   => '/usr/bin/pkill puppet && /usr/bin/nohup puppet agent &',
      unless    => "/bin/ps -ef | grep -v grep | /bin/grep 'puppet agent'",
      require   => File['/etc/puppet/puppet.conf'],
      subscribe => Package[$puppet_agent_package],
    }
  } else {
    service { $puppet_agent_service:
      ensure    => running,
      enable    => true,
      hasstatus => true,
      require   => File['/etc/puppet/puppet.conf'],
      subscribe => Package[$puppet_agent_package],
      #before    => Service['httpd'];
    }
  }

  concat::fragment { 'puppet.conf-common':
    order   => '00',
    target  => $puppet_conf,
    content => template("puppet/puppet.conf-common.erb"),
  }

  concat { $puppet_conf:
    mode    => '0644',
    require => Package['puppet'],
    notify  => Service['puppet_agent'],
  }

}
