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

#define GUINT16_FROM_LE(val)	((guint16) ( \
	(guint16) (   val      & 0xff) + \
	(guint16) (((val >> 8) & 0xff) * 256)))

#define GUINT32_FROM_LE(val)	((guint32) ( \
	(guint32) (( (guint8)  val       ) & 0xff) + \
	(guint32) ((((guint8) (val >> 8 )) & 0xff) * 256) + \
	(guint32) ((((guint8) (val >> 16)) & 0xff) * 65536) + \
	(guint32) ((((guint8) (val >> 24)) & 0xff) * 16777216)))

#define GUINT16_TO_LE(val)	( (guint16) ( \
	(guint16) ( ((guint8) ( val       % 256)) ) | \
	(guint16) ( ((guint8) ((val /256) % 256)) << 8)))

#define GUINT32_TO_LE(val)	( (guint32) ( \
	(guint32) (((guint8) ( val            % 256))      ) | \
	(guint32) (((guint8) ((val /256)      % 256)) << 8 ) | \
	(guint32) (((guint8) ((val /65536)    % 256)) << 16) | \
	(guint32) (((guint8) ((val /16777216) % 256)) << 24)))



#undef g_new
#undef g_new0
#undef g_free
#undef g_realloc


#define g_new(struct_type, n_structs)		\
    ((struct_type *) malloc (sizeof (struct_type) * n_structs))

#define g_new0(struct_type, n_structs)		\
    ((struct_type *) memset(malloc (sizeof (struct_type) * n_structs), 0, sizeof (struct_type) * n_structs))

#define g_free free 
