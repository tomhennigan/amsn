CFLAGS = -g -Wall

CC = gcc
LD = ld
RM = rm -f
LIBS =  -lglib-2.0 -lgobject-2.0 
INCLUDES = -I /usr/include/glib-2.0 -I /usr/lib/glib-2.0/include
OBJS = msn.o msn-connection.o msn-message.o
SRCS = msn.c msn-connection.c msn-message.c
HDRS =  msn.h msn-connection.h msn-message.h


all: msn

%.o: %.c
	${CC} ${CFLAGS} ${INCLUDES} -c -o $@ $<
	
msn: $(OBJS)
	${CC} -o msn ${OBJS} ${LIBS}

clean:
	$(RM) msn *.o *~
