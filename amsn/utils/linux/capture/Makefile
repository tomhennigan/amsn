# Directories in which the Tcl core can be found
TCL_INC_SPEC 	= -I/usr/include/tcl8.4
TCL_STUB_LIB_SPEC = -L/usr/lib/tcl8.4 -ltclstub8.4

# Directories in which the Tk core can be found
TK_INC_SPEC 	= -I/usr/include/tk8.4
TK_STUB_LIB_SPEC = -L/usr/lib/tk8.4 -ltkstub8.4


SHLIB_LD     	= gcc -pipe -shared -fPIC

NAME		= capture
OUTPUT		= capture.so

SOURCES		= capture.c
OBJECTS 	= capture.o


CC		= gcc -pipe -fPIC

INCLUDES	=  ${TCL_INC_SPEC} ${TK_INC_SPEC} 

CFLAGS    	= -O2  -Wall

CC_SWITCHS 	= ${CFLAGS} ${DEFINES} ${INCLUDES} 


LIBSN     	=  ${TCL_STUB_LIB_SPEC} ${TK_STUB_LIB_SPEC}

.PHONY : all clean distclean 

all : ${OUTPUT} 

%.o: %.c
	$(CC) -c $(CC_SWITCHS) $<

${OUTPUT}: ${OBJECTS} 
	${SHLIB_LD} ${OBJECTS} $(LIBSN) -o $@ 

${OBJECTS} : ${SOURCES} 

clean : 
	rm ${OBJECTS} ../${OUTPUT} ${OUTPUT} 2> /dev/null | true

distclean :
	rm -rf *~ ${OBJECTS}  ${OUTPUT} ../${OUTPUT} config.* autom4te.cache 2>/dev/null | true
