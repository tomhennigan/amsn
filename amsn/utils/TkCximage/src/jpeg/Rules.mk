OBJS-jpeg := 	$(tkcximage_dir)/src/jpeg/jcapimin.o  $(tkcximage_dir)/src/jpeg/jcdctmgr.o  \
		$(tkcximage_dir)/src/jpeg/jcmarker.o  $(tkcximage_dir)/src/jpeg/jcphuff.o \
	     	$(tkcximage_dir)/src/jpeg/jdapimin.o  $(tkcximage_dir)/src/jpeg/jdcoefct.o  \
		$(tkcximage_dir)/src/jpeg/jdinput.o   $(tkcximage_dir)/src/jpeg/jdmerge.o \
	     	$(tkcximage_dir)/src/jpeg/jdtrans.o   $(tkcximage_dir)/src/jpeg/jfdctint.o  \
		$(tkcximage_dir)/src/jpeg/jidctred.o  $(tkcximage_dir)/src/jpeg/jquant2.o \
	     	$(tkcximage_dir)/src/jpeg/jcapistd.o  $(tkcximage_dir)/src/jpeg/jchuff.o    \
		$(tkcximage_dir)/src/jpeg/jcmaster.o  $(tkcximage_dir)/src/jpeg/jcprepct.o \
	     	$(tkcximage_dir)/src/jpeg/jdapistd.o  $(tkcximage_dir)/src/jpeg/jdcolor.o   \
		$(tkcximage_dir)/src/jpeg/jdmainct.o  $(tkcximage_dir)/src/jpeg/jdphuff.o  \
		$(tkcximage_dir)/src/jpeg/jerror.o    $(tkcximage_dir)/src/jpeg/jidctflt.o  \
		$(tkcximage_dir)/src/jpeg/jmemmgr.o   $(tkcximage_dir)/src/jpeg/jutils.o \
		$(tkcximage_dir)/src/jpeg/jccoefct.o  $(tkcximage_dir)/src/jpeg/jcinit.o    \
		$(tkcximage_dir)/src/jpeg/jcomapi.o   $(tkcximage_dir)/src/jpeg/jcsample.o \
		$(tkcximage_dir)/src/jpeg/jdatadst.o  $(tkcximage_dir)/src/jpeg/jddctmgr.o  \
		$(tkcximage_dir)/src/jpeg/jdmarker.o  $(tkcximage_dir)/src/jpeg/jdpostct.o \
		$(tkcximage_dir)/src/jpeg/jfdctflt.o  $(tkcximage_dir)/src/jpeg/jidctfst.o  \
		$(tkcximage_dir)/src/jpeg/jmemnobs.o  $(tkcximage_dir)/src/jpeg/jccolor.o  \
		$(tkcximage_dir)/src/jpeg/jcmainct.o  $(tkcximage_dir)/src/jpeg/jcparam.o   \
		$(tkcximage_dir)/src/jpeg/jctrans.o   $(tkcximage_dir)/src/jpeg/jdatasrc.o \
		$(tkcximage_dir)/src/jpeg/jdhuff.o    $(tkcximage_dir)/src/jpeg/jdmaster.o  \
		$(tkcximage_dir)/src/jpeg/jdsample.o  $(tkcximage_dir)/src/jpeg/jfdctfst.o \
		$(tkcximage_dir)/src/jpeg/jidctint.o  $(tkcximage_dir)/src/jpeg/jquant1.o



TARGETS-jpeg := $(tkcximage_dir)/src/jpeg/libjpeg.a


$(TARGETS-jpeg): $(OBJS-jpeg)
	@$(echo_ar_lib)
	@$(ar_lib)

all:: $(TARGETS-jpeg)

clean::
	rm -f $(TARGETS-jpeg)
