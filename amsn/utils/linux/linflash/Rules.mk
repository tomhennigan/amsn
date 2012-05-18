OBJS-linflash := $(linflash_dir)/flash.o
TARGETS-linflash := $(linflash_dir)/flash.so 

$(TARGETS-linflash): MORE_LIBS=${X_LIBS}

all:: $(TARGETS-linflash)

clean:: clean-linflash

clean-linflash::
	rm -f $(TARGETS-linflash) $(OBJS-linflash)

