OBJS-macDock = $(macosx_dir)/macDock/src/macDock.dylib
TARGETS-macDock = $(macosx_dir)/macDock/macDock.dylib

all:: $(TARGETS-macDock)

$(TARGETS-macDock): $(OBJS-macDock)
	cp $< $@

clean:: clean-macDock
	
clean-macDock::
	rm -f $(OBJS-macDock) $(TARGETS-macDock)
