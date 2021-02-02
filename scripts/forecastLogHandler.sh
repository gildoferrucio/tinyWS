#!/bin/bash

#################################AUX FUNCTIONS##################################
function compressTARGZ(){
  #Reference: https://www.peterdavehello.org/2015/02/use-multi-threads-to-compress-files-when-taring-something/
	#Reference: https://www.tecmint.com/progress-monitor-check-progress-of-linux-commands/
  local file
  local isMultithreaded
	local destinyPath
	local outputFile
  file="$1"
  shift
  doesGivenArgumentExists "\-\-multithread" "$@" && isMultithreaded=true || isMultithreaded=false
	destinyPath=$(getGivenArgumentValue "\-\-destinyPath" "$@")

	#Treats additional arguments related to destinyPath
	if ! isVariableBlank "$destinyPath"; then
    ! doesDirectoryExists "$destinyPath" && mkdir -p "$destinyPath"
		if doesFileExists "$file"; then
			outputFile="$destinyPath"/$(getFilename "$file").tar.gz
		elif doesDirectoryExists "$file"; then
			outputFile="$destinyPath"/$(getDirectoryName "$file").tar.gz
		fi
	else
		if doesFileExists "$file" || doesDirectoryExists "$file"; then
			outputFile="$file".tar.gz
		fi
	fi

  if doesFileExists "$file" || doesDirectoryExists "$file"; then
    if $isMultithreaded && isBinaryAvailable "pigz"; then
			if isBinaryAvailable "progress"; then
      	tar -I pigz -cf "$outputFile" "$file" | progress -m $!
			else
				tar -I pigz -cf "$outputFile" "$file"
			fi
    else
			if isBinaryAvailable "progress"; then
	      tar -zcvf "$outputFile" "$file" | progress -m $!
			else
				tar -zcvf "$outputFile" "$file"
			fi
    fi
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

function doesFileExists(){
	local file
	file="$1"

	[ -f "$file" ] && return 0 || return 1
}

function doesDirectoryExists(){
	local directory
	directory="$1"

	[ -d "$directory" ] && return 0 || return 1
}

function getDirectoryName(){
	#Reference: https://stackoverflow.com/questions/1371261/get-current-directory-name-without-full-path-in-a-bash-script/50634869
	local directoryPath
	local name
	directoryPath="$1"

	#dirname="/path/to/somewhere//"
	name="${directoryPath%"${directoryPath##*[!/]}"}" # extglob-free multi-trailing-/ trim
	name="${name##*/}"
	echo "$name"
}

function isVariableBlank(){
  local variable
  variable="$1"

  [ -z "$variable" ] && return 0 || return 1
}

function isBinaryAvailable(){
  local binaryName
  binaryName="$1"

  #which "$binaryName" &> /dev/null
  #"command -v" is a bash builtin, thus is preferable over "which"
  command -v "$binaryName" &> /dev/null
  return "$?"
}

function getFilename(){
	local file
	local filename
	file="$1"

	if doesFileExists "$file"; then
		filename=$(basename "$file")
		echo "$filename"
	fi
}

function changeFilePermissions(){
	local file
	local permission
	file="$1"
	permission="$2"

	if doesFileExists "$file"; then
		chmod "$permission" "$file"
	elif doesDirectoryExists "$file"; then
		chmod -R "$permission" "$file"
	fi
}

function getCurrentDate(){
	local currentDate

	currentDate=$(date +%Y%m%d)
	echo "$currentDate"
}

function removeGivenElement(){
	local elementToBeRemoved
	local array
	elementToBeRemoved="$1"
	shift
	array=("$@")

	if containsGivenElement "$elementToBeRemoved" "${array[@]}"; then
		#removes $elementToBeRemoved from array
		array=($(echo "${array[@]}" | sed -s "s/$elementToBeRemoved//g"))
	fi

	echo "${array[@]}"
}

function containsGivenElement(){
  local wantedElement
  local array
  wantedElement="$1"
  shift
  array=("$@")
  contains=1

  #(echo "${array[@]}" | grep -q "$wantedElement") && return 0 || return 1
  for element in "${array[@]}"; do
    if [ "$element" == "$wantedElement" ]; then
	    contains=0
	    break
    fi
  done

  return $contains
}

###################################FUNCTIONS####################################
function getPreviousDateBasedOnDeltaDays(){
  local deltaDays
  deltaDays="$1"

  date --date="$(getCurrentDate) - $deltaDays day" +%Y%m%d
}

function compressYesterdayFiles(){
  local yesterday
  yesterday=$(getPreviousDateBasedOnDeltaDays 1)

  #Creates temp yesterday directory
  mkdir -p "$INPUT_PATH"/"$yesterday"
  #Moves yesterday forecasts to yesterday directory
  mv -vf "$INPUT_PATH"/forecast_*"$yesterday"* "$INPUT_PATH"/"$yesterday"
  #Compress the files
  compressTARGZ "$INPUT_PATH"/"$yesterday" --destinyPath="$COMPRESSED_FILES_BASE_PATH"
  #Removes yesterday directory (according to shellcheck, when using "rm" it's safer to use "$var:?" to make sure that $var will never expand only to "/", the root directory and wipe the whole system)
  rm -rf "$INPUT_PATH"/"$yesterday"
  changeFilePermissions "$COMPRESSED_FILES_BASE_PATH"/*.tar.gz "400"
}

function removeOldBackups(){
  local directoriesToRemove
  local dayToMaintain
  local directoryToMaintain
  directoriesToRemove=($(ls /backup))

  for n in $(seq 0 9); do
    dayToMaintain=$(date --date="$(getPreviousDateBasedOnDeltaDays $n)" +%m-%d)
    directoryToMaintain=$(ls /backup/ | grep "^$dayToMaintain-"* | head -n 1)
    directoriesToRemove=($(removeGivenElement "$directoryToMaintain" "${directoriesToRemove[@]}"))
  done

  for item in "${directoriesToRemove[@]}"; do
    rm -rf /backup/"$item"
  done
}

function printHelp(){
  echo "This script manages the log files generated by weather forecast service."
  echo "You got to inform pass the path where the logs are stored to the parameter \"inputPath\" as follows:"
  echo "  ./forecastLogHandler.sh --inputPath=<path>"
}
###################################CONSTANTS####################################
COMPRESSED_FILES_BASE_PATH="/backup/$(date +%m-%d-%H-%M)/service.backup"

######################################MAIN######################################
INPUT_PATH=$(getGivenArgumentValue "\-\-inputPath" "$@")

if ! isVariableBlank "$INPUT_PATH"; then
  compressYesterdayFiles
  removeOldBackups
else
  printHelp
fi
