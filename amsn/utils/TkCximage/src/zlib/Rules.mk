OBJS-zlib := 	$(tkcximage_dir)/src/zlib/adler32.o  $(tkcximage_dir)/src/zlib/compress.o  \
		$(tkcximage_dir)/src/zlib/crc32.o  $(tkcximage_dir)/src/zlib/deflate.o  \
		$(tkcximage_dir)/src/zlib/gzio.o  $(tkcximage_dir)/src/zlib/infback.o \
	     	$(tkcximage_dir)/src/zlib/inffast.o  $(tkcximage_dir)/src/zlib/inflate.o  \
		$(tkcximage_dir)/src/zlib/inftrees.o  $(tkcximage_dir)/src/zlib/trees.o  \
		$(tkcximage_dir)/src/zlib/uncompr.o  $(tkcximage_dir)/src/zlib/zutil.o

TARGETS-zlib := $(tkcximage_dir)/src/zlib/libzlib.a


$(TARGETS-zlib): $(OBJS-zlib)
	@$(echo_ar_lib)
	@$(ar_lib)

all:: $(TARGETS-zlib)

clean::
	rm -f $(TARGETS-zlib) $(OBJS-zlib)
