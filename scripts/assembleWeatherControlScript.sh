#!/bin/bash

#################################AUX FUNCTIONS##################################
function printFileLineRange(){
	local textFile
	local rangeBegin
	local rangeEnd
	textFile="$1"
	rangeBegin="$2"
	rangeEnd="$3"

	if isTextFile "$textFile"; then
		sed "$rangeBegin","$rangeEnd"'!d' "$textFile"
	fi
}

function isTextFile(){
	local file
	file="$1"

	getFileMimeType "$file" | grep -q -i "^text"
}

function getFileMimeType(){
	#Reference: https://stackoverflow.com/questions/2227182/how-can-i-find-out-a-files-mime-type-content-type
	local file
	file="$1"

	if doesFileExists "$file"; then
		file -b --mime-type "$file"
	fi
}

function doesFileExists(){
	local file
	file="$1"

	[ -f "$file" ] && return 0 || return 1
}
###################################FUNCTIONS####################################
function assembleScript(){
  local anchorLine
  local baseScriptLastLine
  anchorLine=$(grep -n "$ANCHOR_STRING" "$BASE_SCRIPT" | cut -d: -f1)
  baseScriptLastLine=$(wc -l "$BASE_SCRIPT" | awk '{print $1}')
	
  printFileLineRange "$BASE_SCRIPT" 1 $(($anchorLine - 1)) > "$ASSEMBLED_SCRIPT"
  cat "$SCRIPT_TO_EMBED" >> "$ASSEMBLED_SCRIPT"
  printFileLineRange "$BASE_SCRIPT" $(($anchorLine + 1)) "$baseScriptLastLine" >> "$ASSEMBLED_SCRIPT"
}

###################################CONSTANTS####################################
BASE_SCRIPT="./weatherForecastControl.sh"
ANCHOR_STRING="HERE GOES THE SCRIPT"
SCRIPT_TO_EMBED="./grabWeatherForecast.sh"
ASSEMBLED_SCRIPT="./weatherForecastControlAssembled.sh"

######################################MAIN######################################
if doesFileExists "$BASE_SCRIPT" && doesFileExists "$SCRIPT_TO_EMBED"; then
  assembleScript
fi
