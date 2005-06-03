OBJS-Cximage := $(tkcximage_dir)/src/CxImage/ximadsp.o  $(tkcximage_dir)/src/CxImage/ximaexif.o  \
		$(tkcximage_dir)/src/CxImage/ximagif.o  $(tkcximage_dir)/src/CxImage/ximainfo.o  \
		$(tkcximage_dir)/src/CxImage/ximajpg.o  $(tkcximage_dir)/src/CxImage/ximalyr.o   \
		$(tkcximage_dir)/src/CxImage/ximapng.o  $(tkcximage_dir)/src/CxImage/ximatga.o   \
		$(tkcximage_dir)/src/CxImage/ximatran.o $(tkcximage_dir)/src/CxImage/ximabmp.o  \
		$(tkcximage_dir)/src/CxImage/ximaenc.o   $(tkcximage_dir)/src/CxImage/ximage.o   \
		$(tkcximage_dir)/src/CxImage/ximahist.o  $(tkcximage_dir)/src/CxImage/ximaint.o \
		$(tkcximage_dir)/src/CxImage/ximalpha.o $(tkcximage_dir)/src/CxImage/ximapal.o   \
		$(tkcximage_dir)/src/CxImage/ximasel.o  $(tkcximage_dir)/src/CxImage/ximath.o    \
		$(tkcximage_dir)/src/CxImage/xmemfile.o

TARGETS-Cximage := $(tkcximage_dir)/src/CxImage/libCxImage.a


$(TARGETS-Cximage): $(OBJS-Cximage)
	@$(echo_ar_lib)
	@$(ar_lib)

all:: $(TARGETS-Cximage)

clean::
	rm -f $(TARGETS-Cximage) $(OBJS-Cximage)
