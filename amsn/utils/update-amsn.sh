#!/bin/bash
##############################################################################
#This is a simple script to update aMsn from CVS and link
#the skins in amsn-extras directory right.
#
#Rafael Rodríguez. apt-drink@telefonica.net
#
#v0.1: 18/01/03
##############################################################################

AMSNPATH=~/coding/msn
EXTRASPATH=~/coding/msn/amsn-extras

cd ${AMSNPATH}
echo "Updating amsn..."
cvs -f -q update -d -P "."
cd ${EXTRASPATH}
echo "Updating amsn-extras..."
cvs -f -q update -d -P "."

cd ${EXTRASPATH}/skins
for SKIN in *
do
	if [ $SKIN != "CVS" ]; then
		if [ ! -e "${AMSNPATH}/skins/${SKIN}" ]; then	#Link already exists?
			echo "Linking skin ${SKIN}..."
			ln -s ${EXTRASPATH}/skins/${SKIN} ${AMSNPATH}/skins/${SKIN}
		else
			echo "Not linking skin ${SKIN}. Link already exists..."
		fi
	fi
done
		
