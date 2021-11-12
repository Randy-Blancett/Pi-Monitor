#!/bin/bash
#FILE
# This is the entry point for the self extracting installer
#VERSION 0.0.1
#VERSIONS
#V 0.0.1
# Initial Installer

BL_PATH="$( dirname $0 )"
BL_PATH=$(readlink -e $BL_PATH)
LIB_PATH="$BL_PATH/src/lib"

#VARIABLE
#PRIVATE
#
# Directory where zabbix files are stored
ZABBIX_OUTPUT_DIR=""

#VARIABLE
#PRIVATE
#
# Directory where to copy all the script files
INSTALL_LOCATION="/monitor"
SERVICE_FILE="/lib/systemd/system/orangePiMonitor.service"

function loadRequirements()
{
	# Add ability to Log
	source $LIB_PATH/colorLogging.sh
	# Add common Shell Functions
	source $LIB_PATH/shellUtils.sh
}

##############################################################
# Script Setup                                               #
############################################################## 
loadRequirements

addVar2Dump "INSTALL_LOCATION"
addVar2Dump "BL_PATH"
addVar2Dump "LIB_PATH"
addVar2Dump "SERVICE_FILE"

parseCmdLine "$@"
varDump $DEBUG
log "Installing Orange Pi Monitoring" "$STANDARD" "$TEXT_GREEN"
log " Install Directory : $INSTALL_LOCATION" "$STANDARD" "$TEXT_GREEN"

ensureRoot

ensureDir "$INSTALL_LOCATION"
copyDir "$BL_PATH/src/lib" "$INSTALL_LOCATION"
copyDir "$BL_PATH/doc" "$INSTALL_LOCATION"
copyFile "$BL_PATH/src/monitorDameon.sh" "$INSTALL_LOCATION"

askUser "Where should Zabbix Files be stored" "ZABBIX_OUTPUT_DIR"

echo $ZABBIX_OUTPUT_DIR


log "Creating Service File at $SERVICE_FILE" "$STANDARD" "$TEXT_GREEN"

cat << EOF > $SERVICE_FILE
[Unit]
Description=Script to save statistics about Orange Pi resources.

[Service]
ExecStart=$INSTALL_LOCATION/monitorDameon.sh -o "${ZABBIX_OUTPUT_DIR}"

[Install]
WantedBy=multi-user.target
EOF


log "Reloading daemon" "$STANDARD" "$TEXT_GREEN"
systemctl daemon-reload 
