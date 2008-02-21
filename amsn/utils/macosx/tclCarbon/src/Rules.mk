TARGETS-tclCarbon = $(macosx_dir)/tclCarbon/src/tclCarbon.dylib
OBJS-tclCarbon = $(macosx_dir)/tclCarbon/src/tclCarbonHICommand.o $(macosx_dir)/tclCarbon/src/tclCarbonNotification.o $(macosx_dir)/tclCarbon/src/tclCarbon.o

CFLAGS	+= -DMAC_OSX_TK=1
LDFLAGS += -framework CoreFoundation -framework Carbon -framework QuickTime

all:: $(TARGETS-tclCarbon)

$(TARGETS-tclCarbon): $(OBJS-tclCarbon)
	@$(echo_link_so)
	@$(link_so)

clean:: clean-tclCarbon

clean-tclCarbon::
	rm -f $(OBJS-tclCarbon) $(TARGET-tclCarbon)
