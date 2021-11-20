#!/bin/bash
#FILE
# This will process Cpu Frequency
#VERSION 0.0.1
#VERSIONS
#V 0.0.1
# Initial Split of code to handle CPU Freq

if [[ " ${LOADED_LIB[*]} " != *" checkCpuFreq.sh "* ]]; then
    LOADED_LIB+=('checkCpufreq.sh')
    
    # Allow the library to parse command line options
    source $LIB_PATH/cmdOptions.sh
    # Adds the base logging features
    source $LIB_PATH/colorLogging.sh
	# Adds ability to output data in a zabbix file
	source $LIB_PATH/outputZabbixFile.sh
	
	#VARIABLE
    #PROTECTED
    # This is the base directory where the cpu Fequency files can be found
	BASE_CPU_FREQ_DIR="/sys/devices/system/cpu/"
	
	#VARIABLE
	#PROTECTED
	# This variable will set weather the CPU Freqency should be tracked or not
	CPU_FREQ_ENABLED=1;
	
	#VARIABLE
	#PROTECTED
	# This is the number of seconds to wait before checing the CPU Temp again
	CPU_FREQ_CYCLE=1;
	
	#VARIABLE
	#PRIVATE
	# This holds the last time the cpu check was run.
	CPU_FREQ_LAST_CHECK=0;
	
	#VARIABLE
	#PRIVATE
	# This holds the Key for outputing CPU Temp
	KEY_CPU_FREQ="freq.cpu"
	
	#VARIABLE
	#PRIVATE}
	# Array of numbers of cpus to check
	CPUS="0 1 2 3"
	
	#METHOD
	#PUBLIC
	# Check CPU Frequencies
	#
	#PARAMETERS
	# $1 | Date | Date in seconds since epoc
	function checkCpuFreq()
	{
		skipCheck "CPU Freqency" $CPU_FREQ_ENABLED $CPU_FREQ_LAST_CHECK $CPU_FREQ_CYCLE $1 && \
		return 0
		
		for CPU in ${CPUS}
		do
			log "Process $CPU" $TRACE	
			local FREQ_FILE="${BASE_CPU_FREQ_DIR}/cpu${CPU}/cpufreq/cpuinfo_cur_freq"
			if [ ! -r ${FREQ_FILE} ]
			then
				log "You can not read the frequency file so skiping it" $INFO $TEXT_RED
				continue
			fi	
			local FREQ=$(cat "$FREQ_FILE")			  		
	  		sendZabbixLine2Cache $1 "${KEY_CPU_FREQ}${CPU}" $FREQ 
		done
	}
	
	#METHOD
	#PRIVATE
	# this will parse command line options for this script
	#
	#PARAMETERS
	# $1 | option | The option to parse
	# $2 | data | The Data passed with the option | optional
	function optCheckCpuFreq()
	{
		case $1 in 
			--cpuFreqBaseDir)
				BASE_CPU_FREQ_DIR=$2
				;;
			--cpuFreqEnabled)
				CPU_FREQ_ENABLED=$2
				;;
			--cpuFreqCycle)
				CPU_FREQ_CYCLE=$2
				;;
		esac    			
	}  
    
    ##############################################################
    # Library Setup                                              #
    ##############################################################
    addVar2Dump "BASE_CPU_FREQ_DIR" 
    addVar2Dump "CPU_FREQ_ENABLED"
    addVar2Dump "CPU_FREQ_CYCLE"
    addVar2Dump "KEY_CPU_FREQ"
    addVar2Dump "CPUS"
    
	addCommandLineArg "" "cpuFreqBaseDir" true "This is the base directory where the CPU Frequency files can be found Default: $BASE_CPU_FREQ_DIR"
	addCommandLineArg "" "cpuFreqEnabled" true "0 = don't outout CPU FREQ 1 = output CPU Freq Default: $CPU_FREQ_ENABLED"
	addCommandLineArg "" "cpuFreqCycle" true "This is the number of seconds to wait between checking CPU Freq Default: $CPU_FREQ_CYCLE"
	
	addCommandLineParser "optCheckCpuFreq"
fi