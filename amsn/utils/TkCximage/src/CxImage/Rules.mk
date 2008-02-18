OBJS-Cximage := $(tkcximage_dir)/src/CxImage/ximadsp.cpp.o  $(tkcximage_dir)/src/CxImage/ximaexif.cpp.o  \
		$(tkcximage_dir)/src/CxImage/ximagif.cpp.o  $(tkcximage_dir)/src/CxImage/ximainfo.cpp.o  \
		$(tkcximage_dir)/src/CxImage/ximajpg.cpp.o  $(tkcximage_dir)/src/CxImage/ximalyr.cpp.o   \
		$(tkcximage_dir)/src/CxImage/ximapng.cpp.o  $(tkcximage_dir)/src/CxImage/ximatga.cpp.o   \
		$(tkcximage_dir)/src/CxImage/ximatran.cpp.o $(tkcximage_dir)/src/CxImage/ximabmp.cpp.o  \
		$(tkcximage_dir)/src/CxImage/ximaenc.cpp.o   $(tkcximage_dir)/src/CxImage/ximage.cpp.o   \
		$(tkcximage_dir)/src/CxImage/ximahist.cpp.o  $(tkcximage_dir)/src/CxImage/ximaint.cpp.o \
		$(tkcximage_dir)/src/CxImage/ximalpha.cpp.o $(tkcximage_dir)/src/CxImage/ximapal.cpp.o   \
		$(tkcximage_dir)/src/CxImage/ximasel.cpp.o  $(tkcximage_dir)/src/CxImage/ximath.cpp.o    \
		$(tkcximage_dir)/src/CxImage/xmemfile.cpp.o

TARGETS-Cximage := $(tkcximage_dir)/src/CxImage/libCxImage.a


$(TARGETS-Cximage): $(OBJS-Cximage)
	@$(echo_ar_lib)
	@$(ar_lib)

all:: $(TARGETS-Cximage)

clean::
	rm -f $(TARGETS-Cximage) $(OBJS-Cximage)
