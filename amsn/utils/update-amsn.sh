#!/bin/bash
##############################################################################
#This is a simple script to update aMsn from CVS and link
#the skins in amsn-extras directory right.
#
#Rafael Rodríguez. apt-drink@telefonica.net
#
#v0.1: 18/01/03
##############################################################################

AMSNPATH=~/amsn
EXTRASPATH=~/amsn/amsn-extras

cd ${AMSNPATH}
echo "Updating amsn..."
svn update
if [ -d ${EXTRASPATH} ]; then
	cd ${EXTRASPATH}
	echo "Updating amsn-extras..."
	svn update
fi


