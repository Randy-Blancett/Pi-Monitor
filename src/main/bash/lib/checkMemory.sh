#!/bin/bash
#FILE
# This will process Cpu Frequency
#VERSION 1.0.0
#VERSIONS
#V 1.0.0
# Initial Release

if [[ " ${LOADED_LIB[*]} " != *" checkMemory.sh "* ]]; then
    LOADED_LIB+=('checkMemory.sh')
    
    [[ "${BASH_SOURCE[0]}" == "${0}" ]] && LIB_PATH="$( dirname "$0" )" && LIB_PATH=$(readlink -e "$LIB_PATH")
    
    # Allow the library to parse command line options
    source "$LIB_PATH/cmdOptions.sh"
    # Adds the base logging features
    source "$LIB_PATH/colorLogging.sh"
	# Adds ability to output data in a zabbix file
	source "$LIB_PATH/outputZabbixFile.sh"
	
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
	
	#VARIABLE
	#PRIVATE
	# This holds the Key for outputing memory total
	KEY_MEMORY_TOTAL="memory.total"
	
	#VARIABLE
	#PRIVATE
	# This holds the Key for outputing memory used
	KEY_MEMORY_USED="memory.used"
	
	#VARIABLE
	#PRIVATE
	# This holds the Key for outputing memory free
	KEY_MEMORY_FREE="memory.free"
	
	#VARIABLE
	#PRIVATE
	# This holds the Key for outputing Swap memory free
	KEY_MEMORY_SWAP_FREE="memory.swap.free"
	
	#VARIABLE
	#PRIVATE
	# This holds the Key for outputing Swap memory used
	KEY_MEMORY_SWAP_USED="memory.swap.used"
	
	#VARIABLE
	#PRIVATE
	# This holds the Key for outputing Swap memory total
	KEY_MEMORY_SWAP_TOTAL="memory.swap.total"
	
	#METHOD
	#PUBLIC
	# Process One line of the Memory Stats File
	#
	#PARAMETERS
	# $1 | Date | Date in seconds since epoc
	# $2 | Data | One Line of Data (Name:	Number kb)
	# $2 | Output Array | Name Ref to to output Array
	function processMemoryStatLine()
	{
		log "Processing [$2]" "$TRACE" "$TEXT_YELLOW"
 		local -n OUTPUT="$3"
		local STAT_SPLIT
 		readarray -t -d " " STAT_SPLIT <<<"$2"
 		local NAME=${STAT_SPLIT[0]} 
 		local DATA 		
 		[ -z "${STAT_SPLIT[-2]}" ] && DATA=${STAT_SPLIT[-1]} || DATA=${STAT_SPLIT[-2]} 		
 		OUTPUT["${NAME::-1}"]="${DATA}"
	}
	
	#METHOD
	#PUBLIC
	# Check Memroy Usage
	#
	#PARAMETERS
	# $1 | Date | Date in seconds since epoc
	#
	#EXIT_CODES
	# 1 | Check is Skipped
	function checkMemoryUsage()
	{
		skipCheck "Memory Usage" "$MEMORY_ENABLED" "$MEMORY_LAST_CHECK" "$MEMORY_CYCLE" "$1" && \
		return 1
				
		log "Reading from ${MEMORY_STAT_FILE}" "$DEBUG" "$TEXT_YELLOW"
		
		declare -A MEMORY_STATS
		
		MEMORY_LAST_CHECK=$1	
		local CPU_LINES=();
		local I=-1
	  	local STAT
	  	while read -r STAT; do
		  processMemoryStatLine "$1" "$STAT" MEMORY_STATS
		done <"${MEMORY_STAT_FILE}"
		
		local MEM_USED
		MEM_USED=$((MEMORY_STATS["MemTotal"] - MEMORY_STATS["MemFree"] - MEMORY_STATS["Buffers"] - MEMORY_STATS["Cached"] - MEMORY_STATS["Slab"] ))
		local MEM_SWAP_USED
		MEM_SWAP_USED=$((MEMORY_STATS["SwapTotal"] - MEMORY_STATS["SwapFree"] ))
					
	  	sendZabbixLine2Cache "$1" "$KEY_MEMORY_TOTAL" "$((MEMORY_STATS["MemTotal"] * 1000 ))" 
	  	sendZabbixLine2Cache "$1" "$KEY_MEMORY_FREE" "$((MEMORY_STATS["MemFree"] * 1000 ))" 
	  	sendZabbixLine2Cache "$1" "$KEY_MEMORY_USED" "$((MEM_USED * 1000 ))" 
	  	sendZabbixLine2Cache "$1" "$KEY_MEMORY_SWAP_FREE" "$((MEMORY_STATS["SwapFree"] * 1000 ))" 
	  	sendZabbixLine2Cache "$1" "$KEY_MEMORY_SWAP_TOTAL" "$((MEMORY_STATS["SwapTotal"] * 1000 ))" 
	  	sendZabbixLine2Cache "$1" "$KEY_MEMORY_SWAP_USED" "$((MEM_SWAP_USED * 1000 ))" 
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
    addVar2Dump "KEY_MEMORY_TOTAL"
    addVar2Dump "KEY_MEMORY_USED"
    addVar2Dump "KEY_MEMORY_FREE"
    addVar2Dump "KEY_MEMORY_SWAP_FREE"
    addVar2Dump "KEY_MEMORY_SWAP_USED"
    addVar2Dump "KEY_MEMORY_SWAP_TOTAL"
    
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
	 varDump "$DEBUG"	
	 checkMemoryUsage "$(date +"%s")" 
     printZabbixCache
    fi
 fi