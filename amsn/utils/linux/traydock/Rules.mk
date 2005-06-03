OBJS-tray := $(tray_dir)/tray.o 
TARGETS-tray := $(tray_dir)/libtray.so 

$(TARGETS-tray): $(OBJS-tray)


all:: $(TARGETS-tray)

clean::
	rm -f $(TARGETS-tray) $(OBJS-tray)
