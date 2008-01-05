CC = gcc
RM = /bin/rm -f

ARCH		= -arch ppc -arch i386 -isysroot /Developer/SDKs/MacOSX10.4u.sdk -mmacosx-version-min=10.3
CFLAGS		= --std=c99 -fconstant-cfstrings -Wall -DUSE_TCL_STUBS $(ARCH)
LDFLAGS		= -dynamiclib $(UNIVERSAL) -Wl,-single_module
FRAMEWORKS	= -framework Cocoa -framework Tcl

OBJS = GrowlPathUtil.o GrowlApplicationBridge.o CFGrowlAdditions.o TclGrowler.o growl.o NSURLAdditions.o
TARGET = libgrowl.dylib

all: $(TARGET)

$(TARGET): $(OBJS)
	$(CC) $(LDFLAGS) $(FRAMEWORKS) $(OBJS) -o $@

clean:
	$(RM) $(OBJS) $(TARGET)

install: all
	cp $(TARGET) ../

