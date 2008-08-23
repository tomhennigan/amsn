## Process this file with automake to produce Makefile.in

AUTOMAKE_OPTIONS = foreign 1.6 dist-zip
ACLOCAL_AMFLAGS = -I m4
SUBDIRS = src include doc test tcl

m4datadir = $(datadir)/aclocal
m4data_DATA = m4/aio.m4

pkgconfigdir = $(libdir)/pkgconfig
pkgconfig_DATA = aio.pc

#man_MANS = libao.conf.5

EXTRA_DIST = README AUTHORS CHANGES COPYING libaio.spec aio.m4 acinclude.m4 aio.pc.in $(man_MANS)
libtool: $(LIBTOOL_DEPS)
	$(SHELL) ./config.status --recheck

debug:
	$(MAKE) all CFLAGS="@DEBUG@"

profile:
	$(MAKE) all CFLAGS="@PROFILE@"


doc-dummy :
	
doc: doc-dummy
	$(MAKE) -C include all
	$(MAKE) -C doc doc

