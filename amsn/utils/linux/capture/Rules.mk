OBJS-capture := capture.o libng/libng.a
TARGETS-capture := capture.so 

OBJS-capture-nong := capture-nong.o
TARGETS-capture-nong := capture-nong.so 

$(TARGETS-capture): $(OBJS-capture)
$(TARGETS-capture-nong): $(OBJS-capture-nong)


ifeq ($(USE_LIBNG),yes)
all:: $(TARGETS-capture)
else
all:: $(TARGETS-capture-nong)
	cp $(TARGETS-capture-nong) $(TARGETS-capture)
endif


clean::
	rm -f $(TARGETS-capture) $(TARGETS-capture-nong)
