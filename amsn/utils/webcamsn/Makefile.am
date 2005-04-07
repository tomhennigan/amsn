SUBDIRS = src doc

### all of the standard pc files we need to generate
pcfiles = 							\
	libmimic.pc

all-local: $(pcfiles)

pkgconfigdir = $(libdir)/pkgconfig
pkgconfig_DATA = $(pcfiles)

EXTRA_DIST =							\
	libmimic.pc.in

CLEANFILES = $(pcfiles)
