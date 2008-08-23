
EXTRA_DIST= doxygen.cfg

INCLUDES=-I$(top_srcdir)/include

doc:
	doxygen doxygen.cfg

doc-pack: doc
	-chmod a+r $(top_srcdir)/doc/doxygen/html/*
	-chmod a-w $(top_srcdir)/doc/doxygen/html/*
	if ! test -z "$(AMTAR)"; then \
	$(AMTAR) --create --directory=$(top_srcdir)/doc/doxygen/html --verbose --file=- . | bzip2 -c -9 > $(top_srcdir)/../alsa-lib-doc.tar.bz2 ; \
	else \
		$(TAR) --create --directory=$(top_srcdir)/doc/doxygen/html --verbose --file=- . | bzip2 -c -9 > $(top_srcdir)/../alsa-lib-doc.tar.bz2 ; \
	fi
										        rm -f $(top_srcdir)/doc/doxygen/html/*

doc-clean:
	rm -fr $(top_srcdir)/doc/doxygen/
