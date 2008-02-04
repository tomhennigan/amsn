TARGETS-macDock = $(macosx_dir)/macDock/src/macDock.dylib
OBJS-macDock = $(macosx_dir)/macDock/src/dockIcon.o $(macosx_dir)/macDock/src/macDock.o

LDFLAGS += -framework Carbon

all:: $(TARGETS-growl)

$(TARGETS-macDock): $(OBJS-macDock)
	@$(echo_link_so)
	@$(link_so)

clean:: clean-macDock
	
clean-macDock::
	rm -f $(OBJS-macDock) $(TARGET-macDock)
