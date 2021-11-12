#!/bin/bash
echo ""
echo "Self Extracting Installer"
echo "Orange Pi Monitor"
echo ""

export TMPDIR=`mktemp -d /tmp/selfextract.XXXXXX`

ARCHIVE=`awk '/^__ARCHIVE_BELOW__/ {print NR + 1; exit 0; }' $0`

echo "Extracting Files to $TMPDIR"
tail -n+$ARCHIVE $0 | tar xz -C $TMPDIR

CDIR=`pwd`
cd $TMPDIR
echo "Running Installer"
./installer.sh 

cd $CDIR
echo "Removing Temp Files"
rm -rf $TMPDIR

exit 0

__ARCHIVE_BELOW__
