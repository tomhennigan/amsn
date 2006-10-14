OBJS-siren := $(tcl_siren_dir)/src/tcl_siren.so
TARGETS-siren := $(tcl_siren_dir)/tcl_siren.so 


$(TARGETS-siren): $(OBJS-siren)
	cp $< $@


all:: $(TARGETS-siren)

clean:: clean-siren

clean-siren::
	rm -f $(TARGETS-siren) $(OBJS-siren)
