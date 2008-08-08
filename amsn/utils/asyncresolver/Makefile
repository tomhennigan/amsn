TCLINC=/usr/include/tcl8.5
TCLLIB=/usr/lib/tcl8.5

all:  libasyncresolver.so

libasyncresolver.so: asyncresolver.c
	gcc -shared -o libasyncresolver.so -DUSE_TCL_STUBS -I$(TCLINC) asyncresolver.c -L$(TCLLIB) -ltclstub8.5
