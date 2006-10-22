#include <stdlib.h>

typedef char   gchar;
typedef short  gshort;
typedef long   glong;
typedef int    gint;
typedef gint   gboolean;

typedef unsigned char   guchar;
typedef unsigned short  gushort;
typedef unsigned long   gulong;
typedef unsigned int    guint;

typedef float   gfloat;
typedef double  gdouble;

typedef void* gpointer;
typedef const void *gconstpointer;



typedef signed char gint8;
typedef unsigned char guint8;
typedef signed short gint16;
typedef unsigned short guint16;
typedef signed int gint32;
typedef unsigned int guint32;



#ifndef	FALSE
#define	FALSE	(0)
#endif

#ifndef	TRUE
#define	TRUE	(!FALSE)
#endif


#undef	MAX
#define MAX(a, b)  (((a) > (b)) ? (a) : (b))

#undef	MIN
#define MIN(a, b)  (((a) < (b)) ? (a) : (b))


#undef GUINT16_FROM_LE
#undef GUINT32_FROM_LE
#undef GUINT16_TO_LE
#undef GUINT32_TO_LE

#ifdef __BIG_ENDIAN__

#define POW_2_8 256
#define POW_2_16 65536
#define POW_2_24 16777216

#define IDX(val, i) ((unsigned int) ((unsigned char *) &val)[i])

#define GUINT16_FROM_LE(val) ( (unsigned short) ( IDX(val, 0) + IDX(val, 1) * 256 ))
#define GUINT32_FROM_LE(val) ( (int) (IDX(val, 0) + IDX(val, 1) * 256 + \
        IDX(val, 2) * 65536 + IDX(val, 3) * 16777216)) 

#define GUINT16_TO_LE(val) ( (unsigned short) (\
        (((unsigned short)val % 256) & 0xff) << 8 | \
        ((((unsigned short)val / POW_2_8) % 256) & 0xff) ))

#define GUINT32_TO_LE(val) ( (int) (\
        ((((unsigned int) val           ) % 256)  & 0xff) << 24 | \
        ((((unsigned int) val / POW_2_8 ) % 256) & 0xff) << 16| \
        ((((unsigned int) val / POW_2_16) % 256) & 0xff) << 8 | \
        ((((unsigned int) val / POW_2_24) % 256) & 0xff) ))

#else 

#define GUINT16_TO_LE(val) ( (unsigned short) (val))
#define GUINT32_TO_LE(val) ( (unsigned int) (val))
#define GUINT16_FROM_LE(val) ( (unsigned short) (val))
#define GUINT32_FROM_LE(val) ( (unsigned int) (val))

#endif


#undef g_new
#undef g_new0
#undef g_free
#undef g_realloc


#define g_new(struct_type, n_structs)		\
    ((struct_type *) malloc (sizeof (struct_type) * n_structs))

#define g_new0(struct_type, n_structs)		\
    ((struct_type *) memset(malloc (sizeof (struct_type) * n_structs), 0, sizeof (struct_type) * n_structs))

#define g_free free 
