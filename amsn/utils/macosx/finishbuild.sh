#!/bin/sh
# Based aMSN Build script by David Luyer (http://www.luyer.net/osx/).

# See if we are running the script from the amsn dir, or inside utils/macosx.
if [ -z $(pwd | grep utils) ]; then
	UTILS_PATH=$(dirname $(dirname $0))
else
	UTILS_PATH=".."
fi

remaplib() {

  if [ -z "$1" -o -z "$2" -o -z "$3" ]; then
    echo "usage: remaplib lib old_path new_path";
    return;
  fi

  lib="$1"
  old="$2"
  new="$3"

  if [ `otool -D "$lib" | wc -l ` == "2" ]; then n=3; else n=2; fi

  for file in `otool -L "$lib" | tail -n+${n} | awk '{print$1}' | grep $old`; do
    base=`basename $file`
    install_name_tool -change "$file" "${new}${base}" "$lib"
  done
}

find_missing_libs() {
  lib="$1"
  missing=""

  if [ `otool -D "$lib" | wc -l ` == "2" ]; then n=3; else n=2; fi

  for file in `otool -L "$lib" | tail -n+${n} | awk '{print$1}' `; do
    file=`echo "$file" | sed 's/@executable_path/\/Applications\/aMSN.app\/Contents\/MacOS\//'`
    if [ ! -f $file ]; then
         missing="$missing\n$lib : $file"
    fi
  done

 echo $missing 
}

# Fix bindings to aMSN internal Tcl/Tk versions.
echo "Fixing bindings to use embedded tcltk."

files=`find ${UTILS_PATH}/ -name *.dylib`
files="$files `find ${UTILS_PATH}/macosx/gstreamer/ -name *.so`"
for file in $files ; do
    install_name_tool -change /opt/local/lib/libz.dylib /usr/lib/libz.dylib $file
    install_name_tool -change /opt/local/lib/libz.1.dylib /usr/lib/libz.1.dylib $file
    install_name_tool -change /opt/local/lib/libz.1.2.3.dylib /usr/lib/libz.1.2.3.dylib $file
    install_name_tool -change /usr/lib/libxml2.2.dylib @executable_path/../gstreamer/libxml2.2.dylib $file
    install_name_tool -change /usr/lib/libiconv.2.dylib @executable_path/../gstreamer/libiconv.2.dylib $file

    remaplib $file "/opt/local/lib/gstreamer-0.10" "@executable_path/../gstreamer/"
    remaplib $file "/opt/local/lib/farsight2-0.0" "@executable_path/../gstreamer/"
    remaplib $file "/opt/local/lib/" "@executable_path/../gstreamer/"
done

echo "Looking for unused libs"
unused=""
for lib in `find ${UTILS_PATH}/macosx/gstreamer/ -name *.dylib`; do
    found=""
    base=`basename $lib`
    for file in $files; do 
       if [ `otool -D "$file" | wc -l ` == "2" ]; then n=3; else n=2; fi
       found="${found}$(otool -L $file | tail -n+${n} | grep $base)"
    done
    if [ "x$found" == "x" ]; then
         unused="$unused\n$lib"
    fi
done
echo "Unused libs : $unused"

echo "Looking for missing libs"
missing=""
for file in $files; do
    missing="$missing\n$(find_missing_libs $file)"
done

echo "Missing libs : $(echo "$missing" | sort | uniq)"

echo "Done."
