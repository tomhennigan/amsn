#                                               -*- Autoconf -*-
# Process this file with autoconf to produce a configure script.

AC_PREREQ(2.61)
AC_INIT([libaio],[0.1], [kenshin@cerberus.endofinternet.org])
AC_CONFIG_MACRO_DIR([m4])
AC_CONFIG_AUX_DIR([m4])
AM_INIT_AUTOMAKE([gnu 1.6])
#Library versioning
LIB_CURRENT=0
LIB_REVISION=0
LIB_AGE=0
AC_SUBST(LIB_CURRENT)
AC_SUBST(LIB_REVISION)
AC_SUBST(LIB_AGE)


#Plugin versioning.  We use an integer version number much like LIB_CURRENT.
PLUGIN_VERSION=0

AC_CANONICAL_BUILD
AC_CANONICAL_HOST

plugindir=$libdir/aio/plugins-$PLUGIN_VERSION
AC_SUBST(plugindir)





# Checks for programs.
AC_PROG_LIBTOOL([disable-static])
AC_LIBTOOL_DLOPEN
AC_PROG_LIBTOOL
AC_PROG_CC
AC_LIBTOOL_WIN32_DLL
AC_LIBTOOL_DLOPEN
AM_PROG_LIBTOOL



# check fo dlopen  


AC_CHECK_HEADERS([dlfcn.h],
        [AC_SEARCH_LIBS([dlopen],[dl],
	                [AC_DEFINE([HAVE_DLOPEN],[1],
			                        [support dynamic linking loader])])])
cflags_save="$CFLAGS"
if test -z "$GCC"; then
        case $host in
	*-*-irix*)
		if test -z "$CC"; then
			CC=cc
		fi
		PLUGIN_LDFLAGS="-export-dynamic -avoid-version"
		DEBUG="-g -signed"
		CFLAGS="-O2 -w -signed"
		PROFILE="-p -g3 -O2 -signed" ;;
	sparc-sun-solaris*)
		PLUGIN_LDFLAGS="-export-dynamic -avoid-version"
		DEBUG="-v -g"
		CFLAGS="-xO4 -fast -w -fsimple -native -xcg92"
		PROFILE="-v -xpg -g -xO4 -fast -native -fsimple -xcg92 -Dsuncc" ;;
	*)
		PLUGIN_LDFLAGS="-export-dynamic -avoid-version"
		DEBUG="-g -DDEBUG"
		CFLAGS="-O"
		PROFILE="-g -p" ;;
	esac
else
	case $host in
	*-*-linux*)
		PLUGIN_LDFLAGS="-export-dynamic -avoid-version"
		DEBUG="-g -Wall -DDEBUG -D_REENTRANT -D__NO_MATH_INLINES -fsigned-char"
		CFLAGS="-O20 -ffast-math -D_REENTRANT -fsigned-char"
		PROFILE="-pg -g -O20 -ffast-math -D_REENTRANT -fsigned-char";;
	sparc-sun-*)
		PLUGIN_LDFLAGS="-export-dynamic -avoid-version"
		DEBUG="-g -Wall -D__NO_MATH_INLINES -fsigned-char"
		CFLAGS="-O20 -ffast-math -D__NO_MATH_INLINES -fsigned-char"
		PROFILE="-pg -g -O20 -D__NO_MATH_INLINES -fsigned-char" ;;
	*-darwin*)
		PLUGIN_LDFLAGS="-module -avoid-version"
		DEBUG="-g -Wall -D__NO_MATH_INLINES -fsigned-char -Ddlsym=dlsym_auto_underscore"
		CFLAGS="-D__NO_MATH_INLINES -fsigned-char -Ddlsym=dlsym_auto_underscore"
		;;

	*)
		PLUGIN_LDFLAGS="-export-dynamic -avoid-version"
		DEBUG="-g -DDEBUG -Wall -D__NO_MATH_INLINES -fsigned-char"
		CFLAGS="-O20 -D__NO_MATH_INLINES -fsigned-char"
		PROFILE="-O20 -g -pg -D__NO_MATH_INLINES -fsigned-char" ;;
esac
fi
CFLAGS="$CFLAGS $cflags_save -Wall -Werror"
DEBUG="$DEBUG "
PROFILE="$PROFILE $cflags_save"
AC_SUBST(DEBUG)
AC_SUBST(PROFILE)

