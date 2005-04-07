# Directories in which the Tcl core can be found
TCL_INC_SPEC 	= -I/usr/include/tcl8.4
TCL_STUB_LIB_SPEC = -L/usr/lib/tcl8.4 -ltclstub8.4

# Directories in which the Tk core can be found
TK_INC_SPEC 	= -I/usr/include/tk8.4
TK_STUB_LIB_SPEC = -L/usr/lib/tk8.4 -ltkstub8.4

#DEFINES		=  -DTCL_THREADS=1 -DUSE_THREAD_ALLOC=1 -D_REENTRANT=1 -D_THREAD_SAFE=1 -DHAVE_PTHREAD_ATTR_SETSTACKSIZE=1 -DHAVE_PTHREAD_ATFORK=1 -DHAVE_READDIR_R=1 -DHAVE_THREE_ARG_READDIR_R=1 -DPEEK_XCLOSEIM=1 -D_LARGEFILE64_SOURCE=1 -DTCL_WIDE_INT_TYPE=long\ long -DHAVE_STRUCT_STAT64=1 -DHAVE_OPEN64=1 -DHAVE_LSEEK64=1 -DHAVE_TYPE_OFF64_T=1 -DHAVE_GETCWD=1 -DHAVE_OPENDIR=1 -DHAVE_STRSTR=1 -DHAVE_STRTOL=1 -DHAVE_STRTOLL=1 -DHAVE_STRTOULL=1 -DHAVE_TMPNAM=1 -DHAVE_WAITPID=1 -DHAVE_LIMITS_H=1 -DHAVE_UNISTD_H=1 -DHAVE_SYS_PARAM_H=1 -DUSE_TERMIOS=1 -DHAVE_SYS_TIME_H=1 -DTIME_WITH_SYS_TIME=1 -DHAVE_TM_ZONE=1 -DHAVE_GMTIME_R=1 -DHAVE_LOCALTIME_R=1 -DHAVE_TM_GMTOFF=1 -DHAVE_TIMEZONE_VAR=1 -DHAVE_ST_BLKSIZE=1 -DSTDC_HEADERS=1 -DHAVE_SIGNED_CHAR=1 -DHAVE_LANGINFO=1 -DHAVE_SYS_IOCTL_H=1  -DUSE_TCL_STUBS -DUSE_TK_STUBS 
SHLIB_LD     	= g++ -pipe -shared

NAME		= webcamsn
OUTPUT		= webcamsn.so

SOURCES		= webcamsn.cpp
OBJECTS 	= webcamsn.o


CC		= g++ -pipe

INCLUDES	= -I../src ${TCL_INC_SPEC} ${TK_INC_SPEC} 

CFLAGS    	= -O2  

CC_SWITCHS 	= ${CFLAGS} ${DEFINES} ${INCLUDES} 


LIBSN     	=  -L./ -lmimic ${TCL_STUB_LIB_SPEC} ${TK_STUB_LIB_SPEC}

.PHONY : all clean distclean 

all : ${OUTPUT} 

%.o: %.cpp
	$(CC) -c $(CC_SWITCHS) $<

libmimic.a : ../src/* ../Makefile
	cd ../ && make && cp src/.libs/libmimic.a webcamsn/ && cd webcamsn/

../Makefile :
	cd ../ && ./configure && cd webcamsn/

${OUTPUT}: ${OBJECTS} libmimic.a
	${SHLIB_LD} ${OBJECTS} $(LIBSN) -o $@ && cp ${OUTPUT} ../

${OBJECTS} : ${SOURCES} 

clean : 
	rm ${OBJECTS} libmimic.a ../${OUTPUT} ${OUTPUT} 2> /dev/null | true
	cd ../ && make clean && cd webcamsn/

distclean :
	rm -rf *~ ${OBJECTS} libmimic.a ${OUTPUT} ../${OUTPUT} config.* autom4te.cache 2>/dev/null | true
	cd ../ && make distclean && cd webcamsn/
