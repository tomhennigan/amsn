OBJS-growl = $(macosx_dir)/growl1.0/src/libgrowl.dylib
TARGETS-growl = $(macosx_dir)/growl1.0/libgrowl.dylib

all:: $(TARGETS-growl)

$(TARGETS-growl): $(OBJS-growl)
	cp $< $@

clean:: clean-growl
	
clean-growl::
	rm -f $(OBJS-growl) $(TARGETS-growl)