dnl =========================================
dnl Need -no-undefined for building win32 dll
dnl =========================================
dnl Should we do that for cygwin too ???
dnl I guess so but it needs to be tested.
case $host in
	*-mingw*|*-cygwin*)
    		LIBAIO_LA_LDFLAGS="-no-undefined"
		;;
	*)
		LIBAIO_LA_LDFLAGS=""
		;;
esac
AC_SUBST(LIBAIO_LA_LDFLAGS)

#AC_CHECK_LIB(pthread, pthread_kill)

case $host in
	*hpux*)
		DLOPEN_FLAGS='(RTLD_LAZY)'
		SHARED_LIB_EXTS='.sl'
		;;
	*openbsd* | *netbsd* | *solaris2.7)
		DLOPEN_FLAGS='(RTLD_LAZY)'
		SHARED_LIB_EXTS='.so'
		;;
	*)
		DLOPEN_FLAGS='(RTLD_NOW | RTLD_GLOBAL)'
		SHARED_LIB_EXTS='.so'
		;;
esac
AC_DEFINE_UNQUOTED(DLOPEN_FLAG, [${DLOPEN_FLAGS}],"dlopen flags")
AC_DEFINE_UNQUOTED(SHARED_LIB_EXT, ["$SHARED_LIB_EXTS"], "shared lib ext")


# Checks for libraries.

# Checks for header files.
AC_HEADER_STDC
AC_CHECK_HEADERS([fcntl.h inttypes.h  stdint.h limits.h stddef.h stdint.h stdlib.h string.h sys/ioctl.h sys/socket.h sys/time.h unistd.h])

# Checks for typedefs, structures, and compiler characteristics.
AC_C_CONST
AC_HEADER_STDBOOL
AC_C_INLINE
AC_TYPE_INT16_T
AC_TYPE_INT32_T
AC_TYPE_INT64_T
AC_TYPE_INT8_T
AC_TYPE_PID_T
AC_TYPE_SIZE_T
AC_HEADER_TIME
AC_TYPE_UINT16_T
AC_TYPE_UINT32_T
AC_TYPE_UINT64_T
AC_TYPE_UINT8_T
AC_C_VOLATILE

# Checks for library functions.
AC_PROG_GCC_TRADITIONAL
AC_FUNC_MALLOC
AC_FUNC_SELECT_ARGTYPES
AC_CHECK_FUNCS([floor gettimeofday memmove memset pow select setenv strcasecmp strchr strdup strerror strrchr strstr strtol])

#enable debug 

AC_ARG_ENABLE(debug,[  --enable-debug		enable debug output],[ ENABLE_DEBUG="$enableval" ], [ ENABLE_DEBUG="yes"])
if test "$ENABLE_DEBUG" = "yes"; then
	AC_DEFINE([DEBUG_OUT],[1],["debug output"])
fi 


#CHECK FOR OSS

AC_ARG_ENABLE(oss, [  --enable-oss		include oss output plugin],[ BUILD_OSS="$enableval" ], [ BUILD_OSS="yes" ])

if test "x$BUILD_OSS" = "xyes"; then
	AC_CHECK_HEADERS([sys/soundcard.h machine/soundcard.h])

	if test "x${ac_cv_header_sys_soundcard_h}" = "xyes" || test "x${ac_cv_header_machine_soundcard_h}" = "xyes" ; then 
		have_oss=yes
	fi
fi
if test "x$have_oss" = xyes; then
	AC_DEFINE(HAVE_OSS,[1],[we have oss])
fi

AM_CONDITIONAL(HAVE_OSS,test "x$have_oss" = "xyes")

# CHECK FOR ALSA

AC_ARG_ENABLE(alsa, [  --enable-alsa         include alsa  output plugin ],[ BUILD_ALSA="$enableval" ],[ BUILD_ALSA="yes" ])
AC_ARG_ENABLE(alsa-mmap, [  --enable-alsa-mmap         use alsa mmio ],[ BUILD_ALSAMMIO="$enableval" ],[ BUILD_ALSAMMIO="yes" ])


if test "$BUILD_ALSA" = "yes"; then
	AC_CHECK_HEADER([alsa/asoundlib.h], ,have_alsa=no)
        AC_CHECK_LIB([asound], [snd_pcm_open],have_alsa=yes,have_alsa=no)
	if test "$BUILD_ALSAMMIO" = "yes" ; then 
		AC_CHECK_HEADER(sys/mman.h, have_alsammio=yes, have_alsammio=no)
	fi
