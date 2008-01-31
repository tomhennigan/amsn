OBJS-webcamsn := $(webcamsn_dir)/src/webcamsn.$(SHLIB_EXTENSION)
TARGETS-webcamsn := $(webcamsn_dir)/webcamsn.$(SHLIB_EXTENSION) 


$(TARGETS-webcamsn): $(OBJS-webcamsn)
	cp $< $@


all:: $(TARGETS-webcamsn)


check:: check-webcamsn

check-webcamsn:
	wish $(webcamsn_dir)/webcamsn.tcl

clean:: clean-webcamsn

clean-webcamsn::
	rm -f $(TARGETS-webcamsn) $(OBJS-webcamsn)
