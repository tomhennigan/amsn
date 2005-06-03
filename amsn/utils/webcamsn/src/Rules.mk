OBJS-webcamsn := $(webcamsn_dir)/src/webcamsn.o $(webcamsn_dir)/src/kidhash.o $(webcamsn_dir)/src/libmimic.a
TARGETS-webcamsn := $(webcamsn_dir)/src/webcamsn.so 

OBJS-mimic := 	$(webcamsn_dir)/src/bitstring.o  $(webcamsn_dir)/src/deblock.o  $(webcamsn_dir)/src/encode.o \
		$(webcamsn_dir)/src/idct_dequant.o $(webcamsn_dir)/src/mimic.o \
		$(webcamsn_dir)/src/vlc_decode.o  $(webcamsn_dir)/src/colorspace.o  $(webcamsn_dir)/src/decode.o   \
		$(webcamsn_dir)/src/fdct_quant.o  $(webcamsn_dir)/src/vlc_common.o  $(webcamsn_dir)/src/vlc_encode.o

TARGETS-mimic := $(webcamsn_dir)/src/libmimic.a


$(TARGETS-mimic): $(OBJS-mimic)
	@$(echo_ar_lib)
	@$(ar_lib)


$(TARGETS-webcamsn): $(OBJS-webcamsn)

all:: $(TARGETS-webcamsn)

clean:: clean-webcamsn

clean-webcamsn::
	rm -f $(TARGETS-webcamsn) $(OBJS-webcamsn)
