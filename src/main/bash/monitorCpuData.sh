#!/bin/bash
#FILE
# This will write CPU stats to a file that Zabbix can process
#VERSION 0.0.2
#VERSIONS
#V 0.0.3
# Split into seperate files to make it easier to maintain
#V 0.0.2
#RELEASE 04AUG2021
# Logged the Cpu Usage
#V 0.0.1
# Logged the Cpu Temp
# Logged the Gpu Temp
# Logged the Cpu Frequency

BL_PATH="$( dirname $0 )"
BL_PATH=$(readlink -e $BL_PATH)
LIB_PATH="$BL_PATH/lib"

KEY_CPU_TEMP="temp.cpu"
KEY_GPU_TEMP="temp.gpu"
CYCLE_TIME_MIN=3
LAST_CHECK=0;

CPUS="0 1 2 3"

OUTPUT_DIR="/tmp/zabbix"

CPU_TEMP_FILE="/sys/devices/virtual/thermal/thermal_zone0/temp"
GPU_TEMP_FILE="/sys/devices/virtual/thermal/thermal_zone1/temp"
CPU_STATUS="/proc/stat"

OLD_CPU_READINGS=()

BASE_CPU_FREQ_DIR="/sys/devices/system/cpu/"

function loadRequirements()
{
	source $LIB_PATH/colorLogging.sh
}

#METHOD
#PRIVATE
# this will parse command line options for this script
#
#PARAMETERS
# $1 | option | The option to parse
# $2 | data | The Data passed with the option | optional
function optParserMonitorCpu()
{
	case $1 in 
		-o | --outputDir)
			OUTPUT_DIR=$2
			;;
	esac    			
}

#METHOD
#PUBLIC
# Check CPU Frequencies
#
#PARAMETERS
# $1 | Date | Date in seconds since epoc
function checkCpuFreq()
{
	log "Checking CPU Frequencies" $TRACE
	
	for CPU in ${CPUS}
	do
		log "Process $CPU" $TRACE	
		local FREQ_FILE="${BASE_CPU_FREQ_DIR}/cpu${CPU}/cpufreq/cpuinfo_cur_freq"
		if [ ! -r ${FREQ_FILE} ]
		then
			log "You can not read the frequency file so skiping it" $INFO
			continue
		fi	
		local FREQ=$(cat "$FREQ_FILE")		
  		sendLine2Cache $1 "freq.cpu${CPU}" $FREQ 
	done
}

#METHOD
#PUBLIC
# Check Temp of CPU
#
#PARAMETERS
# $1 | Date | Date in seconds since epoc
function checkCpuTemp()
{
	log "Checking CPU Temp" $TRACE
	log "Reading from ${CPU_TEMP_FILE}" $DEBUG
	if [ ! -r ${CPU_TEMP_FILE} ]
	then
		log "You can not read the temp file so skiping it" $INFO
		return
	fi
	local TEMP=$(cat ${CPU_TEMP_FILE})
  	local TEMP=$(printf '%.3f\n' $(echo "${TEMP}/1000" | bc -l))
  	sendLine2Cache $1 $KEY_CPU_TEMP $TEMP 
}

#METHOD
#PUBLIC
# Check Temp of GPU
#
#PARAMETERS
# $1 | Date | Date in seconds since epoc
function checkGpuTemp()
{
	log "Checking GPU Temp" $TRACE
	log "Reading from ${GPU_TEMP_FILE}" $DEBUG
	if [ ! -r ${GPU_TEMP_FILE} ]
	then
		log "You can not read the temp file so skiping it" $INFO
		return
	fi
	local TEMP=$(cat ${GPU_TEMP_FILE})
  	local TEMP=$(printf '%.3f\n' $(echo "${TEMP}/1000" | bc -l))
  	sendLine2Cache $1 $KEY_GPU_TEMP $TEMP 
}

