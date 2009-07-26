OBJS-tclISF := $(tclISF_dir)/src/tclISF.cpp.o $(tclISF_dir)/src/libISF/libISF.a $(tkcximage_dir)/src/CxImage/libCxImage.a

ifeq ($(FOUND_OS),mac)
  EXTRAOBJS-tclISF := $(prefix)/lib/libpng.a $(prefix)/lib/libjpeg.a
endif


TARGETS-tclISF := $(tclISF_dir)/src/tclISF.cpp.$(SHLIB_EXTENSION)

$(TARGETS-tclISF):: $(OBJS-tclISF) $(EXTRAOBJS-tclISF)

all:: $(TARGETS-tclISF)

clean:: clean-tclISF

clean-tclISF::
	rm -f $(TARGETS-tclISF) $(OBJS-tclISF)
