OBJS-siren := $(tcl_siren_dir)/src/tcl_siren.$(SHLIB_EXTENSION)
TARGETS-siren := $(tcl_siren_dir)/tcl_siren.$(SHLIB_EXTENSION) 


$(TARGETS-siren): $(OBJS-siren)
	cp $< $@


all:: $(TARGETS-siren)

clean:: clean-siren

clean-siren::
	rm -f $(TARGETS-siren) $(OBJS-siren)
