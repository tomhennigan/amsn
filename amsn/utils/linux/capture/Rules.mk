OBJS-capture := capture.o libng/libng.a
TARGETS-capture := capture.so 

$(TARGETS-capture): $(OBJS-capture)

all:: $(TARGETS-capture)

clean::
	rm -f capture.so
