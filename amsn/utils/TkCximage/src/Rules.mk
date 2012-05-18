OBJS-TkCximage := $(tkcximage_dir)/src/TkCximage.cpp.o $(tkcximage_dir)/src/PhotoFormat.cpp.o \
		  $(tkcximage_dir)/src/procs.cpp.o $(tkcximage_dir)/src/CxImage/libCxImage.a

ifeq ($(STATIC),yes)
OBJS-TkCximage += libstdc++.a
endif

TARGETS-TkCximage := $(tkcximage_dir)/src/TkCximage.cpp.$(SHLIB_EXTENSION)

$(OBJS-TkCximage): CXXFLAGS+=-I$(tkcximage_dir)/src/CxImage

$(TARGETS-TkCximage): $(OBJS-TkCximage) ${STATIC_PNG_JPEG}
	@$(echo_link_so_cpp)
	@$(link_so_cpp)

all:: $(TARGETS-TkCximage)

clean:: clean-tkcximagesrc

clean-tkcximagesrc::
	rm -f $(TARGETS-TkCximage) $(OBJS-TkCximage)
