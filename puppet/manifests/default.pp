Exec {
  path => $facts['path'],
}
package { ['tree']:
  ensure => latest
}

node /mysql.*/ {
  $override_options = {
    'mysqld' => {
      'bind_address' => '10.10.10.2',
    }
  }
  class { '::mysql::server':
    restart                 => true,
    remove_default_accounts => true,
    override_options        => $override_options,
  }
  -> mysql::db { 'employees':
    user     => 'employees',
    password => 'employees',
    host     => '%',
    grant    => ['SELECT', 'UPDATE'],
    charset  => 'latin1',
    collate  => 'latin1_swedish_ci',
  }
  ~> exec { 'mysql employees < employees.sql':
    cwd         => '/app/data',
    refreshonly => true,
  }
}

node /backend.*/ {
  $service_template = @(EOT)
    [Unit]
    Description=Simple App
    After=network.target

    [Service]
    User=app
    Restart=on-failure
    WorkingDirectory=/app
    ExecStart=/usr/local/bin/bundle exec rackup --server puma --host 0.0.0.0 --port 3000

    [Install]
    WantedBy=multi-user.target
    | EOT

  include apt
  apt::ppa { 'ppa:brightbox/ruby-ng': }
  -> package { ['ruby2.5', 'ruby2.5-dev', 'build-essential',
      'libmysqlclient-dev']: # need these for `bundle update`
    ensure => present,
  }
  -> package { 'bundler':
    ensure   => present,
    provider => 'gem',
  }
  -> user { 'app':
    ensure => present,
    home   => '/app',
    system => true,
  }
  -> exec { 'bundle update --retry 3':
    cwd    => '/app',
    unless => 'bundle update --local',
    tries  => 3,
  }
  -> file { '/etc/systemd/system/app.service': # let systemd handle the app workers
    content => inline_epp($service_template),
  }
  ~> exec {'systemctl daemon-reload': # make systemd aware of app.service
    refreshonly => true,
  }
  ~> service { 'app':
    ensure => running,
    enable => true,
  }
}

node /frontend.*/ {
  class { 'nginx':
    confd_purge  => true, # purge /etc/nginx/conf.d/*
    server_purge => true, # purge /etc/nginx/{sites-available,sites-enabled,streams-enabled}
  }
  nginx::resource::upstream { 'backend':
    members => [
      'backend1:3000',
      'backend2:3000',
    ],
  }
  nginx::resource::server { 'default':
    proxy => 'http://backend',
  }
}
