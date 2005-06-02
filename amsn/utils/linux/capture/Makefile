srcdir		:= .
VPATH		:= $(srcdir)


# programs
CC		:= gcc -pipe
CXX		:= 

# misc
VERSION		:= 2.0
PACKAGE		:= capture

# for CFLAGS
WARN_FLAGS	:= -Wall -Wmissing-prototypes -Wstrict-prototypes -Wpointer-arith
LFS_FLAGS	:= -D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE -D_FILE_OFFSET_BITS=64
LIB_FLAGS	:= -I. -I$(srcdir)/libng -I$(srcdir)/structs -Llibng
LIBDIR		:= /home/kakaroto/msn/utils/linux/capture


# various libraries
THREAD_LIBS	:= -lpthread
ALSA_LIBS	:= -lasound
MAD_LIBS	:= -lmad
MPEG2_LIBS	:= 
GL_LIBS		:= 


# Directories in which the Tcl core can be found
TCL_INC_SPEC 	= -I/usr/include/tcl8.4
TCL_STUB_LIB_SPEC = -L/usr/lib/tcl8.4 -ltclstub8.4${TCL_DBGX}

# Directories in which the Tk core can be found
TK_INC_SPEC 	= -I/usr/include/tcl8.4/tk-private/generic
TK_STUB_LIB_SPEC = -L/usr/lib -ltkstub8.4



# stuff configure has found
FOUND_ALSA	:= yes
FOUND_GL	:= no
FOUND_MAD	:= yes
FOUND_MPEG2	:= no
FOUND_OS	:= linux
USE_MMX		:= yes
USE_LIBNG	:= yes


# build final cflags
CFLAGS   := -g -O2
CFLAGS   += $(WARN_FLAGS)
CFLAGS   += $(LFS_FLAGS)
CFLAGS	 += ${TCL_INC_SPEC}
CFLAGS	 += ${TK_INC_SPEC}
CFLAGS   += $(LIB_FLAGS)
CFLAGS   += -DPACKAGE='"$(PACKAGE)"'
CFLAGS   += -DVERSION='"$(VERSION)"'
CFLAGS   += -DLIBDIR='"$(LIBDIR)"'
CXXFLAGS := $(CFLAGS)

# for gcc3
#CFLAGS   += -std-gnu99

# shared objects need -fPIC
%.so : CFLAGS   += -fPIC
%.so : CXXFLAGS += -fPIC

# libraries
LDLIBS  := 
LDFLAGS := 

LDFLAGS	 += ${TCL_STUB_LIB_SPEC}
LDFLAGS	 += ${TK_STUB_LIB_SPEC}

#########################################################
# targets

build: all

ifeq ($(USE_LIBNG), yes)
Makefile: $(srcdir)/Makefile.in $(srcdir)/configure
	$(srcdir)/configure --enable-libng
else
Makefile: $(srcdir)/Makefile.in $(srcdir)/configure
	$(srcdir)/configure --disable-libng
endif

$(srcdir)/configure: $(srcdir)/configure.ac
	(cd $(srcdir); ./autogen.sh)

clean::
	find . -name \*~ -print | xargs rm -f
	find . -name \*.o -print | xargs rm -f
	find . -name \*.a -print | xargs rm -f
	find . -name \*.dep -print | xargs rm -f


distclean:: clean
	-rm -f Makefile Make.config
	-rm -f config.cache config.h config.log config.status


#########################################################
# some rules ...

include $(srcdir)/Compile.mk


#########################################################
# include stuff

# subdirs
include $(srcdir)/Rules.mk
include $(srcdir)/libng/Rules.mk
include $(srcdir)/libng/plugins/Rules.mk
include $(srcdir)/libng/contrib-plugins/Rules.mk

