#include "config.h"

#include <stdio.h>
#include <stdlib.h>

#include "grab-ng.h"
#include "misc.h"

/* ------------------------------------------------------------------------ */
/* prehistoric libc ;)                                                      */

#ifndef HAVE_STRCASESTR
char* __used strcasestr(char *haystack, char *needle)
{
    int hlen = strlen(haystack);
    int nlen = strlen(needle);
    int offset;

    for (offset = 0; offset <= hlen - nlen; offset++)
	if (0 == strncasecmp(haystack+offset,needle,nlen))
	    return haystack+offset;
    return NULL;
}
#endif

#ifndef HAVE_MEMMEM
void __used *memmem(unsigned char *haystack, size_t haystacklen,
		    unsigned char *needle, size_t needlelen)
{
    int i;

    for (i = 0; i < haystacklen - needlelen; i++)
	if (0 == memcmp(haystack+i,needle,needlelen))
	    return haystack+i;
    return NULL;
}
#endif
