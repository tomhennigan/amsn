#
# $Id$
#
# TODO
#	- integrate to both kde & gnome, check if existing
name=amsn
version=0.60
release=1
module=msn

# Installation paths
prefix=/usr
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

SUBDIRS=i s lang
transcript=uninstall.sh

# For integration with the current desktop
gnomelinks=/etc/X11/applnk/Internet
kdelinks=/usr/share/applnk/Internet
wmapps=${gnomelinks}
icon=messenger.png
desklink=amsn.desktop

# Items to be installed
docs= LEEME TODO changelog

# From sandbox do:
# 1) make install prefix=<ROOT> version=<VERSION> wmapps=blahblash
# 2) make tar
# Then assuming the spec file & tar file are into the RPM tree
# 3)  rpm -bb --target noarch --clean amsn.spec
all: install

mkdirs:
	echo "LIB $(libdir) DATA $(datadir) BIN $(bindir)" 
	mkdir -p $(libdir)
	mkdir -p $(datadir)
	mkdir -p $(wmapps)
	mkdir -p $(bindir)

installdoc:
	mkdir -p ${DOCDIR}
	cp ${docs} ${DOCDIR}

uninstallold:
	rm -f  ${DOCDIR}
	rm -f  ${libdir}/i/*
	rm -f  ${libdir}/sounds/*
	rm -f  ${wmapps}/${desklink}
	rm -f  ${datadir}/${icon}

newtranscript:
	cat /dev/null > .${transcript}

# Install everything in subdirectories (sounds,images,languages)
installsubdirs:
	@list='$(SUBDIRS)'; for subdir in $$list; do \
		mydir=$(libdir)/$$subdir; \
		mkdir -p $$mydir; \
		files=`ls $$subdir`; for myfile in $$files; do \
		  if [ ! -d $$myfile ]; then \
		    srcfile=$$subdir/$$myfile; \
		    dstfile=$$mydir; \
		    cp $$srcfile $$dstfile; \
		    echo "rm -f $$dstfile/$$myfile" >> .$(transcript); \
		  fi; \
		done; \
		echo "rmdir -f $$mydir" >> .$(transcript); \
		done; \

# Install core files from root directory
install: mkdirs newtranscript installsubdirs 
	@core=`ls langlist README *tcl *htm*`; for corefile in $$core; do \
		myfile=$(libdir)/$$corefile; \
		cp $$corefile $(libdir); \
		echo "rm -f $$myfile" >> .$(transcript); \
		done; \
		cp i/$(icon) $(datadir)/$(icon); \
		echo "rm -f $(datadir)/$(icon)" >> .$(transcript); \
		cp $(desklink) $(wmapps); \
		echo "rm -f $(wmapps)/$(desklink)" >> .$(transcript)
#		ln -sf $(libdir)/i/$(icon) $(datadir)/$(icon)
	@cp .$(transcript) $(libdir)/$(transcript)
#	Now we install the executable in the binary directory
#	@ln -sf $(libdir)/${name} $(bindir)/${name}
	@cp amsn $(bindir)/amsn
	@echo "rm -f $(bindir)/amsn" >> .$(transcript)
#	cat .$(transcript)

# WARNING: This target is only used when installing a tarball. When
#	   distributed in an RPM this uninstall transcript must NOT
#	   be executed!.
uninstall:
#	@echo "sh $(libdir)/$(transcript)"
	sh $(libdir)/$(transcript)

tar:
	(cd ..; ln -s ${module} ${name}-${version}; tar --exclude=CVS* --dereference -czvf /tmp/${name}-${version}-${release}.tar.gz ${name}-${version}; rm -f ${name}-${version}; cd -)

