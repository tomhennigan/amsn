OBJS-tcl_siren := $(tcl_siren_dir)/src/tcl_siren.o $(tcl_siren_dir)/src/libsiren.a
TARGETS-tcl_siren := $(tcl_siren_dir)/src/tcl_siren.so 

OBJS-siren := 	$(tcl_siren_dir)/src/common.o  $(tcl_siren_dir)/src/dct4.o  $(tcl_siren_dir)/src/encoder.o \
		$(tcl_siren_dir)/src/huffman.o $(tcl_siren_dir)/src/rmlt.o \

TARGETS-siren := $(tcl_siren_dir)/src/libsiren.a


$(TARGETS-siren): $(OBJS-siren)
	@$(echo_ar_lib)
	@$(ar_lib)


$(TARGETS-tcl_siren): $(OBJS-tcl_siren)

all:: $(TARGETS-tcl_siren)

clean:: clean-tcl_siren

clean-tcl_siren:: clean-siren
	rm -f $(TARGETS-tcl_siren) $(OBJS-tcl_siren)

clean-siren:: 
	rm -f $(TARGETS-siren) $(OBJS-siren)
