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

#define POW_2_8 256
#define POW_2_16 65536
#define POW_2_24 16777216

#define IDX(val, i) ((guint32) ((guchar *) &val)[i])

#define GUINT16_FROM_LE(val) ( (guint16) ( IDX(val, 0) + (guint16) IDX(val, 1) * 256 ))
#define GUINT32_FROM_LE(val) ( (guint32) (IDX(val, 0) + IDX(val, 1) * 256 + \
        IDX(val, 2) * 65536 + IDX(val, 3) * 16777216)) 


#ifdef BYTE_ORDER_BE

#define SHIFT_1_16(res) (res << 8)
#define SHIFT_2_16(res) (res)

#define SHIFT_1_32(res) (res << 24)
#define SHIFT_2_32(res) (res << 16)
#define SHIFT_3_32(res) (res << 8)
#define SHIFT_4_32(res) (res)

#else 

#define SHIFT_1_16(res) (res)
#define SHIFT_2_16(res) (res << 8)

#define SHIFT_1_32(res) (res)
#define SHIFT_2_32(res) (res << 8)
#define SHIFT_3_32(res) (res << 16)
#define SHIFT_4_32(res) (res << 24)

#endif


#define GUINT16_TO_LE(val) ( (guint16) (\
        SHIFT_1_16(((guint16) (val % 256) & 0xff)) | \
        SHIFT_2_16(((guint16) ((val / POW_2_8) % 256) & 0xff)) ))

#define GUINT32_TO_LE(val) ( (guint32) (\
        SHIFT_1_32(((guint32) (val % 256 ) & 0xff)) | \
        SHIFT_2_32(((guint32) ((val / POW_2_8) % 256) & 0xff))| \
        SHIFT_3_32(((guint32) ((val / POW_2_16) % 256 ) & 0xff)) | \
        SHIFT_4_32(((guint32) ((val / POW_2_24) % 256 ) & 0xff)) ))


#undef g_new
#undef g_new0
#undef g_free
#undef g_realloc


#define g_new(struct_type, n_structs)		\
    ((struct_type *) malloc (sizeof (struct_type) * n_structs))

#define g_new0(struct_type, n_structs)		\
    ((struct_type *) memset(malloc (sizeof (struct_type) * n_structs), 0, sizeof (struct_type) * n_structs))

#define g_free free 
