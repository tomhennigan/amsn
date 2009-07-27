
rm ~/amsn/utils/macosx/gstreamer/*.so
rm ~/amsn/utils/macosx/gstreamer/*.dylib

for software in $(echo gettext libiconv glib2 libxml2 liboil gstreamer gst-plugins-base gst-plugins-good gst-plugins-bad gst-ffmpeg farsight2 libnice bzip2 speex); do
   cp /opt/local/var/macports/software/$software/*+universal/opt/local/lib/*.dylib ~/amsn/utils/macosx/gstreamer/
   cp /opt/local/var/macports/software/$software/*+universal/opt/local/lib/gstreamer-0.10/*.so ~/amsn/utils/macosx/gstreamer/
   cp /opt/local/var/macports/software/$software/*+universal/opt/local/lib/farsight2-0.0/*.so ~/amsn/utils/macosx/gstreamer/
done

for file in ~/amsn/utils/macosx/gstreamer/*.so ~/amsn/utils/macosx/gstreamer/*.dylib; do
   base=`basename $file`
   if [  x`grep "$base" ~/amsn/utils/macosx/gst_files.txt ` == "x" ] ; then
      rm $file
   fi
done

