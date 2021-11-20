#!/bin/bash
#FILE
# This will process Cpu Frequency
#VERSION 1.0.0
#VERSIONS
#V 1.0.0
# Initial Release

if [[ " ${LOADED_LIB[*]} " != *" checkMemory.sh "* ]]; then
    LOADED_LIB+=('checkMemory.sh')
    
    [[ "${BASH_SOURCE[0]}" == "${0}" ]] && LIB_PATH="$( dirname $0 )" && LIB_PATH=$(readlink -e $LIB_PATH)
    
    # Allow the library to parse command line options
    source $LIB_PATH/cmdOptions.sh
    # Adds the base logging features
    source $LIB_PATH/colorLogging.sh
	# Adds ability to output data in a zabbix file
	source $LIB_PATH/outputZabbixFile.sh
	
	#VARIABLE
    #PROTECTED
    # This is the file where the Memory Info can be found
	MEMORY_STAT_FILE="/proc/meminfo"
	
	#VARIABLE
	#PROTECTED
	# This variable will set weather the Memory should be tracked or not
	MEMORY_ENABLED=1;
	
	#VARIABLE
	#PROTECTED
	# This is the number of seconds to wait before checing the Memory again
	MEMORY_CYCLE=15;
	
	#VARIABLE
	#PRIVATE
	# This holds the last time the Memory check was run.
	MEMORY_LAST_CHECK=0;
	
	#METHOD
	#PUBLIC
	# Check Memroy Usage
	#
	#PARAMETERS
	# $1 | Date | Date in seconds since epoc
	function checkMemoryUsage()
	{
		skipCheck "Memory Usage" "$MEMORY_ENABLED" "$MEMORY_LAST_CHECK" "$MEMORY_CYCLE" "$1" && \
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
	# this will parse command line options for this script
	#
	#PARAMETERS
	# $1 | option | The option to parse
	# $2 | data | The Data passed with the option | optional
	function optCheckMemory()
	{
		case $1 in 
			--memoryStatFile)
				MEMORY_STAT_FILE=$2
				;;
			--memoryEnabled)
				MEMORY_ENABLED=$2
				;;
			--memoryCycle)
				MEMORY_CYCLE=$2
				;;
		esac    			
	}  
    
    ##############################################################
    # Library Setup                                              #
    ##############################################################
    addVar2Dump "MEMORY_STAT_FILE" 
    addVar2Dump "MEMORY_ENABLED" 
    addVar2Dump "MEMORY_CYCLE" 
    addVar2Dump "MEMORY_LAST_CHECK" 
    
    addCommandLineArg "" "memoryStatFile" true "This is the file where memory stats can be found Default: $MEMORY_STAT_FILE"
	addCommandLineArg "" "memoryEnabled" true "0 = don't outout Memory 1 = output Memory Default: $MEMORY_ENABLED"
	addCommandLineArg "" "memoryCycle" true "This is the number of seconds to wait between checking Memory Default: $MEMORY_CYCLE"
    
    ##############################################################
    # Testing Process                                            #
    ##############################################################
    
    if [[ "${BASH_SOURCE[0]}" == "${0}" ]]
    then
     log "${BASH_SOURCE[0]} is being run directly, this is only intened for Testing" "$STANDARD" "$TEXT_BLUE"
     parseCmdLine "$@"
	 varDump $DEBUG	 
    fi
 fi