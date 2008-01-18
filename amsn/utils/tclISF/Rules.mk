OBJS-tclISF := $(tclISF_dir)/src/tclISF.so
TARGETS-tclISF := $(tclISF_dir)/tclISF.so 


$(TARGETS-tclISF): $(OBJS-tclISF)
	cp $< $@

all:: $(TARGETS-tclISF)

clean:: clean-tclISF

clean-tclISF::
	rm -f $(TARGETS-tclISF) $(OBJS-tclISF)
