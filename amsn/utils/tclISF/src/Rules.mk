OBJS-tclISF := $(tclISF_dir)/src/tclISF.cpp.o $(tclISF_dir)/src/libISF/libISF.a $(tkcximage_dir)/src/CxImage/libCxImage.a

TARGETS-tclISF := $(tclISF_dir)/src/tclISF.cpp.$(SHLIB_EXTENSION)

$(tclISF_dir)/src/tclISF.cpp.o: CXXFLAGS+=-I$(tkcximage_dir)/src/CxImage

$(TARGETS-tclISF): $(OBJS-tclISF) $(STATIC_PNG_JPEG)

all:: $(TARGETS-tclISF)

clean:: clean-tclISF

clean-tclISF::
	rm -f $(TARGETS-tclISF) $(OBJS-tclISF)
