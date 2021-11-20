#!/bin/bash
#FILE
# This will process GPU Temp
#VERSION 1.1.0
#VERSIONS
#V 1.1.0
# Fix ShellCheck Issues
#
#V 1.0.0
# Initial Split of code to handle Gpu Temp

if [[ " ${LOADED_LIB[*]} " != *" checkGpuTemp.sh "* ]]; then
    LOADED_LIB+=('checkGpuTemp.sh')
     
    # Allow the library to parse command line options
    source "$LIB_PATH/cmdOptions.sh"
    # Adds the base logging features
    source "$LIB_PATH/colorLogging.sh"
	# Adds ability to output data in a zabbix file
	source "$LIB_PATH/outputZabbixFile.sh"
	
    #VARIABLE
    #PROTECTED
    # This is the file where GPU Temp Data is stored
	GPU_TEMP_FILE="/sys/devices/virtual/thermal/thermal_zone1/temp"
	
	#VARIABLE
	#PROTECTED
	# This variable will set weather the gpu Temp should be tracked or not
	GPU_TEMP_ENABLED=1;
	
	#VARIABLE
	#PROTECTED
	# This is the number of seconds to wait before checing the GPU Temp again
	GPU_TEMP_CYCLE=1;
	
	#VARIABLE
	#PRIVATE
	# This holds the last time the gpu check was run.
	GPU_TEMP_LAST_CHECK=0;
	
	#VARIABLE
	#PRIVATE
	# This is the key that will be used when outputing GPU Temp
	KEY_GPU_TEMP="temp.gpu"
	
	#METHOD
	#PUBLIC
	# Check Temp of GPU
	#
	#PARAMETERS
	# $1 | Date | Date in seconds since epoc
	function checkGpuTemp()
	{
		skipCheck "GPU Temp" "$GPU_TEMP_ENABLED" "$GPU_TEMP_LAST_CHECK" "$GPU_TEMP_CYCLE" "$1" && \
		return 0
			
		GPU_TEMP_LAST_CHECK=$1			
		log "Checking GPU Temp" "$TRACE" "$TEXT_BLUE"
		[ ! -r "${GPU_TEMP_FILE}" ] && \
			log "You can not read the GPU temp file so skiping it" "$INFO" "$TEXT_RED" && \
			return

		local TEMP=
		TEMP=$(cat ${GPU_TEMP_FILE})
		TEMP=$(echo "${TEMP}/1000" | bc -l)
	  	TEMP=$(printf '%.3f\n' "$TEMP")
	  	sendZabbixLine2Cache "$1" "$KEY_GPU_TEMP" "$TEMP" 
	}
	
	#METHOD
	#PRIVATE
	# this will parse command line options for this script
	#
	#PARAMETERS
	# $1 | option | The option to parse
	# $2 | data | The Data passed with the option | optional
	function optCheckGpuTemp()
	{
		case $1 in 
			--gpuTempFile)
				GPU_TEMP_FILE=$2
				;;
			--gpuTempEnabled)
				GPU_TEMP_ENABLED=$2
				;;
			--gpuTempCycle)
				GPU_TEMP_CYCLE=$2
				;;
		esac    			
	}  
    
    ##############################################################
    # Library Setup                                              #
    ##############################################################  
    addVar2Dump "GPU_TEMP_FILE" 
    addVar2Dump "GPU_TEMP_ENABLED"
    addVar2Dump "GPU_TEMP_CYCLE"
    addVar2Dump "KEY_GPU_TEMP"
    
	addCommandLineArg "" "gpuTempFile" true "This is the file where the GPU Temp can be found Default: $GPU_TEMP_FILE"
	addCommandLineArg "" "gpuTempEnabled" true "0 = don't outout gpu Temp 1 = output Gpu Temp Default: $GPU_TEMP_ENABLED"
	addCommandLineArg "" "gpuTempCycle" true "This is the number of seconds to wait between checking GPU Temp Default: $GPU_TEMP_CYCLE"
	
	addCommandLineParser "optCheckGpuTemp"
    
fi