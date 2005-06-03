OBJS-webcamsn := $(webcamsn_dir)/src/webcamsn.so
TARGETS-webcamsn := $(webcamsn_dir)/webcamsn.so 


$(TARGETS-webcamsn): $(OBJS-webcamsn)
	cp $< $@


all:: $(TARGETS-webcamsn)


check:: check-webcamsn

check-webcamsn:
	wish $(webcamsn_dir)/webcamsn.tcl

clean:: clean-webcamsn

clean-webcamsn::
	rm -f $(TARGETS-webcamsn) $(OBJS-webcamsn)
