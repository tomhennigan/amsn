OBJS-tclCarbonNotification = $(macosx_dir)/tclCarbonNotification/src/tclCarbonNotification0.1.dylib
TARGETS-tclCarbonNotification = $(macosx_dir)/tclCarbonNotification/tclCarbonNotification0.1.dylib

all:: $(TARGETS-tclCarbonNotification)

$(TARGETS-tclCarbonNotification): $(OBJS-tclCarbonNotification)
	cp $< $@

clean:: clean-tclCarbonNotification
	
clean-tclCarbonNotification::
	rm -f $(OBJS-tclCarbonNotification) $(TARGETS-tclCarbonNotification)
