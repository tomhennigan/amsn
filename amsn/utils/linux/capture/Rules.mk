OBJS-capture := $(capture_dir)/capture.o $(capture_dir)/libng/libng.a
TARGETS-capture := $(capture_dir)/capture.so 

OBJS-capture-nong := $(capture_dir)/capture-nong.o
TARGETS-capture-nong := $(capture_dir)/capture-nong.so 

$(TARGETS-capture): $(OBJS-capture)
$(TARGETS-capture-nong): $(OBJS-capture-nong)


ifeq ($(USE_LIBNG),yes)
all:: $(TARGETS-capture)

check-capture: $(TARGETS-capture)
	wish $(capture_dir)/test.tcl

else
all:: $(TARGETS-capture-nong)
	cp $(TARGETS-capture-nong) $(TARGETS-capture)

check-capture: $(TARGETS-capture-nong)
	wish $(capture_dir)/test.tcl

endif

check:: check-capture

clean:: clean-capture

clean-capture:
	rm -f $(TARGETS-capture) $(TARGETS-capture-nong)

