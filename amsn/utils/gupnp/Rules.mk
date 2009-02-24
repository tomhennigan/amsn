OBJS-gupnp := $(gupnp_dir)/gupnp.o
TARGETS-gupnp := $(gupnp_dir)/gupnp.$(SHLIB_EXTENSION) 

all:: $(TARGETS-gupnp)

clean:: clean-gupnp

clean-gupnp::
	rm -f $(TARGETS-gupnp) $(OBJS-tcl_gupnp)

