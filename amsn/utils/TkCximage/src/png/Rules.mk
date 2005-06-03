OBJS-png := 	$(tkcximage_dir)/src/png/png.o $(tkcximage_dir)/src/png/pnggccrd.o  \
		$(tkcximage_dir)/src/png/pngmem.o  $(tkcximage_dir)/src/png/pngread.o \
		$(tkcximage_dir)/src/png/pngrtran.o  $(tkcximage_dir)/src/png/pngset.o  \
	    	$(tkcximage_dir)/src/png/pngvcrd.o  $(tkcximage_dir)/src/png/pngwrite.o  \
		$(tkcximage_dir)/src/png/pngwutil.o $(tkcximage_dir)/src/png/pngerror.o \
		$(tkcximage_dir)/src/png/pngget.o $(tkcximage_dir)/src/png/pngpread.o \
	    	$(tkcximage_dir)/src/png/pngrio.o   $(tkcximage_dir)/src/png/pngrutil.o \
		$(tkcximage_dir)/src/png/pngtrans.o  $(tkcximage_dir)/src/png/pngwio.o   \
		$(tkcximage_dir)/src/png/pngwtran.o

TARGETS-png := $(tkcximage_dir)/src/png/libpng.a


$(TARGETS-png): $(OBJS-png)
	@$(echo_ar_lib)
	@$(ar_lib)

all:: $(TARGETS-png)

clean::
	rm -f $(TARGETS-png) 
