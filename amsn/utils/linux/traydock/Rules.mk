OBJS-tray := $(tray_dir)/libtray.o
TARGETS-tray := $(tray_dir)/libtray.so

$(TARGETS-tray): $(OBJS-tray)
	@$(echo_link_so_addlibs)
	@$(link_so_addlibs)


all:: $(TARGETS-tray)

clean::
	rm -f $(TARGETS-tray) $(OBJS-tray)
