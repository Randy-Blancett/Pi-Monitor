#!/bin/bash

SCRIPT_PATH="$( dirname $0 )"
SCRIPT_PATH=$(readlink -e $SCRIPT_PATH)

INSTALL_DIR="/monitor/scripts"
SERVICE_FILE="/lib/systemd/system/cpuMonitor.service"

echo "Copying files to $INSTALL_DIR"
mkdir -p $INSTALL_DIR
cp -R $SCRIPT_PATH/bash/* $INSTALL_DIR

echo "Creating Service File at $SERVICE_FILE"
cat << EOF > $SERVICE_FILE
[Unit]
Description=Script to save statistics about the CPUs

[Service]
ExecStart=$INSTALL_DIR/monitorCpuData.sh -o /nas/pihole/monitoring/

[Install]
WantedBy=multi-user.target
EOF


echo "Reloading daemon"
systemctl daemon-reload