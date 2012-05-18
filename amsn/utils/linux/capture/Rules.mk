OBJS-capture := $(capture_dir)/capture.o
TARGETS-capture := $(capture_dir)/capture.so 

$(OBJS-capture): CFLAGS+=-I$(capture_dir) -I$(capture_dir)/libng
$(TARGETS-capture): MORE_LIBS=-L$(capture_dir)/libng -lng

$(TARGETS-capture): $(OBJS-capture) | $(capture_dir)/libng/libng.so


all:: $(TARGETS-capture)

check-capture: $(TARGETS-capture)
	wish $(capture_dir)/test.tcl


check:: check-capture

clean:: clean-capture

clean-capture:
	rm -f $(OBJS-capture) $(TARGETS-capture)

