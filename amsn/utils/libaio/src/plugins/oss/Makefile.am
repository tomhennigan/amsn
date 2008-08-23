AUTOMAKE_OPTIONS = foreign

if HAVE_OSS

ossltlibs = libaio_oss.la
osssources = aio_oss.c

else

ossltlibs =
osssources =

endif
INCLUDES = -I$(top_builddir)/include/aio -I$(top_srcdir)/include -I$(top_srcdir)/src
libdir = $(plugindir)
lib_LTLIBRARIES = $(ossltlibs)

libaio_oss_la_LDFLAGS = @PLUGIN_LDFLAGS@
libaio_oss_la_SOURCES = $(osssources)
EXTRA_DIST = aio_oss.c
