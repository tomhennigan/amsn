OBJS-TkCximage := $(tkcximage_dir)/src/TkCximage.so
TARGETS-TkCximage := $(tkcximage_dir)/TkCximage.so 


$(TARGETS-TkCximage): $(OBJS-TkCximage)
	cp $< $@

all:: $(TARGETS-TkCximage)

check:: check-tkcximage

check-tkcximage:
	wish $(tkcximage_dir)/demos/demo.tcl

clean:: clean-tkcximage

clean-tkcximage::
	rm -f $(TARGETS-TkCximage) $(OBJS-TkCximage)
