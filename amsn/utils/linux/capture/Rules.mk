OBJS-capture := $(capture_dir)/capture.o $(capture_dir)/libng/libng.a
TARGETS-capture := $(capture_dir)/capture.so 


$(TARGETS-capture): $(OBJS-capture)


all:: $(TARGETS-capture)

check-capture: $(TARGETS-capture)
	wish $(capture_dir)/test.tcl


check:: check-capture

clean:: clean-capture

clean-capture:
	rm -f $(TARGETS-capture)

