CFLAGS = -g -Wall -std=gnu99

CC = gcc
LD = ld
RM = rm -f
LIBS = -lglib-2.0 -lgobject-2.0
INCLUDES = -I /usr/include/glib-2.0 -I /usr/lib/glib-2.0/include
OBJS = msn.o msn-connection.o msn-message.o msn-protocol.o protocols/msnp13.o protocols/cvr0.o
SRCS = msn.c msn-connection.c msn-message.c msn-protocol.c protocols/msnp13.c protocols/cvr0.c
HDRS = msn.h msn-connection.h msn-message.h msn-protocol.h protocols/msnp13.h protocols/cvr0.h


all: msn

%.o: %.c
	${CC} ${CFLAGS} ${INCLUDES} -c -o $@ $<
	
msn: $(OBJS)
	${CC} -o msn ${OBJS} ${LIBS}

clean:
	$(RM) msn *.o *~
	$(RM) protocols/*.o protocols/*~

