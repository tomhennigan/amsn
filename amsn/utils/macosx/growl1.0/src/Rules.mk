TARGETS-growl = $(macosx_dir)/growl1.0/src/libgrowl.dylib
OBJS-growl = $(macosx_dir)/growl1.0/src/GrowlPathUtil.o $(macosx_dir)/growl1.0/src/GrowlApplicationBridge.o $(macosx_dir)/growl1.0/src/CFGrowlAdditions.o $(macosx_dir)/growl1.0/src/TclGrowler.o $(macosx_dir)/growl1.0/src/growl.o $(macosx_dir)/growl1.0/src/NSURLAdditions.o

CFLAGS += --std=c99
LDFLAGS += -framework Cocoa

all:: $(TARGETS-growl)

$(TARGETS-growl): $(OBJS-growl)
	@$(echo_link_so)
	@$(link_so)

clean:: clean-growl	
	
clean-growl::
	rm -f $(OBJS-growl) $(TARGET-growl)
