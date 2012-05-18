OBJS-tcl_farsight := $(tcl_farsight_dir)/src/tcl_farsight.o
TARGETS-tcl_farsight := $(tcl_farsight_dir)/src/tcl_farsight.$(SHLIB_EXTENSION) 

$(OBJS-tcl_farsight): CFLAGS += ${FARSIGHT2_CFLAGS}

$(TARGETS-tcl_farsight): LDFLAGS += ${FARSIGHT2_LIBS}

all:: $(TARGETS-tcl_farsight)

clean:: clean-tcl_farsight

clean-tcl_farsight::
	rm -f $(TARGETS-tcl_farsight) $(OBJS-tcl_farsight)

