OBJS-farsight := $(tcl_farsight_dir)/src/tcl_farsight.$(SHLIB_EXTENSION)
TARGETS-farsight := $(tcl_farsight_dir)/tcl_farsight.$(SHLIB_EXTENSION) 

ifeq (${HAVE_FARSTREAM},yes)
  $(OBJS-farsight): CFLAGS+=-DHAVE_FARSTREAM
else
  ifeq (${HAVE_FARSIGHT},yes)
    $(OBJS-farsight): CFLAGS+=-DHAVE_FARSIGHT
  endif
endif

$(TARGETS-farsight): $(OBJS-farsight)
	cp $< $@


all:: $(TARGETS-farsight)

clean:: clean-farsight

clean-farsight::
	rm -f $(TARGETS-farsight) $(OBJS-farsight)
