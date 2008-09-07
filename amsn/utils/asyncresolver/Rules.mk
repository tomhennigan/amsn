
OBJS-asyncresolver = $(async_dir)/src/libasyncresolver.$(SHLIB_EXTENSION)
TARGETS-asyncresolver = $(async_dir)/libasyncresolver.$(SHLIB_EXTENSION)

all:: $(TARGETS-asyncresolver)

$(TARGETS-asyncresolver): $(OBJS-asyncresolver)
	cp $< $@

clean:: clean-asyncresolver
	
clean-asyncresolver::
	rm -f $(OBJS-asyncresolver) $(TARGETS-asyncresolver)
