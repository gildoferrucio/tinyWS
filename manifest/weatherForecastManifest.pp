node default {
  file { "weatherForecastControlAssembled.sh":
    # I've choose to use a new mount point and configure it in /etc/puppetlabs/puppet/fileserver.conf, as described in https://puppet.com/docs/puppet/7.3/file_serving.html#creating-a-new-mount-point-in-fileserver.conf
    source  => "puppet:///tinyWS/weatherForecastControlAssembled.sh",
    path    => "/usr/local/bin/weatherForecastControlAssembled.sh",
    mode    => "0744",
    owner   => "root",
    group   => "root",
    replace => true,
    #TODO: check if notify is working as it should
    notify  => Service["weatherForecastService"],
  }
  file { "forecastLogHandler.sh":
    # I've choose to use a new mount point and configure it in /etc/puppetlabs/puppet/fileserver.conf, as described in https://puppet.com/docs/puppet/7.3/file_serving.html#creating-a-new-mount-point-in-fileserver.conf
    source  => "puppet:///tinyWS/forecastLogHandler.sh",
    path    => "/usr/local/bin/forecastLogHandler.sh",
    mode    => "0744",
    owner   => "root",
    group   => "root",
    replace => true,
  }
  service { "weatherForecastService":
    require => File["weatherForecastControlAssembled.sh"],
    ensure  => running,
    start   => "/usr/local/bin/weatherForecastControlAssembled.sh start",
    stop    => "/usr/local/bin/weatherForecastControlAssembled stop",
    status  => "/usr/local/bin/weatherForecastControlAssembled status",
  }
  cron { "forecastLogHandlerCron":
    require => File["forecastLogHandler.sh"],
    ensure  => present,
    command => "/usr/local/bin/forecastLogHandler.sh --inputPath=/opt/weatherForecast",
    user    => "root",
    hour    => 2,
    minute  => 0,
  }
}
