#!/bin/bash
#FILE
#AUTHOR Randy Blancett
#AUTHOR_EMAIL Randy.Blancett@gmail.com
#VERSION 1.1.0
#VERSIONS
#V 1.1.0
# Fix ShellCheck Issues
#
#V 1.0.0
# Initial Release

if [[ " ${LOADED_LIB[*]} " != *" outputZabbixFiles.sh "* ]]; then
    LOADED_LIB+=('outputZabbixFiles.sh')
    
    # Allow the library to parse command line options
    source "$LIB_PATH/cmdOptions.sh"
    # Adds the base logging features
    source "$LIB_PATH/colorLogging.sh"
    
    #VARIABLE
	#PROTECTED
	# This variable will store all the lines until they should be writen
	# This is done to minimize disk IO
  	OUTPUT_CACHE=()
    
    #VARIABLE
	#PROTECTED
	# This is the location where the Zabbix File will be writen to
	OUTPUT_DIR="/tmp/zabbix"
	
	#METHOD
	#PUBLIC
	# This Method will write the cache to disk
	function writeZabbixCache
	{
  		log "Saving Data to $OUTPUT_FILE" "$INFO" "$TEXT_BLUE"
		echo -e -n "${OUTPUT_CACHE[@]}" >> "$OUTPUT_FILE"
  		OUTPUT_CACHE=()
	}	
	
	#METHOD
	#PUBLIC
	# This Method will print the zabbix data to screen 
	# Mostly used for testing.
	function printZabbixCache
	{
  		log "Printing Zabbix Cache" "$STANDARD" "$TEXT_BLUE"
		echo -e -n "${OUTPUT_CACHE[@]}"
  		OUTPUT_CACHE=()
	}	
	
	#METHOD
	#PUBLIC
	# This will send the output line to the cache that will be writen at a later time
	# If this returns 0 then you should skip if it returns something other than 0 then run the check
	#
	#PARAMETERS
	# $1 | Name | Name of the Check
	# $2 | Enabled | Is Check Enabled 0 =  no, 1 = yes
	# $3 | Last Check | Timestamp of last successful Check
	# $4 | Cycle | Number of seconds to wait between checks
	# $5 | Date | Current Timestamp
	function skipCheck
	{
		log "Checking if we should run: $1" "$OMG" "$TEXT_BLUE" 	
		[ 0 == "$2" ] && \
			log "$1 check has been disabled" "$DEBUG" "$TEXT_RED" && \
			return 0
			
		log "Seeing if $3+$4 is Greater Than [$5]" "$OMG" "$TEXT_BLUE" 			
		[ $(($3+$4)) -gt "$5" ] && \
			log "$1 check should not be run this time." "$DEBUG" "$TEXT_BLUE" && \
			return 0
			
		return 1
	}
	
	#METHOD
	#PUBLIC
	# This will send the output line to the cache that will be writen at a later time
	#
	#PARAMETERS
	# $1 | Date | Date in seconds since epoc
	# $2 | Key | Key of the value
	# $3 | Value | Value to be logged
	function sendZabbixLine2Cache
	{
		# shellcheck disable=SC2179
		OUTPUT_CACHE+="$HOSTNAME $2 $1 ${3}\\n"
	}

	#METHOD
	#PRIVATE
	# this will parse command line options for this script
	#
	#PARAMETERS
	# $1 | option | The option to parse
	# $2 | data | The Data passed with the option | optional
	function optOutputZabbixFile()
	{
		case $1 in 
			-o | --outputDir)
				OUTPUT_DIR=$2
				;;
		esac    			
	}  
    
    ##############################################################
    # Library Setup                                              #
    ##############################################################		
	addVar2Dump "OUTPUT_DIR"
	addCommandLineArg "o" "outputDir" true "The base directory where data files will be writen Default: $OUTPUT_DIR"
	addCommandLineParser "optOutputZabbixFile"
    
fi