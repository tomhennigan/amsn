TARGETS-tclCarbonNotification = $(macosx_dir)/tclCarbonNotification/src/tclCarbonNotification0.1.dylib
OBJS-tclCarbonNotification = $(macosx_dir)/tclCarbonNotification/src/tclCarbonNotification.o

LDFLAGS += -framework CoreFoundation -framework Carbon -framework QuickTime

all:: $(TARGETS-tclCarbonNotification)

$(TARGETS-tclCarbonNotification): $(OBJS-tclCarbonNotification)
	@$(echo_link_so)
	@$(link_so)

clean:: clean-tclCarbonNotification

clean-growl::
	rm -f $(OBJS-tclCarbonNotification) $(TARGET-tclCarbonNotification)
