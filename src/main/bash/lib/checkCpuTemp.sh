#!/bin/bash
#FILE
# This will process Cpu Temp
#VERSION 1.1.0
#VERSIONS
#V 1.1.0
# Fix ShellCheck Issues
# Add Test code
#
#V 1.0.0
# Initial Split of code to handle CPU Temp

if [[ " ${LOADED_LIB[*]} " != *" checkCpuTemp.sh "* ]]; then
    LOADED_LIB+=('checkCpuTemp.sh')    
    [[ "${BASH_SOURCE[0]}" == "${0}" ]] && LIB_PATH="$( dirname "$0" )" && LIB_PATH=$(readlink -e "$LIB_PATH")
    
     # Allow the library to parse command line options
    source "$LIB_PATH/cmdOptions.sh"
    # Adds the base logging features
    source "$LIB_PATH/colorLogging.sh"
	# Adds ability to output data in a zabbix file
	source "$LIB_PATH/outputZabbixFile.sh"
	
	#VARIABLE
    #PROTECTED
    # This is the file where CPU Temp Data is stored
	CPU_TEMP_FILE="/sys/devices/virtual/thermal/thermal_zone0/temp"
	
	#VARIABLE
	#PROTECTED
	# This variable will set weather the cpu Temp should be tracked or not
	CPU_TEMP_ENABLED=1;
	
	#VARIABLE
	#PROTECTED
	# This is the number of seconds to wait before checing the CPU Temp again
	CPU_TEMP_CYCLE=1;
	
	#VARIABLE
	#PRIVATE
	# This holds the last time the cpu check was run.
	CPU_TEMP_LAST_CHECK=0;
	
	#VARIABLE
	#PRIVATE
	# This holds the Key for outputing CPU Temp
	KEY_CPU_TEMP="temp.cpu"
	
	#METHOD
	#PUBLIC
	# Check Temp of CPU
	#
	#PARAMETERS
	# $1 | Date | Date in seconds since epoc
	function checkCpuTemp()
	{
		skipCheck "CPU Temp" "$CPU_TEMP_ENABLED" "$CPU_TEMP_LAST_CHECK" "$CPU_TEMP_CYCLE" "$1" && \
		return 0
			
		CPU_TEMP_LAST_CHECK=$1			
		log "Checking CPU Temp" "$TRACE"
		[ ! -r ${CPU_TEMP_FILE} ] && \
			log "You can not read the cpu temp file so skiping it" "$INFO" "$TEXT_RED" && \
			return
		local TEMP
		TEMP=$(cat ${CPU_TEMP_FILE})
		TEMP=$(echo "${TEMP}/1000" | bc -l)
	  	TEMP=$(printf '%.3f\n' "$TEMP")
	  	sendZabbixLine2Cache "$1" "$KEY_CPU_TEMP" "$TEMP" 
	}
	
	#METHOD
	#PRIVATE
	# this will parse command line options for this script
	#
	#PARAMETERS
	# $1 | option | The option to parse
	# $2 | data | The Data passed with the option | optional
	function optCheckCpuTemp()
	{
		case $1 in 
			--cpuTempFile)
				CPU_TEMP_FILE=$2
				;;
			--cpuTempEnabled)
				CPU_TEMP_ENABLED=$2
				;;
			--cpuTempCycle)
				CPU_TEMP_CYCLE=$2
				;;
		esac    			
	}  
    
    ##############################################################
    # Library Setup                                              #
    ##############################################################
    addVar2Dump "CPU_TEMP_FILE" 
    addVar2Dump "CPU_TEMP_ENABLED"
    addVar2Dump "CPU_TEMP_CYCLE"
    addVar2Dump "KEY_CPU_TEMP"
    
	addCommandLineArg "" "cpuTempFile" true "This is the file where the CPU Temp can be found Default: $CPU_TEMP_FILE"
	addCommandLineArg "" "cpuTempEnabled" true "0 = don't outout CPU Temp 1 = output CPU Temp Default: $CPU_TEMP_ENABLED"
	addCommandLineArg "" "cpuTempCycle" true "This is the number of seconds to wait between checking CPU Temp Default: $CPU_TEMP_CYCLE"
	
	addCommandLineParser "optCheckCpuTemp"
    
    ##############################################################
    # Testing Process                                            #
    ##############################################################
    
    if [[ "${BASH_SOURCE[0]}" == "${0}" ]]
    then
     log "${BASH_SOURCE[0]} is being run directly, this is only intened for Testing" "$STANDARD" "$TEXT_BLUE"
     parseCmdLine "$@"
	 varDump "$DEBUG"
	 DATE=$(date +"%d%B%Y_%H %s ")
	 readarray -t -d " " DATE_ARRAY <<<"$DATE"
  	 DATE=${DATE_ARRAY[1]}  	 
     checkCpuTemp "$DATE"
     printZabbixCache
    fi
fi