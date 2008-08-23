# aio.m4
# Configure paths for libaio


dnl AIO_CHECK([ACTION-IF-FOUND [,ACTIO-IF-NOT-FOUND])
dnl test for libaio, and define AIO_CFLAGS and AIO_LIBS
dnl
AC_DEFUN([AIO_CHECK],[
dnl
dnl get the c flags and libraies
dnl
AC_ARG_WITH(aio,[  --with-aio=PREFIX		Prefix where libaio is installed (optional)],aio_prefix="$withval", aio_preifx="")
AC_ARG_WITH(aio-libs,[  --with-aio-libs=DIR		Directory where libaio is installer (optional)],aio_libs="$withval",aio_libs="")
AC_ARG_WITH(aio-includes,[  --with-aio-includes=DIR		Directory where liabio includes are installed (optional)],aio_includes="$withval",aio_includes="")
AC_MSG_CHECKING([for aio ])

if test "x$aio_prefix" != "xno"; then


dnl
dnl  set the flags 
dnl
if test "x$aio_libraries" != "x" ; then
       	AIO_LIBS="-L$aio_libraries"
elif test "x$aio_prefix" != "x"; then
	AIO_LIBS="-L$aio_prefix/lib"
fi

if test "x$aio_includes" != "x" ; then
    	AIO_CFLAGS="-I$aio_includes"
elif test "x$aio_prefix" != "x"; then
	AIO_CFLAGS="-I$aio_prefix/include"
fi
AC_CHECK_FUNCS(dlopen, [AO_DL_LIBS=""], [
	AC_CHECK_LIB(dl, dlopen, [AO_DL_LIBS="-ldl"], [
		AC_MSG_WARN([could not find dlopen() needed by libaio sound drivers
		your system may not be supported.])
    	])
])
AIO_LIBS="$AIO_LIBS -laio $AIO_DL_LIBS"

dnl user didn't provide try pkg-config
if test "x$AIO_CFLAGS" = "x"; then
	unset AIO_LIBS
	unset AIO_CFLAGS
	PKG_CHECK_MODULES([AIO],[aio])
fi


no_aio=""
ac_save_CFLAGS="$CFLAGS"
ac_save_LIBS="$LIBS"
CFLAGS="$CFLAGS $AIO_CFLAGS"
LIBS="$LIBS $AIO_LIBS"
dnl
dnl Now check if the installed aio is sufficiently new.
dnl
rm -f conf.aiotest
AC_RUN_IFELSE([
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <aio/aio.h>

int main ()
{
  system("touch conf.aiotest");
  return 0;
}

],, no_aio=yes,[])
if test "x$no_aio" = "x" ; then
	AC_MSG_CHECKING(aio found)
	AC_MSG_RESULT(yes)
	ifelse([$1], , :, [$1])    
else
	if test -f conf.aiotest ; then
		:
	else
		echo "*** Could not run libaio test program, checking why..."
		CFLAGS="$CFLAGS $AO_CFLAGS"
	       	LIBS="$LIBS $AO_LIBS"
		AC_LINK_IFELSE([AC_LANG_PROGRAM(
     [[#include <stdio.h>
     #include <stdlib.h>
     #include <string.h>
     #include <aio/aio.h>]],
                                     [return 0;])],[echo "*** The test program compiled, but did not run. This usually means"
					 echo "*** that the run-time linker is not finding libaio or finding the wrong version"
					 echo "*** try adding the path to liabio to your LD_LIBRARY_PATH  or ld.config and run ldconfig." ],
				     [ echo "*** The test program failed to compile or link. See the file config.log for the"
				      echo "*** exact error that occured."]
		)
	fi
	AIO_CFLAGS=""
	AIO_LIBS=""
	AC_MSG_CHECKING(aio found)
	AC_MSG_RESULT(no)
	ifelse([$2], , :, [$2])

fi
AC_SUBST(AIO_CFLAGS)
AC_SUBST(AIO_LIBS)
else

AC_MSG_RESULT(disabled)
ifelse([$2], , :,[$2])
fi

])
