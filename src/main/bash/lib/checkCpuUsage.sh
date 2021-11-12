#!/bin/bash
#FILE
# This will process Cpu Usage
#VERSION 0.0.1
#VERSIONS
#V 0.0.1
# Initial Split of code to handle CPU Usage

if [[ " ${LOADED_LIB[*]} " != *" checkCpuUsage.sh "* ]]; then
    LOADED_LIB+=('checkCpuUsage.sh')
    
     # Allow the library to parse command line options
    source $LIB_PATH/cmdOptions.sh
    # Adds the base logging features
    source $LIB_PATH/colorLogging.sh
	# Adds ability to output data in a zabbix file
	source $LIB_PATH/outputZabbixFile.sh
	
	#VARIABLE
    #PROTECTED
    # This is the file where the CPU usage stats can be found
	BASE_CPU_USAGE_FILE="/proc/stat"
	
	#VARIABLE
	#PROTECTED
	# This variable will set weather the CPU Usage should be tracked or not
	CPU_USAGE_ENABLED=1;
	
	#VARIABLE
	#PROTECTED
	# This is the number of seconds to wait before checing the CPU Usage again
	CPU_USAGE_CYCLE=10;
	
	#VARIABLE
	#PRIVATE
	# This holds the last time the cpu Usage check was run.
	CPU_USAGE_LAST_CHECK=0;
	
	#VARIABLE
	#PRIVATE
	# Temporary location to store CPU Readings
	OLD_CPU_READINGS=()
		
	#METHOD
	#PUBLIC
	# Check CPU Frequencies
	#
	#PARAMETERS
	# $1 | Date | Date in seconds since epoc
	function checkCpuUsage()
	{
		skipCheck "CPU Usage" $CPU_USAGE_ENABLED $CPU_USAGE_LAST_CHECK $CPU_USAGE_CYCLE $1 && \
		return 0
				
		log "Reading from ${CPU_STATUS}" $DEBUG $YELLOW_TEXT
		
		CPU_USAGE_LAST_CHECK=$1	
		local CPU_LINES=();
		local I=-1
	  	while IFS= read -r CPU
	  	do
	  		((I+=1))
	  		processSingleCpuData "$1" "${OLD_CPU_READINGS[${I}]}" "$CPU"
	  		OLD_CPU_READINGS[${I}]="$CPU"
	  	done < <(grep cpu ${BASE_CPU_USAGE_FILE})
	}
	
	#METHOD
	#PRIVATE
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
		log "Processing One cpu [$2] [$3]" $TRACE $TEXT_YELLOW
		[ -z "$2" ] && \
			log "There is no old data so we can not process." "$INFO" "$TEXT_YELLOW" && \
			return
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
	  	sendZabbixLine2Cache $1 $2.usage.$3 $USAGE 
	}
	
	#METHOD
	#PRIVATE
	# this will parse command line options for this script
	#
	#PARAMETERS
	# $1 | option | The option to parse
	# $2 | data | The Data passed with the option | optional
	function optCheckCpuUsage()
	{
		case $1 in 
			--cpuUsageFile)
				BASE_CPU_USAGE_FILE=$2
				;;
			--cpuUsageEnabled)
				CPU_USAGE_ENABLED=$2
				;;
			--cpuUsageCycle)
				CPU_USAGE_CYCLE=$2
				;;
		esac    			
	}  
    
    ##############################################################
    # Library Setup                                              #
    ##############################################################
    addVar2Dump "BASE_CPU_USAGE_FILE" 
    addVar2Dump "CPU_USAGE_ENABLED"
    addVar2Dump "CPU_USAGE_CYCLE"
    
	addCommandLineArg "" "cpuUsageFile" true "This is the file where the CPU usage stats can be found Default: $BASE_CPU_USAGE_FILE"
	addCommandLineArg "" "cpuUsageEnabled" true "0 = don't outout CPU Usage 1 = output CPU Usage Default: $CPU_USAGE_ENABLED"
	addCommandLineArg "" "cpuUsageCycle" true "This is the number of seconds to wait between checking CPU Usage Default: $CPU_USAGE_CYCLE"
	
	addCommandLineParser "optCheckCpuUsage"
fi