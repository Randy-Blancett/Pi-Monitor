#!/bin/bash
#FILE
# This is the entry point for the monitoring of the orange pi dameon
#VERSION 1.1.0
#VERSIONS
#V 1.1.0
# Fix ShellCheck Issues
#
#V 1.0.0
# Initial Split of code into more manageable chunks

BL_PATH="$( dirname "$0" )"
BL_PATH=$(readlink -e "$BL_PATH")
LIB_PATH="$BL_PATH/lib"

#VARIABLE
#PRIVATE
# This is the minimum time between cycles.
CYCLE_TIME_MIN=3


#METHOD
#PRIVATE
# This method is used to add any required bash libraries
function loadRequirements()
{
	# Adds ability to log data in color
	source "$LIB_PATH/colorLogging.sh"
	# Adds ability to output data in a zabbix file
	source "$LIB_PATH/outputZabbixFile.sh"
	# Adds ability monitor Gpu Temp
	source "$LIB_PATH/checkGpuTemp.sh"
	# Adds ability monitor Cpu Temp
	source "$LIB_PATH/checkCpuTemp.sh"
	# Adds ability monitor Cpu Freq
	source "$LIB_PATH/checkCpuFreq.sh"
	# Adds ability monitor Cpu Usage
	source "$LIB_PATH/checkCpuUsage.sh"
}

#METHOD
#PRIVATE
# this will parse command line options for this script
#
#PARAMETERS
# $1 | option | The option to parse
# $2 | data | The Data passed with the option | optional
function optMonitorDameon()
{
	case $1 in 
		-c | --minCycle)
			CYCLE_TIME_MIN=$2
			;;
	esac    			
}

#METHOD
#PUBLIC
# Check if a given directory exists, if not it will create it
#
#PARAMETERS
# $1 | Directory | Directory to Check
function ensureDir
{
	log "Ensure that Directory $1 exists" "$INFO" "$TEXT_GREEN"
	if [ ! -d "$1" ]; then
		log "$1 does not exist atempting to create." "$DEBUG" "$TEXT_YELLOW"
  		mkdir -p "$1"
	fi
}

##############################################################
# Script Setup                                               #
############################################################## 
loadRequirements

setDescription "This is the entry point to a dameon that will write metrics to a Zabbix File Format."
setUsage "./monitorDameon.sh -o <outputDir>"

addVar2Dump "BL_PATH"
addVar2Dump "LIB_PATH"
addVar2Dump "CYCLE_TIME_MIN"

addCommandLineArg "c" "minCycle" true "The minimum sleep cycle betwee runs Default: $CYCLE_TIME_MIN"
addCommandLineParser "optMonitorDameon"

parseCmdLine "$@"
varDump "$DEBUG"

ensureDir "$OUTPUT_DIR"

log "Starting Monitor Dameon..." "$STANDARD" "$TEXT_GREEN"

while true
do
  DATE=$(date +"%d%B%Y_%H %s ")
  readarray -t -d " " DATE_ARRAY <<<"$DATE"
  OUTPUT_FILE=$OUTPUT_DIR/${DATE_ARRAY[0]}
  DATE=${DATE_ARRAY[1]}  
  checkCpuTemp "$DATE"
  checkGpuTemp "$DATE"
  checkCpuFreq "$DATE"
  checkCpuUsage "$DATE"
  writeZabbixCache
  sleep "$CYCLE_TIME_MIN"
done
