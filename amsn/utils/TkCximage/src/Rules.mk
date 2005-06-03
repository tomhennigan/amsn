OBJS-TkCximage := $(tkcximage_dir)/src/TkCximage.o $(tkcximage_dir)/src/PhotoFormat.o \
		  $(tkcximage_dir)/src/procs.o $(tkcximage_dir)/src/CxImage/libCxImage.a \
		 $(tkcximage_dir)/src/jpeg/libjpeg.a $(tkcximage_dir)/src/png/libpng.a \
		 $(tkcximage_dir)/src/zlib/libzlib.a

TARGETS-TkCximage := $(tkcximage_dir)/src/TkCximage.so 


$(TARGETS-TkCximage): $(OBJS-TkCximage)
	@$(echo_link_so)
	@$(link_so_cpp)

all:: $(TARGETS-TkCximage)

clean:: clean-tkcximage

clean-tkcximage::
	rm -f $(TARGETS-TkCximage) $(OBJS-TkCximage)
