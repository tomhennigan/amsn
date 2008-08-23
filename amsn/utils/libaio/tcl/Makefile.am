#process this file with automake to produce Makefile.in

AUTOMAKE_OPTIONS = foreign

INCLUDES = -I$(top_builddir)/include/aio -I$(top_srcdir)/include

pkglib_LTLIBRARIES = libtclaio.la

libtclaio_la_SOURCES = tclaio.c $(top_builddir)/src/libaio.la
libtclaio_la_LDFLAGS = @TCL_STUB_LIB_SPEC@
libtclaio_la_CFLAGS = @TCL_INC_SPEC@
libtclaio_la_LIBADD = $(top_builddir)/src/libaio.la

install-data-local:
	$(mkinstalldirs) $(DESTDIR)$(pkglibdir)
	cp tclaio.tcl $(DESTDIR)$(pkglibdir)
	cp pkgIndex.tcl $(DESTDIR)$(pkglibdir)
	cp aio_play $(DESTDIR)$(bindir)

