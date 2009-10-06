TARGETS-statusicon = $(macosx_dir)/statusicon/statusicon.dylib
OBJS-statusicon = $(macosx_dir)/statusicon/statusicon.c

LDFLAGS += -framework Cocoa

all:: $(TARGETS-statusicon)

$(TARGETS-statusicon): $(OBJS-statusicon)
	@$(echo_link_so)
	@$(link_so)

clean:: clean-statusicon
	
clean-statusicon::
	rm -f $(OBJS-statusicon) $(TARGET-statusicon)
