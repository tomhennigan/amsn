OBJS-tclCarbon = $(macosx_dir)/tclCarbon/src/tclCarbon.dylib
TARGETS-tclCarbon = $(macosx_dir)/tclCarbon/tclCarbon.dylib

all:: $(TARGETS-tclCarbon)

$(TARGETS-tclCarbon): $(OBJS-tclCarbon)
	cp $< $@

clean:: clean-tclCarbon
	
clean-tclCarbon::
	rm -f $(OBJS-tclCarbon) $(TARGETS-tclCarbon)
