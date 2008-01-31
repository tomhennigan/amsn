OBJS-tclCarbonHICommand = $(macosx_dir)/tclCarbonHICommand/src/tclCarbonHICommand0.1.dylib
TARGETS-tclCarbonHICommand = $(macosx_dir)/tclCarbonHICommand/tclCarbonHICommand0.1.dylib

all:: $(TARGETS-tclCarbonHICommand)

$(TARGETS-tclCarbonHICommand): $(OBJS-tclCarbonHICommand)
	cp $< $@

clean:: clean-tclCarbonHICommand
	
clean-tclCarbonHICommand::
	rm -f $(OBJS-tclCarbonHICommand) $(TARGETS-tclCarbonHICommand)
