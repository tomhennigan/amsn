TCL_FRAMEWORK=/System/Library/Frameworks/Tcl.framework
TK_FRAMEWORK=/System/Library/Frameworks/Tk.framework
TCL_CFLAGS=-I$(TCL_FRAMEWORK)/Headers -DUSE_TCL_STUBS
TK_CFLAGS=-I$(TK_FRAMEWORK)/Headers -DUSE_TK_STUBS
TCL_LDFLAGS=-framework Tcl
TK_LDFLAGS=-framework Tk
UNIVERSAL=-arch i386 -arch ppc -isysroot /Developer/SDKs/MacOSX10.4u.sdk 
CFLAGS=-fPIC -DTARGET_OS_MAC=1 -DTARGET_API_MAC_CARBON=1 -DMAC_OSX_TK 	$(UNIVERSAL) -O0 $(TCL_CFLAGS) $(TK_CFLAGS)
DYNLIB_LDFLAGS=-dynamiclib -Wl,-single_module
LDFLAGS=$(UNIVERSAL) $(DYNLIB_LDFLAGS) $(TK_LDFLAGS) $(TCL_LDFLAGS) 	-framework CoreFoundation -framework Carbon -framework QuickTime
OBJECTS=tclCarbonHICommand.o
TARGET=tclCarbonHICommand0.1.dylib

all: $(TARGET)

$(TARGET): $(OBJECTS)
	$(CC) $(OBJECTS) $(LDFLAGS) -o $@

clean:
	rm -f $(OBJECTS) $(TARGET)
