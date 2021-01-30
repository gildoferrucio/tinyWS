#!/bin/bash

#################################AUX FUNCTIONS##################################
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


######################################MAIN######################################
OUTPUT=$(getGivenArgumentValue "\-\-output" "$@")
OUTPUT=$(removeDuplicatedSlashesOnDirectoryPath "$OUTPUT")
CITY=$(getGivenArgumentValue "\-\-city" "$@")

! isVariableBlank "$OUTPUT"  && ! isVariableBlank "$CITY" && getWeatherGraphFromCity "$CITY" > "$OUTPUT"
