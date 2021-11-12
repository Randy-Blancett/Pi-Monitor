#!/bin/bash
cd ${project.build.directory}/installer

FINAL_FILE="${project.build.directory}/PiMonitorInstaller.bsx"

cat install.sh > "$FINAL_FILE"

if [ -e "payload.tar.gz" ]; then
    cat payload.tar.gz >> "$FINAL_FILE"
else
    echo "payload.tar.gz does not exist"
    exit 1
fi

echo "$FINAL_FILE created"
exit 0