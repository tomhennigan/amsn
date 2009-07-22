OBJS-tclISF := $(tclISF_dir)/src/tclISF.cpp.o $(tclISF_dir)/src/libISF/libISF.a $(tkcximage_dir)/src/CxImage/libCxImage.a

TARGETS-tclISF := $(tclISF_dir)/src/tclISF.cpp.$(SHLIB_EXTENSION)

$(TARGETS-tclISF):: $(OBJS-tclISF)

all:: $(TARGETS-tclISF)

clean:: clean-tclISF

clean-tclISF::
	rm -f $(TARGETS-tclISF) $(OBJS-tclISF)
