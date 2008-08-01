OBJS-tcl_farsight := $(tcl_farsight_dir)/src/tcl_farsight.o
TARGETS-tcl_farsight := $(tcl_farsight_dir)/src/tcl_farsight.$(SHLIB_EXTENSION) 

$(OBJS-tcl_farsight): $(tcl_farsight_dir)/src/tcl_farsight.c
	@$(echo_compile_farsight)
	@$(compile_farsight)

$(TARGETS-tcl_farsight): $(OBJS-tcl_farsight)
	@$(echo_link_farsight)
	@$(link_farsight)

all:: $(TARGETS-tcl_farsight)

clean:: clean-tcl_farsight

clean-tcl_farsight::
	rm -f $(TARGETS-tcl_farsight) $(OBJS-tcl_farsight)

