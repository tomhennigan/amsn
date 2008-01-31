TARGETS-tclCarbonHICommand = $(macosx_dir)/tclCarbonHICommand/src/tclCarbonHICommand0.1.dylib
OBJS-tclCarbonHICommand = $(macosx_dir)/tclCarbonHICommand/src/tclCarbonHICommand.o

LDFLAGS += -framework CoreFoundation -framework Carbon -framework QuickTime

all:: $(TARGETS-tclCarbonHICommand)

$(TARGETS-tclCarbonHICommand): $(OBJS-tclCarbonHICommand)
	@$(echo_link_so)
	@$(link_so)

clean:: clean-tclCarbonHICommand

clean-growl::
	rm -f $(OBJS-tclCarbonHICommand) $(TARGET-tclCarbonHICommand)
