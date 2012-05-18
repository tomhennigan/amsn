OBJS-tray := $(tray_dir)/libtray.o
TARGETS-tray := $(tray_dir)/libtray.so

$(TARGETS-tray): MORE_LIBS=${X_LIBS}

all:: $(TARGETS-tray)

clean::
	rm -f $(TARGETS-tray) $(OBJS-tray)
