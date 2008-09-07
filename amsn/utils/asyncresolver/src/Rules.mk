
OBJS-asyncresolver = $(async_dir)/src/asyncresolver.o
TARGETS-asyncresolver = $(async_dir)/src/libasyncresolver.$(SHLIB_EXTENSION)

all:: $(TARGETS-asyncresolver)

$(TARGETS-asyncresolver): $(OBJS-asyncresolver)
	@$(echo_link_so)
	@$(link_so)

clean:: clean-asyncresolver
	
clean-asyncresolver::
	rm -f $(OBJS-asyncresolver) $(TARGET-asyncresolver)
