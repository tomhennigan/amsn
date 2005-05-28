OBJS-libng := \
	libng/grab-ng.o \
	libng/devices.o \
	libng/writefile.o \
	libng/parse-mpeg.o \
	libng/parse-dvb.o \
	libng/color_common.o \
	libng/color_packed.o \
	libng/color_lut.o \
	libng/color_yuv2rgb.o \
	libng/convert.o \
	libng/misc.o


libng/libng.a: $(OBJS-libng)
	@$(echo_ar_lib)
	@$(ar_lib)


ifeq ($(USE_LIBNG),yes)
all:: libng/libng.a
endif

clean::
	rm -f libng.a
