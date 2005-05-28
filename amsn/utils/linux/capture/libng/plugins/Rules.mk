
# targets to build
TARGETS-plugins := \
	libng/plugins/flt-invert.so \
	libng/plugins/deinterlace.so \
	libng/plugins/conv-mjpeg.so \
	libng/plugins/conv-audio.so \
	libng/plugins/read-avi.so \
	libng/plugins/read-mpeg.so \
	libng/plugins/write-avi.so \
	libng/plugins/write-mpeg.so
# controls not settable yet ...
#	libng/plugins/flt-gamma.so \
#	libng/plugins/flt-disor.so \

ifeq ($(FOUND_LQT),yes)
TARGETS-plugins += \
	libng/plugins/read-qt.so \
	libng/plugins/write-qt.so
endif
ifeq ($(FOUND_DV),yes)
TARGETS-plugins += \
	libng/plugins/read-dv.so \
	libng/plugins/write-dv.so
endif
ifeq ($(FOUND_MPEG2),yes)
TARGETS-plugins += \
	libng/plugins/conv-mpeg.so
endif
ifeq ($(FOUND_ARTS),yes)
TARGETS-plugins += \
	libng/plugins/snd0-arts.so
endif
ifeq ($(FOUND_ALSA),yes)
TARGETS-plugins += \
	libng/plugins/snd1-alsa.so
endif

ifeq ($(FOUND_OS),linux)
TARGETS-plugins += \
	libng/plugins/drv0-v4l2.so \
	libng/plugins/drv1-v4l.so \
	libng/plugins/snd1-oss.so
endif
ifeq ($(FOUND_OS),bsd)
TARGETS-plugins += \
	libng/plugins/drv0-bsd.so \
	libng/plugins/snd1-oss.so
endif

GONE-plugins := \
	$(libdir)/invert.so \
	$(libdir)/nop.so \
	$(libdir)/flt-nop.so \
	$(libdir)/read-mp3.so

# extra cfrags
libng/plugins/snd0-arts.so  : CFLAGS += $(ARTS_FLAGS)

# libraries to link
libng/plugins/read-qt.so    : LDLIBS := $(QT_LIBS)
libng/plugins/write-qt.so   : LDLIBS := $(QT_LIBS)
libng/plugins/read-dv.so    : LDLIBS := $(DV_LIBS)
libng/plugins/write-dv.so   : LDLIBS := $(DV_LIBS)
libng/plugins/conv-audio.so : LDLIBS := $(MAD_LIBS)
libng/plugins/conv-mpeg.so  : LDLIBS := $(MPEG2_LIBS)
libng/plugins/snd0-arts.so  : LDLIBS := $(ARTS_LIBS)
libng/plugins/snd1-alsa.so  : LDLIBS := $(ALSA_LIBS)

# global targets
ifeq ($(USE_LIBNG),yes)
all:: $(TARGETS-plugins)
endif

clean::
	rm -f $(TARGETS-plugins)

libng/plugins/conv-mjpeg.so: libng/plugins/conv-mjpeg.o
libng/plugins/conv-audio.so: libng/plugins/conv-audio.o
libng/plugins/conv-mpeg.so:  libng/plugins/conv-mpeg.o
libng/plugins/drv0-bsd.so:   libng/plugins/drv0-bsd.o
libng/plugins/flt-debug.so:  libng/plugins/flt-debug.o
libng/plugins/flt-disor.so:  libng/plugins/flt-disor.o
libng/plugins/flt-gamma.so:  libng/plugins/flt-gamma.o
libng/plugins/flt-invert.so: libng/plugins/flt-invert.o
libng/plugins/deinterlace.so: libng/plugins/deinterlace.o
libng/plugins/read-avi.so:   libng/plugins/read-avi.o
libng/plugins/read-dv.so:    libng/plugins/read-dv.o
libng/plugins/read-qt.so:    libng/plugins/read-qt.o
libng/plugins/read-mpeg.so:  libng/plugins/read-mpeg.o
libng/plugins/snd0-arts.so:  libng/plugins/snd0-arts.o
libng/plugins/snd1-alsa.so:  libng/plugins/snd1-alsa.o
libng/plugins/snd1-oss.so:   libng/plugins/snd1-oss.o
libng/plugins/write-avi.so:  libng/plugins/write-avi.o
libng/plugins/write-mpeg.so: libng/plugins/write-mpeg.o
libng/plugins/write-dv.so:   libng/plugins/write-dv.o
libng/plugins/write-qt.so:   libng/plugins/write-qt.o

libng/plugins/drv0-v4l2.so: \
	libng/plugins/drv0-v4l2.o \
	libng/plugins/struct-v4l2.o \
	libng/plugins/struct-dump.o

libng/plugins/drv1-v4l.so: \
	libng/plugins/drv1-v4l.o \
	libng/plugins/struct-v4l.o \
	libng/plugins/struct-dump.o

libng/plugins/struct-dump.o: structs/struct-dump.c
	@$(echo_compile_c)
	@$(compile_c)
	@$(fixup_deps)

libng/plugins/struct-v4l.o: structs/struct-v4l.c
	@$(echo_compile_c)
	@$(compile_c)
	@$(fixup_deps)

libng/plugins/struct-v4l2.o: structs/struct-v4l2.c
	@$(echo_compile_c)
	@$(compile_c)
	@$(fixup_deps)
