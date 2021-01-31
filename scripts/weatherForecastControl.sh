#!/bin/bash

#################################AUX FUNCTIONS##################################
function isProcessRunning(){
	local processName
	local processInfo
	processName="$1"

	if ! isVariableBlank "$processName"; then
		#Reference of "pidof -x": https://www.linuxquestions.org/questions/programming-9/pidof-x-python-script-not-always-working-4175492559/
		processInfo=$(getProcessPIDs "$processName")
		! isVariableBlank  "$processInfo" && return 0 || return 1
	fi
}

function getProcessPIDs(){
	#References: https://www.geeksforgeeks.org/pidof-command-in-linux-with-examples/
	#            https://www.cyberciti.biz/faq/linux-pidof-command-examples-find-pid-of-program/
	local processName
	local processPIDs
	processName="$1"

	if ! isVariableBlank  "$processName"; then
		processPIDs=($(pidof -x "$processName"))
		#[ $(arrayLength "${processPIDs[@]}") -eq 0 ] && processPIDs=$(getProcessInfo "$processName" | awk '{print $2}')
	fi

	echo "${processPIDs[@]}"
}

function killProcessByPID(){
	local processPIDs
	processPIDs=("$@")

	[ $(arrayLength "${processPIDs[@]}") -ne 0 ] && kill -9 "${processPIDs[@]}"
}

function isVariableBlank(){
  local variable
  variable="$1"

  [ -z "$variable" ] && return 0 || return 1
}

function arrayLength(){
	local array
	array=("$@")
	echo ${#array[@]}
}

function doesDirectoryExists(){
	local directory
	directory="$1"

	[ -d "$directory" ] && return 0 || return 1
}
###################################FUNCTIONS####################################
function generateWeatherForecastScriptFile(){
  ! doesDirectoryExists "$SCRIPT_PATH" && mkdir -p "$SCRIPT_PATH"

  cat << 'EOF' > "$SCRIPT_PATH"/"$SCRIPT_NAME"
HERE GOES THE SCRIPT
EOF
}

function printHelp(){
  echo "This script controls the grabWeatherForecast.sh script to use it as a service. The use cases are:"
  echo "  1. Start the weather forecast script."
  echo "  =>To start the forecast script as a service you must issue the command as follows."
  echo "    \$ ./weatherForecastControl.sh start"
  echo ""
  echo "  2. Stop the weather forecast script."
  echo "  =>To stop the forecast script as a service you must issue the command as follows."
  echo "    \$ ./weatherForecastControl.sh stop"
  echo ""
  echo "  3. Return the status of the weather forecast script."
  echo "  =>To return the status of the forecast script as a service you must issue the command as follows."
  echo "    \$ ./weatherForecastControl.sh status"
  echo "    "
  echo "    The expected return is 0 (zero) if the script is running, and non-zero otherwise."
  echo ""
}
###################################CONSTANTS####################################
SCRIPT_PATH="/tmp"
SCRIPT_NAME="grabWeatherForecast.sh"
OUTPUT="/tmp"
CITY="João Pessoa"

######################################MAIN######################################
ACTION="$1"

case "$ACTION" in
  start)
    if ! isProcessRunning "$SCRIPT_NAME"; then
      generateWeatherForecastScriptFile
      nohup "$SCRIPT_PATH"/"$SCRIPT_NAME" --output="$OUTPUT" --city="$CITY" --periodic &
    fi
    ;;
  stop)
    if isProcessRunning "$SCRIPT_NAME"; then
      killProcessByPID $(getProcessPIDs "$SCRIPT_NAME")
    fi
    ;;
  status)
    return $(isProcessRunning "$SCRIPT_NAME")
    ;;
  *)
    printHelp
    ;;
esac
