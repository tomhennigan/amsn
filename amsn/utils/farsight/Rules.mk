OBJS-farsight := $(farsight_dir)/farsight.o
TARGETS-farsight := $(farsight_dir)/farsight

$(OBJS-farsight): $(farsight_dir)/farsight.c
	@$(echo_compile_farsight)
	@$(compile_farsight)

$(TARGETS-farsight): $(OBJS-farsight)
	@$(echo_link_farsight)
	@$(link_farsight)

all:: $(TARGETS-farsight)

clean:: clean-farsight

clean-farsight::
	rm -f $(TARGETS-farsight) $(OBJS-farsight)
