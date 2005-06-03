OBJS-libng := \
	$(capture_dir)/libng/grab-ng.o \
	$(capture_dir)/libng/devices.o \
	$(capture_dir)/libng/writefile.o \
	$(capture_dir)/libng/parse-mpeg.o \
	$(capture_dir)/libng/parse-dvb.o \
	$(capture_dir)/libng/color_common.o \
	$(capture_dir)/libng/color_packed.o \
	$(capture_dir)/libng/color_lut.o \
	$(capture_dir)/libng/color_yuv2rgb.o \
	$(capture_dir)/libng/convert.o \
	$(capture_dir)/libng/misc.o \
	$(TARGETS-plugins)

TARGET-libng := $(capture_dir)/libng/libng.a

$(TARGET-libng): $(OBJS-libng)
	@$(echo_ar_lib)
	@$(ar_lib)

ifeq ($(USE_LIBNG),yes)
all:: $(TARGET-libng)
endif

clean:: clean-libng

clean-libng:
	rm -f $(TARGET-libng) $(OBJS-libng)
