OBJS-libISF := $(tclISF_dir)/src/libISF/compression.o  $(tclISF_dir)/src/libISF/createTags.o  \
		$(tclISF_dir)/src/libISF/decodeTags.o  $(tclISF_dir)/src/libISF/decompression.o  \
		$(tclISF_dir)/src/libISF/decProperty.o  $(tclISF_dir)/src/libISF/encoding.o   \
		$(tclISF_dir)/src/libISF/libISF.o  $(tclISF_dir)/src/libISF/read.o

TARGETS-libISF := $(tclISF_dir)/src/libISF/libISF.a


$(TARGETS-libISF): $(OBJS-libISF)
	@$(echo_ar_lib)
	@$(ar_lib)

all:: $(TARGETS-libISF)

clean::
	rm -f $(TARGETS-libISF) $(OBJS-libISF)
