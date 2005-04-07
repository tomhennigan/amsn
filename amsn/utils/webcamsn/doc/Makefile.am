EXTRA_DIST = Doxyfile.in

if LIBMIMIC_DOXYGEN_DOCS_ENABLED
all-local: dox

dox: Doxyfile
	-rm -rf api/
	doxygen Doxyfile
endif

