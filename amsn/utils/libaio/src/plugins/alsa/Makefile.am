AUTOMAKE_OPTIONS = foreign

if HAVE_OSS

alsaltlibs = libaio_alsa.la
alsasources = aio_alsa.c

else

alsaltlibs =
alsasources =

endif
INCLUDES = -I$(top_builddir)/include/aio -I$(top_srcdir)/include -I$(top_srcdir)/src
libdir = $(plugindir)
lib_LTLIBRARIES = $(alsaltlibs)

libaio_alsa_la_LDFLAGS = @PLUGIN_LDFLAGS@
libaio_alsa_la_LIBADD = @ALSA_LIBS@
libaio_alsa_la_SOURCES = $(alsasources)

EXTRA_DIST = aio_alsa.c
