#!/bin/bash

TAG='Release-0_98_4'
VERSION='0.98.4'
DIR_NAME="amsn-$VERSION"
SKINS="Dark%20Matter%204.0 Oxygen"
RM_PLUGINS='DualDisplayPicture advancedconfigviewer chameleon devel'

# Prepare the working directory
echo "Preparing $DIR_NAME"
mkdir amsn-releases || true
cd amsn-releases
RELEASE_DIR=`pwd`
rm -rf $DIR_NAME

# Export amsn tag
echo "Exporting amsn tag $TAG to $DIR_NAME"
svn export https://amsn.svn.sourceforge.net/svnroot/amsn/tags/$TAG $DIR_NAME >  /dev/null

# Export plugins
echo "Exporting plugins to $DIR_NAME/plugins"
svn export --force https://amsn.svn.sourceforge.net/svnroot/amsn/trunk/amsn-extras/plugins/ $DIR_NAME/plugins  >  /dev/null

#delete unwanted plugins
for plugin in $RM_PLUGINS
do
  echo "Deleting unwanted plugin $plugin"
  rm -rf '$DIR_NAME/plugins/$plugin'
done

# Export wanted skins
cd $DIR_NAME/skins
for skin in $SKINS
do
  echo "Exporting skin $skin"
  svn export https://amsn.svn.sourceforge.net/svnroot/amsn/trunk/amsn-extras/skins/$skin >  /dev/null
done
cd $RELEASE_DIR

# Create full tarballs
echo "Creating tarballs"
tar -czf amsn-$VERSION-full.tar.gz $DIR_NAME
tar -cjf amsn-$VERSION-full.tar.bz2 $DIR_NAME

# Create source tarballs
echo "Creating source tarballs"
cd $DIR_NAME
rm -rf utils/windows/gnash utils/windows/gstreamer utils/windows/reg1.1 utils/windows/snack2.2 utils/windows/tkdnd/ utils/windows/tkvideo1.3.0/ utils/windows/winico0.6
find . -name "*.dll" | xargs rm -rf
find . -name "*.exe" | xargs rm -rf
rm -rf utils/macosx/sndplay utils/macosx/cabextract utils/macosx/QuickTimeTcl3.1 utils/macosx/gstreamer/ utils/macosx/tclAE2.0.4 utils/macosx/tls1.5.0
find . -name "*.dylib" | xargs rm -rf
find . -name "*.so" | xargs rm -rf
cd $RELEASE_DIR
tar -czf amsn-$VERSION-src.tar.gz $DIR_NAME
tar -cjf amsn-$VERSION-src.tar.bz2 $DIR_NAME
rm -rf $DIR_NAME
tar -xjf amsn-$VERSION-full.tar.bz2

# Create mac tarballs
echo "Creating mac tarballs"
cd $DIR_NAME
find . -name "Rules.mk" | xargs rm -rf
rm -rf utils/windows/ utils/linux/ autopackage/ debian/
find . -name "*.dll" | xargs rm -rf
find . -name "*.exe" | xargs rm -rf
find . -name "*.dsp" | xargs rm -rf
find . -name "*.dsw" | xargs rm -rf
find . -name "*.vcproj" | xargs rm -rf
find . -name "*.sln" | xargs rm -rf
find . -name "*.c" | xargs rm -rf
find . -name "*.cpp" | xargs rm -rf
find . -name "*.h" | xargs rm -rf
rm -rf utils/macosx/tclCarbon/src utils/macosx/aMSN.xcodeproj utils/macosx/statusicon/*.[mh] utils/macosx/sndplay-src utils/macosx/snack2.2/patches utils/macosx/make_dmg utils/macosx/macDock/src utils/macosx/growl1.0/src utils/macosx/*.sh
rm -rf utils/TkCximage/demos/ utils/TkCximage/src/ utils/asyncresolver/src/ utils/farsight/src/ utils/gupnp utils/libaio utils/tclISF/src utils/tcl_siren/src/ utils/webcamsn/src
cd $RELEASE_DIR
tar -czf amsn-$VERSION-mac.tar.gz $DIR_NAME
tar -cjf amsn-$VERSION-mac.tar.bz2 $DIR_NAME
rm -rf $DIR_NAME
tar -xjf amsn-$VERSION-full.tar.bz2


# Create windows tarballs
echo "Creating windows tarballs"
echo "** NSIS should take only the needed files, no need for this then"

