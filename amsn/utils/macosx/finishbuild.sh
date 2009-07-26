#!/bin/sh
# Based aMSN Build script by David Luyer (http://www.luyer.net/osx/).

# See if we are running the script from the amsn dir, or inside utils/macosx.
if [ -z $(pwd | grep utils) ]; then
	UTILS_PATH=$(dirname $(dirname $0))
else
	UTILS_PATH=".."
fi

# Copy the built in the files to the right places.
echo "Renaming built libraries to have correct extension."
if [ -f ${UTILS_PATH}/webcamsn/webcamsn.so ]; then
	echo "Moving webcamsn."
	mv ${UTILS_PATH}/webcamsn/webcamsn.so \
		${UTILS_PATH}/webcamsn/webcamsn.dylib
fi
if [ -f ${UTILS_PATH}/TkCximage/TkCximage.so ]; then
	echo "Moving TkCximage."
	mv ${UTILS_PATH}/TkCximage/TkCximage.so \
		${UTILS_PATH}/TkCximage/TkCximage.dylib
fi
if [ -f ${UTILS_PATH}/tcl_siren/tcl_siren.so ]; then
	echo "Renaming tcl_siren."
	mv ${UTILS_PATH}/tcl_siren/tcl_siren.so \
		${UTILS_PATH}/tcl_siren/tcl_siren.dylib
fi

if [ -f ${UTILS_PATH}/tclISF/tclISF.so ]; then
	echo "Renaming tclISF."
	mv ${UTILS_PATH}/tclISF/tclISF.so \
		${UTILS_PATH}/tclISF/tclISF.dylib
fi

remaplib() {

  if [ -z "$1" -o -z "$2" -o -z "$3" ]; then
    echo "usage: remaplib lib old_path new_path";
    return;
  fi

  lib="$1"
  old="$2"
  new="$3"

  for file in `otool -L "$lib" | tail -n+3 | awk '{print$1}' | grep $old`; do
    base=`basename $file`
    install_name_tool -change "$file" "${new}${base}" "$lib"
  done
}

for file in `find ${UTILS_PATH}/macosx/gstreamer/ -name *.dylib`; do
    remaplib $file "/opt/local/lib/gstreamer-0.10" "@executable_path/../gstreamer/"
    remaplib $file "/opt/local/lib/farsight2-0.0" "@executable_path/../gstreamer/"
    remaplib $file "/opt/local/lib/" "@executable_path/../gstreamer/"
done

for file in `find ${UTILS_PATH}/macosx/gstreamer/ -name *.so`; do
    remaplib $file "/opt/local/lib/gstreamer-0.10" "@executable_path/../gstreamer/"
    remaplib $file "/opt/local/lib/farsight2-0.0" "@executable_path/../gstreamer/"
    remaplib $file "/opt/local/lib/" "@executable_path/../gstreamer/"
done

find_missing_libs() {
  lib="$1"
  missing=""

  for file in `otool -L "$lib" | tail -n+3 | awk '{print$1}' `; do
    base=`basename $file`
    if [ ! -f $file ]; then
         missing="$missing\n$file"
    fi
  done

}

# Fix bindings to aMSN internal Tcl/Tk versions.
echo "Fixing bindings to use embedded tcltk."
for file in `find ${UTILS_PATH} -name *.dylib` utils/macosx/sndplay
do
        install_name_tool -change /Library/Frameworks/Tk.framework/Versions/8.4/Tk \
                @executable_path/../Frameworks/Tk.framework/Versions/8.4/Tk "$file"
        install_name_tool -change /System/Library/Frameworks/Tk.framework/Versions/8.4/Tk \
                @executable_path/../Frameworks/Tk.framework/Versions/8.4/Tk "$file"
        install_name_tool -change /Library/Frameworks/Tcl.framework/Versions/8.4/Tcl \
                @executable_path/../Frameworks/Tcl.framework/Versions/8.4/Tcl "$file"
        install_name_tool -change /System/Library/Frameworks/Tcl.framework/Versions/8.4/Tcl \
                @executable_path/../Frameworks/Tcl.framework/Versions/8.4/Tcl "$file"

		install_name_tool -change /Library/Frameworks/Tk.framework/Versions/8.5/Tk \
		        @executable_path/../Frameworks/Tk.framework/Versions/8.5/Tk "$file"
		install_name_tool -change /System/Library/Frameworks/Tk.framework/Versions/8.5/Tk \
		        @executable_path/../Frameworks/Tk.framework/Versions/8.5/Tk "$file"
		install_name_tool -change /Library/Frameworks/Tcl.framework/Versions/8.5/Tcl \
		        @executable_path/../Frameworks/Tcl.framework/Versions/8.5/Tcl "$file"
		install_name_tool -change /System/Library/Frameworks/Tcl.framework/Versions/8.5/Tcl \
		        @executable_path/../Frameworks/Tcl.framework/Versions/8.5/Tcl "$file"
done

echo "Done."