fi
if test "x$have_alsa" = xyes; then 
	ALSA_LIBS="-lasound"
	AC_DEFINE(HAVE_ALSA,[1],[we have alsa])
	if test "x$have_alsammio" = xyes; then
		AC_DEFINE(USE_ALSA_MMIO,[1],[Enable alsa mmap])
	fi
else
	ALSA_LIBS=""
fi


AM_CONDITIONAL(HAVE_ALSA, test "x$have_alsa" = xyes)




AC_SUBST(ALSA_LIBS)

AC_ARG_ENABLE(broken-oss, [  --enable-broken-oss           workaround for some OSS drivers (see README for details)],,
if test "x$have_alsa" = "xyes" ; then
   enable_broken_oss="yes"
fi)

if test "x$enable_broken_oss" = "xyes"; then
   AC_DEFINE([BROKEN_OSS],[1],["broken oss api workarround"])
   AC_MSG_WARN(["Broken OSS API workaround enabled.  See  aio_oss.c for details."])
fi
AC_SUBST(PLUGIN_LDFLAGS)



SC_PATH_TCLCONFIG
SC_LOAD_TCLCONFIG


	SHLIB_CFLAGS=`echo "$TCL_SHLIB_CFLAGS" |sed -e "s|PIC|pic|" -e "s|+Z|+z|"`
	SHLIB_LD=$TCL_SHLIB_LD
	SHLIB_SUFFIX=$TCL_SHLIB_SUFFIX
	DL_LIBS=$TCL_DL_LIBS
	#LD_FLAGS=$TCL_LD_FLAGS
	
	TCL_BASE=`echo ${TCL_LIB_SPEC} |sed -e "s|^.*-l||"`
	TCL_STUB_BASE=`echo ${TCL_STUB_LIB_SPEC} |sed -e "s|^.*-l||"`
	
	AC_SUBST(TCL_LIB_DIR)
	
	if test "x${TCL_INC_SPEC}" != "x" ; then
	TCL_INC_DIR=$TCL_INC_SPEC
	fi
	
	
	if  test "x${TCL_INCLUDE_SPEC}" != "x"; then
	TCL_INC_DIR=$TCL_INCLUDE_SPEC
	fi
	
	if test "x${TCL_INC_DIR}" == "x"; then
	TCL_INC_DIR=$TCL_INCLUDE_DIR
	fi
	
	if test "x${TCL_INC_DIR}" == "x" -a -f ${TCL_PREFIX}/include/tcl.h; then
	TCL_INC_DIR=${TCL_PREFIX}/include
	fi
	
	if test "x${TCL_INC_DIR}" == "x"; then
	AC_MSG_ERROR(You dot not have a devel package of Tcl)
	fi
	
	case $TCL_INC_DIR in
		-I*) ;;
		*) TCL_INC_DIR=-I$TCL_INC_DIR;;
	esac
	
	TCL_INC_SPEC=$TCL_INC_DIR
	
	framework=`echo "${TCL_BASE}" | grep -- "-framework"`
	if test "x${framework}" == "x"; then
	TCL_LIB_SPEC="-L${TCL_LIB_DIR} -l${TCL_BASE}"
	fi
	TCL_STUB_LIB_SPEC="-L${TCL_LIB_DIR} -l${TCL_STUB_BASE}"
	eval "TCL_UNSHARED_LIB_FILE=lib${TCL_BASE}${TCL_UNSHARED_LIB_SUFFIX}"
	eval "TCL_SHARED_LIB_FILE=lib${TCL_BASE}${TCL_SHARED_LIB_SUFFIX}"

AC_SUBST(TCL_STUB_LIB_SPEC)
AC_SUBST(TCL_INC_SPEC)
AC_SUBST(TCL_VERSION)
#AM_CONFIG_HEADER(config.h)
#AC_CONFIG_FILES([Makefile])
AC_CONFIG_HEADERS(config.h)
AC_OUTPUT(Makefile src/Makefile src/plugins/Makefile src/plugins/oss/Makefile src/plugins/alsa/Makefile include/Makefile include/aio/Makefile doc/Makefile test/Makefile tcl/Makefile aio.pc)
