/* --------------------------------------------------------------------- */
/* misc stuff some libc versions have and some don't ...                 */

#ifndef HAVE_STRCASESTR
char* strcasestr(char *haystack, char *needle);
#endif

#ifndef HAVE_MEMMEM
void *memmem(unsigned char *haystack, size_t haystacklen,
	     unsigned char *needle, size_t needlelen);
#endif
