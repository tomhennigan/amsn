#!/bin/bash

TAG='Release-0_98_3'
VERSION='0.98.3'
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
svn export https://amsn.svn.sourceforge.net/svnroot/amsn/trunk/amsn-extras/plugins/ $DIR_NAME/plugins  >  /dev/null

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
echo "NOT YET SUPPORTED"

# Create windows  tarballs
echo "Creating windows tarballs"
echo "NOT YET SUPPORTED"

# Create mac tarballs
echo "Creating mac tarballs"
echo "NOT YET SUPPORTED"

