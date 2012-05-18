OBJS-gupnp := $(gupnp_dir)/gupnp.o
TARGETS-gupnp := $(gupnp_dir)/gupnp.$(SHLIB_EXTENSION)

$(OBJS-gupnp): CFLAGS+=${GUPNP_CFLAGS}
$(TARGETS-gupnp): MORE_LIBS=${GUPNP_LIBS}

all:: $(TARGETS-gupnp)

clean:: clean-gupnp

clean-gupnp::
	rm -f $(TARGETS-gupnp) $(OBJS-gupnp)

