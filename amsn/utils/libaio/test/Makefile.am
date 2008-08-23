
AUTOMAKE_OPTIONS = foreign 

aio_example_sources = aio_example.c

INCLUDES = -I$(top_builddir)/include/aio -I$(top_srcdir)/include
aio_example_LDADD = ../src/libaio.la ../src/plugins/oss/libaio_oss.la ../src/plugins/alsa/libaio_alsa.la
check_PROGRAMS = aio_example
aio_example_SOURCES = $(aio_example_sources)
aio_example_PROGRAM = aio_example
TESTS = $(check_PROGRAMS)
bin_PROGRAMS= aio_example
debug:
	$(MAKE) all CFLAGS="@DEBUG@"
