# targets to build
TARGETS-plugins := $(capture_dir)/libng/plugins/conv-mjpeg.so
TARGETS-plugins += $(patsubst %,$(capture_dir)/libng/plugins/%.so,${LIBNG_PLUGINS})

# global targets
all:: $(TARGETS-plugins)

clean:: clean-plugins

clean-plugins:
	rm -f $(TARGETS-plugins) $(capture_dir)/libng/plugins/*.o

$(TARGETS-plugins): CFLAGS+=$(V4L_CFLAGS) -I$(capture_dir) -I$(capture_dir)/libng -I$(capture_dir)/structs
$(TARGETS-plugins): LDFLAGS+=$(foreach rp,$(RPATH),"-Wl,-rpath=$(rp)/$(capture_dir)/libng")
$(TARGETS-plugins): MORE_LIBS=-L$(capture_dir)/libng -lng

$(TARGETS-plugins): | $(capture_dir)/libng/libng.so

$(capture_dir)/libng/plugins/drv0-v4l2.so: \
	$(capture_dir)/libng/plugins/drv0-v4l2.o \
	$(capture_dir)/libng/plugins/struct-v4l2.o \
	$(capture_dir)/libng/plugins/struct-dump.o
	@$(echo_link_so)
	@$(link_so)

$(capture_dir)/libng/plugins/drv1-v4l.so: \
	$(capture_dir)/libng/plugins/drv1-v4l.o \
	$(capture_dir)/libng/plugins/struct-v4l.o \
	$(capture_dir)/libng/plugins/struct-dump.o
	@$(echo_link_so)
	@$(link_so)

$(capture_dir)/libng/plugins/struct-dump.o: $(capture_dir)/structs/struct-dump.c
	@$(echo_compile_c)
	@$(compile_c)

$(capture_dir)/libng/plugins/struct-v4l.o: $(capture_dir)/structs/struct-v4l.c
	@$(echo_compile_c)
	@$(compile_c)

$(capture_dir)/libng/plugins/struct-v4l2.o: $(capture_dir)/structs/struct-v4l2.c
	@$(echo_compile_c)
	@$(compile_c)
