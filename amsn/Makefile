#
# $Id$
# Todo: This file is very BETA :) but it works for now :P
#       Need to include compiling of traydock, and copy the amsn.* menu files.
#

name=amsn
version=0.95
release=1a
module=msn

# Installation paths
prefix=/usr/local
exec_prefix=${prefix}
bindir=${exec_prefix}/bin
libdir=${prefix}/share/${name}
datadir=${prefix}/share/pixmaps
DOCDIR=${prefix}/share/doc/${name}-${version}
proot=${prefix}
pexec_prefix=${proot}
pbindir=${pexec_prefix}/bin
plibdir=${proot}/share/${name}
pdatadir=${proot}/share/pixmaps
pdocdir=${proot}/share/doc/${name}-${version}

transcript=uninstall.sh

# For integration with the current desktop
gnomelinks=/etc/X11/applnk/Internet
kdelinks=/usr/share/applnk/Internet
debianlinks=/usr/lib/menu
wmapps=${gnomelinks}
icon=messenger.png
desklink=amsn.desktop

all: install

mkdirs:
	mkdir -p $(libdir)
	mkdir -p $(datadir)
	mkdir -p $(wmapps)
	mkdir -p $(bindir)

installdoc:
	mkdir -p ${DOCDIR}
	cp -rp docs/ ${DOCDIR}


install: mkdirs installdoc
	@# Installing traydock
	@# cd plugins/traydock
	@# make && cd ..

	mkdir -p ${libdir}
	cp -a * ${libdir}

	@# Copy menu file.
	@# cp ${desklink} ${wmapps}

	@# Remove CVS directorys.
	@# find ${libdir} -type d -name CVS -exec rm -rf {} \;

	@# Installing pixmaps.
	mkdir -p ${pdatadir}
	cp -a icons/32x32/* ${pdatadir}

	ln -s ${libdir}/amsn ${bindir}

uninstall:
	rm -rf ${libdir}
	rm ${bindir}/amsn
