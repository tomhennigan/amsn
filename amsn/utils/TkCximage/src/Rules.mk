OBJS-TkCximage := $(tkcximage_dir)/src/TkCximage.cpp.o $(tkcximage_dir)/src/PhotoFormat.cpp.o \
		  $(tkcximage_dir)/src/procs.cpp.o $(tkcximage_dir)/src/CxImage/libCxImage.a
ifeq ($(STATIC),yes)
OBJS-TkCximage += libstdc++.a
endif

TARGETS-TkCximage := $(tkcximage_dir)/src/TkCximage.cpp.so

$(TARGETS-TkCximage):: $(OBJS-TkCximage)

all:: $(TARGETS-TkCximage)

clean:: clean-tkcximage

clean-tkcximage::
	rm -f $(TARGETS-TkCximage) $(OBJS-TkCximage)
