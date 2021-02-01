#!/bin/bash

#################################AUX FUNCTIONS##################################
function doesGivenArgumentExists(){
  local argumentKey
  local argumentList
  argumentKey="$1"
  shift
  argumentList=("$@")

  if ! isVariableBlank "$argumentKey"; then
    (echo "${argumentList[@]}" | sed -s 's/[[:blank:]]/\n/g' | grep -q "$argumentKey") && return 0 || return 1
  fi
}

# Usage: gatewayAddress=$(getGivenArgumentValue "\-\-gateway" "$@")
function getGivenArgumentValue(){
  local argumentKey
  local argumentList
  local argumentValue
  argumentKey="$1"
  shift
  argumentList=("$@")

  if ! isVariableBlank "$argumentKey"; then
    #argumentValue=$(echo "${argumentList[@]}" | sed -s 's/[[:blank:]]/\n/g' | grep "$argumentKey" | sed -s "s/=/ /" | awk '{print $2}')
		# Allows to get all arguments, breaking all "--" preceded arguments into lines, then selecting the right one and finally retrive only the argument value
    argumentValue=$(echo "${argumentList[@]}" | sed -s "s|--|\n--|g" | grep "$argumentKey" | sed -s "s/$argumentKey=//")
    argumentValue=$(echo "$argumentValue" | sed -s "s|^[[:blank:]]*||g" | sed -s "s|[[:blank:]]*$||g")
  fi

  echo "$argumentValue"
}

function removeDuplicatedSlashesOnDirectoryPath(){
	#Reference: https://stackoverflow.com/questions/1371261/get-current-directory-name-without-full-path-in-a-bash-script/50634869
	local directoryPath
  local name

	directoryPath="$1"
	#dirname="/path/to/somewhere//"
	name="${directoryPath%"${directoryPath##*[!/]}"}" # extglob-free multi-trailing-/ trim
	echo "$name"
}

function isVariableBlank(){
  local variable
  variable="$1"

  [ -z "$variable" ] && return 0 || return 1
}

function getCurrentTimestamp(){
	local currentDate

	currentDate=$(date +%Y%m%d_%H%M%S)
	echo "$currentDate"
}

function doesDirectoryExists(){
	local directory
	directory="$1"

	[ -d "$directory" ] && return 0 || return 1
}
###################################FUNCTIONS####################################
function getWeatherGraphFromCity(){
	#References: https://linuxconfig.org/get-your-weather-forecast-from-the-linux-cli
	#            https://ostechnix.com/check-weather-details-command-line-linux/
  local cityName
	# If the cityName has spaces on it, replace by "+" plus character
	cityName=$(echo "$@" | sed -s "s/ /+/g")

  curl http://v2.wttr.in/"$cityName"
	[ "$?" -ne 0 ] && curl http://wttr.in/"$cityName"
}

function printHelp(){
  echo "This script grabs the forecast for the specified city and prints it in the specified output path. The use cases are:"
  echo "  1. Run it a single time."
  echo "  =>To run it just one time, you must issue the command as follows."
  echo "    \$ ./grabWeatherForecast.sh --output=<path> --city=<cityName>"
  echo "  "
  echo "    Example #1:"
  echo "      \$ ./grabWeatherForecast.sh --output=/opt --city=Recife"
  echo "    Example #2:"
  echo "      \$ ./grabWeatherForecast.sh --output=/opt --city=João Pessoa"
  echo ""
  echo "  2. Run it indefinetly, just as a service would. Like so, it will gather a new forecast at 1 minute period."
  echo "  =>To run it indefinetly you need to add the \"--periodic\" parameter."
  echo "    \$ ./grabWeatherForecast.sh --output=<path> --city=<cityName> --periodic"
  echo "  "
  echo "    Example #1:"
  echo "      \$ ./grabWeatherForecast.sh --output=/opt --city=Recife --periodic"
  echo "    Example #2:"
  echo "      \$ ./grabWeatherForecast.sh --output=/opt --city=João Pessoa --periodic"
}
###################################CONSTANTS####################################
PERIOD_SECS=60

######################################MAIN######################################
OUTPUT=$(getGivenArgumentValue "\-\-output" "$@")
OUTPUT=$(removeDuplicatedSlashesOnDirectoryPath "$OUTPUT")
CITY=$(getGivenArgumentValue "\-\-city" "$@")
doesGivenArgumentExists "\-\-periodic" "$@" && IS_PERIODIC=true || IS_PERIODIC=false

if ! isVariableBlank "$OUTPUT"  && ! isVariableBlank "$CITY"; then
  ! doesDirectoryExists "$OUTPUT" && mkdir -p "$OUTPUT"

  if $IS_PERIODIC; then
    while true; do
      FILENAME=forecast_$(echo "$CITY" | sed -s "s/ //g")_$(hostname)_$(getCurrentTimestamp)
      getWeatherGraphFromCity "$CITY" > "$OUTPUT"/"$FILENAME"
      sleep $PERIOD_SECS
    done
  else
    FILENAME=forecast_$(echo "$CITY" | sed -s "s/ //g")_$(hostname)_$(getCurrentTimestamp)
    getWeatherGraphFromCity "$CITY" > "$OUTPUT"/"$FILENAME"
  fi
else
  printHelp
fi
