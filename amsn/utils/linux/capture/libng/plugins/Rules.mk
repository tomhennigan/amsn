
# targets to build
TARGETS-plugins := 
ifeq ($(FOUND_OS),linux)
TARGETS-plugins += \
	$(capture_dir)/libng/plugins/drv0-v4l2.so \
	$(capture_dir)/libng/plugins/drv1-v4l.so
endif
ifeq ($(FOUND_OS),bsd)
TARGETS-plugins += \
	$(capture_dir)/libng/plugins/drv0-bsd.so 
endif

# global targets
ifeq ($(USE_LIBNG),yes)
all:: $(TARGETS-plugins)
endif

clean:: clean-plugins

clean-plugins:
	rm -f $(TARGETS-plugins)

$(capture_dir)/libng/plugins/drv0-bsd.so:   $(capture_dir)/libng/plugins/drv0-bsd.o

$(capture_dir)/libng/plugins/drv0-v4l2.so: \
	$(capture_dir)/libng/plugins/drv0-v4l2.o \
	$(capture_dir)/libng/plugins/struct-v4l2.o \
	$(capture_dir)/libng/plugins/struct-dump.o

$(capture_dir)/libng/plugins/drv1-v4l.so: \
	$(capture_dir)/libng/plugins/drv1-v4l.o \
	$(capture_dir)/libng/plugins/struct-v4l.o \
	$(capture_dir)/libng/plugins/struct-dump.o

$(capture_dir)/libng/plugins/struct-dump.o: $(capture_dir)/structs/struct-dump.c
	@$(echo_compile_c)
	@$(compile_c)
	@$(fixup_deps)

$(capture_dir)/libng/plugins/struct-v4l.o: $(capture_dir)/structs/struct-v4l.c
	@$(echo_compile_c)
	@$(compile_c)
	@$(fixup_deps)

$(capture_dir)/libng/plugins/struct-v4l2.o: $(capture_dir)/structs/struct-v4l2.c
	@$(echo_compile_c)
	@$(compile_c)
	@$(fixup_deps)
