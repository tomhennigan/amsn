OBJS-tclISF := $(tclISF_dir)/src/tclISF.o $(tclISF_dir)/src/libISF/libISF.a

TARGETS-tclISF := $(tclISF_dir)/src/tclISF.$(SHLIB_EXTENSION)

$(TARGETS-tclISF):: $(OBJS-tclISF)

all:: $(TARGETS-tclISF)

clean:: clean-tclISF

clean-tclISF::
	rm -f $(TARGETS-tclISF) $(OBJS-tclISF)
