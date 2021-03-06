
# This script originally by the growl project (growl.info)
# Author: Chris Forsythe (http://brok3n.org/archivesextreme/2006/09/dmg_creation_ti.html)

# aMSN-Changes:
#	- Fixed script to allow for spaces in dmg name and path.
#	- Added support for bless instead of openUp
#	- OpenUp resides locally rather than in /usr/local

# Create a read-only disk image of the contents of a folder
#
# Usage: make-diskimage <image_file>
#                       <src_folder>
#                       <volume_name>
#                       <applescript>
#                       <eula_resource_file>

set -e;

if [ -z "$1" -o -z "$2" -o -z "$3" ]; then
	echo "usage: $0 output_file src_folder volume_name ?applescript? ?eula_resource_file?"
	exit 1
fi 

DMG_DIRNAME="`dirname "$1"`"
DMG_DIR="`cd "$DMG_DIRNAME" > /dev/null; pwd`"
DMG_NAME="`basename "$1"`"
DMG_TEMP_NAME="${DMG_DIR}/rw.${DMG_NAME}"
SRC_FOLDER="`cd "$2" > /dev/null; pwd`"
VOLUME_NAME="$3"

# optional arguments
APPLESCRIPT="$4"
EULA_RSRC="$5"

# Create the image
echo "creating disk image"
rm -f "$DMG_TEMP_NAME"
hdiutil create -srcfolder "$SRC_FOLDER" -volname "$VOLUME_NAME" -fs HFS+ -fsargs "-c c=64,a=16,e=16" -format UDRW "$DMG_TEMP_NAME"

# mount it
echo "mounting disk image"
MOUNT_DIR="/Volumes/$VOLUME_NAME"
DEV_NAME="`hdiutil attach -readwrite -noverify -noautoopen $DMG_TEMP_NAME | egrep '^/dev/' | sed 1q | awk '{print $1}'`"

# run applescript
if [ ! -z "${APPLESCRIPT}" -a "${APPLESCRIPT}" != "-null-" ]; then
	osascript $APPLESCRIPT
fi

# make sure it's not world writeable
echo "fixing permissions"
chmod -Rf go-w "${MOUNT_DIR}" || true

# make the top window open itself on mount:

if [ -x ./openUp ]; then
	echo "making top window open on mount (openUp)"
    ./openUp "${MOUNT_DIR}"
else
	echo "making top window open on mount (bless)"
	bless --openfolder "${MOUNT_DIR}"
fi

# unmount
echo "unmounting disk image"
hdiutil detach "$DEV_NAME"

# compress image
echo "compressing disk image"
hdiutil convert "$DMG_TEMP_NAME" -format UDZO -imagekey zlib-level=9 -o "${DMG_DIR}/${DMG_NAME}"
rm -f "$DMG_TEMP_NAME"

# adding EULA resources
if [ ! -z "${EULA_RSRC}" -a "${EULA_RSRC}" != "-null-" ]; then
        echo "adding EULA resources"
        hdiutil unflatten "${DMG_DIR}/${DMG_NAME}"
        /Developer/Tools/ResMerger -a ${EULA_RSRC} -o "${DMG_DIR}/${DMG_NAME}"
        hdiutil flatten "${DMG_DIR}/${DMG_NAME}"
fi

echo "disk image done"
exit 0
