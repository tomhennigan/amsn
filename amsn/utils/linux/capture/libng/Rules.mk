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
	$(capture_dir)/libng/misc.o

TARGET-libng := $(capture_dir)/libng/libng.so

V4L_CFLAGS=
ifeq ($(HAVE_LIBV4L),yes)
  V4L_CFLAGS += -DHAVE_LIBV4L
endif

$(OBJS-libng): CFLAGS+=-I$(capture_dir) $(V4L_CFLAGS) $(if $(strip ${LIBDIR}),-DLIBDIR=\"${LIBDIR}/$(capture_dir)/libng/plugins\",)
$(TARGET-libng): MORE_LIBS=-ldl

$(TARGET-libng): $(OBJS-libng)
	@$(echo_link_so)
	@$(link_so)

all:: $(TARGET-libng)

clean:: clean-libng

clean-libng:
	rm -f $(TARGET-libng) $(OBJS-libng)
