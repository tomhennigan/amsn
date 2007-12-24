#ifndef BYTEORDER_H
#define BYTEORDER_H

#include <sys/types.h>

#ifdef __sun
#include <sys/byteorder.h>
#define BIG_ENDIAN    4321
#define LITTLE_ENDIAN 1234
#ifdef _BIG_ENDIAN
#define BYTE_ORDER BIG_ENDIAN
#else
#define BYTE_ORDER LITTLE_ENDIAN
#endif
#endif


#ifndef BYTE_ORDER
# error "Aiee: BYTE_ORDER not defined\n";
#endif

#define SWAP2(x) (((x>>8) & 0x00ff) |\
                  ((x<<8) & 0xff00))

#define SWAP4(x) (((x>>24) & 0x000000ff) |\
                  ((x>>8)  & 0x0000ff00) |\
                  ((x<<8)  & 0x00ff0000) |\
                  ((x<<24) & 0xff000000))

#endif /* BYTEORDER_H */
