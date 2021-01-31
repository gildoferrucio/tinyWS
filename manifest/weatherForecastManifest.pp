node "default" {
  file { "/usr/local/bin/weatherForecastControlAssembled.sh":
    #TODO: check for appropriate source parameter filling
    #      check: https://stackoverflow.com/questions/35429068/how-to-install-and-run-a-script-in-puppet
    source  => "puppet://$servername/",
    path    => "/usr/local/bin/weatherForecastControlAssembled.sh",
    mode    => "0744",
    owner   => "root"
    group   => "root"
    replace => true,
  }

  file { "/usr/local/bin/forecastLogHandler.sh":
    #TODO: check for appropriate source parameter filling
    #      check: https://stackoverflow.com/questions/35429068/how-to-install-and-run-a-script-in-puppet
    source  => ,
    path    => "/usr/local/bin/forecastLogHandler.sh",
    mode    => "0744",
    owner   => "root",
    group   => "root",
    replace => true,
  }

  service { "weatherForecastService":
    ensure  => running,
    start   => "/usr/local/bin/weatherForecastControlAssembled.sh start",
    stop    => "/usr/local/bin/weatherForecastControlAssembled stop",
    status  => "/usr/local/bin/weatherForecastControlAssembled status",
  }

  cron { "forecastLogHandlerCron":
    ensure  => present,
    command => "/usr/local/bin/forecastLogHandler.sh --inputPath=/opt/weatherForecast",
    user    => "root",
    hour    => 2,
    minute  => 0,
  }
}