#METHOD
#PUBLIC
# Process usage stats for a single cpu line
# Data Format:
#1 	user 	Time spent with normal processing in user mode.
#2 	nice 	Time spent with niced processes in user mode.
#3 	system 	Time spent running in kernel mode.
#4 	idle 	Time spent in vacations twiddling thumbs.
#5 	iowait 	Time spent waiting for I/O to completed. This is considered idle time too. 	since 2.5.41
#6 	irq 	Time spent serving hardware interrupts. See the description of the intr line for more details. 	since 2.6.0
#7 	softirq 	Time spent serving software interrupts. 	since 2.6.0
#8 	steal 	Time stolen by other operating systems running in a virtual environment. 	since 2.6.11
#9 	guest 	Time spent for running a virtual CPU or guest OS under the control of the kernel. 	since 2.6.24
#
#PARAMETERS
# $1 | Date | Date in seconds since epoc
# $2 | Old Data | The data for one cpu the prior run
# $3 | New Data | The data for one cpu this run
function processSingleCpuData()
{
	log "Processing One cpu [$2] [$3]" $TRACE
	if [ -z "$2" ]
	then
		log "There is no old data so we can not process." $INFO
		return;
	fi
	local OLD_DATA=($2)
	local NEW_DATA=($3)
	local DELTA_DATA=()
	local NAME=${OLD_DATA[0]}
	local TOTAL=0
	
	local I=-1
	for OLD in ${OLD_DATA[@]}
	do	
  		((I+=1))
  		if [ $I -eq 0 ]
  		then
  			DELTA_DATA[$I]=""
  			continue
  		fi
  		DELTA_DATA[$I]=$((NEW_DATA[$I]- OLD_DATA[$I]))
  		((TOTAL+=DELTA_DATA[$I]))
	done
	
	sendCpuMetric $1 "$NAME" "user" "${DELTA_DATA[1]}" "$TOTAL"
	sendCpuMetric $1 "$NAME" "nice" "${DELTA_DATA[2]}" "$TOTAL"
	sendCpuMetric $1 "$NAME" "system" "${DELTA_DATA[3]}" "$TOTAL"
	sendCpuMetric $1 "$NAME" "idle" "${DELTA_DATA[4]}" "$TOTAL"
	sendCpuMetric $1 "$NAME" "iowait" "${DELTA_DATA[5]}" "$TOTAL"
	sendCpuMetric $1 "$NAME" "irq" "${DELTA_DATA[6]}" "$TOTAL"
	sendCpuMetric $1 "$NAME" "softirq" "${DELTA_DATA[7]}" "$TOTAL"
	sendCpuMetric $1 "$NAME" "steal" "${DELTA_DATA[8]}" "$TOTAL"
	sendCpuMetric $1 "$NAME" "guest" "${DELTA_DATA[9]}" "$TOTAL"
	sendCpuMetric $1 "$NAME" "totalUsed" "$((TOTAL- DELTA_DATA[4]))" "$TOTAL"
}

#METHOD
#PUBLIC
# Check Temp of GPU
#
#PARAMETERS
# $1 | Date | Date in seconds since epoc
# $2 | CPU Name | Name of the cpu the data belongs to
# $3 | Stat Name | Name of the statistic to process
# $4 | Used Cycles | Number of total Cycles used
# $5 | Total | Total cycles available

function sendCpuMetric()
{
	local USAGE=$(echo "scale=2; 100*$4/$5" | bc -l)
  	sendLine2Cache $1 $2.usage.$3 $USAGE 
}

#METHOD
#PUBLIC
# Prpcess data about the cpus
#
#PARAMETERS
# $1 | Date | Date in seconds since epoc
function checkCpuUsage()
{
	log "Checking CPU Usage" $TRACE
	log "Reading from ${CPU_STATUS}" $DEBUG
	local CPU_LINES=();
	local I=-1
  	while IFS= read -r CPU
  	do
  		((I+=1))
  		processSingleCpuData "$1" "${OLD_CPU_READINGS[${I}]}" "$CPU"
  		OLD_CPU_READINGS[${I}]="$CPU"
  	done < <(grep cpu ${CPU_STATUS})
}

#METHOD
#PUBLIC
# This will send the output line to the cache that will be writen at a later time
#
#PARAMETERS
# $1 | Date | Date in seconds since epoc
# $2 | Key | Key of the value
# $3 | Value | Value to be logged
function sendLine2Cache
{
	OUTPUT_CACHE+="$HOSTNAME $2 $1 ${3}\\n"
}

#METHOD
#PUBLIC
# Check if a given directory exists, if not it will create it
#
#PARAMETERS
# $1 | Directory | Directory to Check
function ensureDir
{
	if [ ! -d “$1” ]; then
  		mkdir -p $1
	fi
}
    
##############################################################
# Script Setup                                               #
############################################################## 
loadRequirements

setDescription "This script will read Cpu information and save it to a file in Zabbix format"

addVar2Dump "BL_PATH"
addVar2Dump "LIB_PATH"
addVar2Dump "KEY_CPU_TEMP"
addVar2Dump "KEY_GPU_TEMP"
addVar2Dump "CPUS"
addVar2Dump "OUTPUT_DIR"
addVar2Dump "CPU_TEMP_FILE"
addVar2Dump "GPU_TEMP_FILE"
addVar2Dump "CPU_STATUS"
addVar2Dump "BASE_CPU_FREQ_DIR"
addVar2Dump "CYCLE_TIME_MIN"

addCommandLineArg "o" "outputDir" true "The base directory where data files will be writen Default: $OUTPUT_DIR"

addCommandLineParser "optParserMonitorCpu"

parseCmdLine "$@"
varDump $DEBUG

ensureDir $OUTPUT_DIR

while true
do
  DATE_ARRAY=($(date +"%d%B%Y_%H %s"))
  OUTPUT_FILE=$OUTPUT_DIR/${DATE_ARRAY[0]}
  DATE=${DATE_ARRAY[1]}
  OUTPUT_CACHE=()
  log "Saving Data to $OUTPUT_FILE" $INFO
  checkCpuTemp $DATE
  checkGpuTemp $DATE
  checkCpuFreq $DATE
  if [ $((LAST_CHECK+10)) -le $DATE ]
  then
  	checkCpuUsage $DATE
  	LAST_CHECK=$DATE
  fi
  echo -e -n $OUTPUT_CACHE >> $OUTPUT_FILE
  sleep $CYCLE_TIME_MIN
done
