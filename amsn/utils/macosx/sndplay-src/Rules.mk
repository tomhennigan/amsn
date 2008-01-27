OBJS-sndplay := $(macosx_dir)/sndplay-src/sndplay.o
TARGETS-sndplay := $(macosx_dir)/sndplay-src/sndplay
FINAL-sndplay := $(macosx_dir)/sndplay

LDFLAGS += -framework AppKit

$(TARGETS-sndplay): $(OBJS-sndplay)
	@$(echo_link_app)
	@$(link_app)

$(FINAL-sndplay): $(TARGETS-sndplay)
	cp $< $@

all:: $(TARGETS-sndplay)
	

clean:: clean-sndplay

clean-sndplay::
	rm -f $(TARGETS-sndplay) $(OBJS-sndplay) $(FINAL-sndplay)
