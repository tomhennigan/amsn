CC = gcc
CFLAGS = -framework AppKit
CFLAGS_INTEL = -arch i386 -isysroot /Developer/SDKs/MacOSX10.4u.sdk
CFLAGS_PPC = -arch ppc -isysroot /Developer/SDKs/MacOSX10.2.8.sdk
RM = rm

sndplay: sndplay_intel.o sndplay_ppc.o
	lipo -create sndplay_intel.o sndplay_ppc.o -output sndplay

sndplay_intel.o:
	$(CC) $(CFLAGS) $(CFLAGS_INTEL) sndplay.m -o sndplay_intel.o
	
sndplay_ppc.o:
	$(CC) $(CFLAGS) $(CFLAGS_PPC) sndplay.m -o sndplay_ppc.o
	
all: sndplay

clean_objs:
	-$(RM) *.o

clean_release: clean_objs

clean: clean_objs
	-$(RM) sndplay