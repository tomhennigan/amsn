/* ------------------------------------------------------------------- */
/* YUV conversions                                                     */

int
packed422_to_planar422(unsigned char *d, unsigned char *s, int p)
{
    int i;
    unsigned char *y,*u,*v;

    i = p/2;
    y = d;
    u = y + p;
    v = u + p / 2;
    
    while (--i) {
	*(y++) = *(s++);
	*(u++) = *(s++);
	*(y++) = *(s++);
        *(v++) = *(s++);
    }
    return p*2;
}

/* y only, no chroma */
int
packed422_to_planar420(unsigned char *d, unsigned char *s, int p)
{
    int i;
    unsigned char *y;

    i = p/2;
    y = d;
    
    while (--i) {
	*(y++) = *(s++);
	s++;
	*(y++) = *(s++);
	s++;
    }
    return p*3/2;
}

#if 0
void
x_packed422_to_planar420(unsigned char *d, unsigned char *s, int w, int h)
{
    int  a,b;
    unsigned char *y,*u,*v;

    y = d;
    u = y + w * h;
    v = u + w * h / 4;

    for (a = h; a > 0; a -= 2) {
	for (b = w; b > 0; b -= 2) {
	    *(y++) = *(s++);
	    *(u++) = *(s++);
	    *(y++) = *(s++);
	    *(v++) = *(s++);
	}
	for (b = w; b > 0; b -= 2) {
	    *(y++) = *(s++);
	    s++;
	    *(y++) = *(s++);
	    s++;
	}
    }
}
#endif
