echo "Make sure you run this with '. ./utils/macosx/startbuild.sh' (start with a dot then space then path) so that the exported variables affect your current shell"
export CFLAGS='-arch ppc -arch i386 -isysroot /Developer/SDKs/MacOSX10.4u.sdk -mmacosx-version-min=10.3'
export CXXFLAGS=$CFLAGS
export LDFLAGS="$CFLAGS -headerpad_max_install_names"
export MACOSX_DEPLOYMENT_TARGET=10.3
