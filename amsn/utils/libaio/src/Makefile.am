#process this file with automake to produce Makefile.in

AUTOMAKE_OPTIONS = foreign
SUBDIRS = plugins

INCLUDES = -I$(top_builddir)/include/aio -I$(top_srcdir)/include -DAIO_PLUGIN_PATH=\"@plugindir@\"

lib_LTLIBRARIES = libaio.la

wmm=

libaio_la_SOURCES = aio.c aio_null.c format.c aio_internal.h $(wmm)
libaio_la_LDFLAGS = @LIBAIO_LA_LDFLAGS@ -version-info @LIB_CURRENT@:@LIB_REVISION@:@LIB_AGE@


debug:
	$(MAKE) all CFLAGS="@DEBUG@"

profile:
	$(MAKE) all CFLAGS="@PROFILE@"


