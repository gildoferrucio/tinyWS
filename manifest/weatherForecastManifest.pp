service { "weatherForecast":
  ensure  => running,
  start   => "./grabWeatherForecast.sh start",
  stop    => "./grabWeatherForecast.sh stop",
  status  => "./grabWeatherForecast.sh status",
}
