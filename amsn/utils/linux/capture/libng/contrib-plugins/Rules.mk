
# targets to build
TARGETS-contrib-plugins := \
	libng/contrib-plugins/flt-smooth.so

# global targets
ifeq ($(USE_LIBNG),yes)
all:: $(TARGETS-contrib-plugins)
endif

clean::
	rm -f $(TARGETS-contrib-plugins)

libng/contrib-plugins/flt-smooth.so:   libng/contrib-plugins/flt-smooth.o
