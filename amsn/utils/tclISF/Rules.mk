OBJS-tclISF := $(tclISF_dir)/src/tclISF.$(SHLIB_EXTENSION)
TARGETS-tclISF := $(tclISF_dir)/tclISF.$(SHLIB_EXTENSION) 


$(TARGETS-tclISF): $(OBJS-tclISF)
	cp $< $@

all:: $(TARGETS-tclISF)

clean:: clean-tclISF

clean-tclISF::
	rm -f $(TARGETS-tclISF) $(OBJS-tclISF)
