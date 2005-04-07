dnl Process this file with autoconf to produce a configure script.
AC_PREREQ(2.53)
AC_INIT(libmimic, 1.0.2)
AC_CONFIG_SRCDIR(libmimic.pc.in)
AM_INIT_AUTOMAKE(AC_PACKAGE_NAME, AC_PACKAGE_VERSION)

AM_MAINTAINER_MODE
AC_PROG_MAKE_SET

dnl Libtool.
AM_PROG_LIBTOOL

AM_CONFIG_HEADER(config.h)

dnl Increment on interface add, remove or change.
MIMIC_CURRENT=0

dnl Increment on source change. Reset when CURRENT changes.
MIMIC_REVISION=1

dnl Increment on interface addition. Reset on removal.
MIMIC_AGE=0

AC_SUBST(MIMIC_CURRENT)
AC_SUBST(MIMIC_REVISION)
AC_SUBST(MIMIC_AGE)

dnl Check for programs.
AC_PROG_CC
AC_PROG_INSTALL

dnl Documentation.
AC_ARG_ENABLE(doxygen-docs, [  --enable-doxygen-docs   build Doxygen documentation],enable_doxygen_docs=$enableval,enable_doxygen_docs=auto)

AC_PATH_PROG(DOXYGEN, doxygen, no)

AC_MSG_CHECKING([whether to build Doxygen documentation])

if test x$DOXYGEN = xno; then
    have_doxygen=no
else
    have_doxygen=yes
fi

if test x$enable_doxygen_docs = xauto; then
    if test x$have_doxygen = xno; then
        enable_doxygen_docs=no
    else
        enable_doxygen_docs=yes
    fi
fi

if test x$enable_doxygen_docs = xyes; then
    if test x$have_doxygen = xno; then
        AC_MSG_ERROR([Building Doxygen docs explicitly required, but Doxygen not found])
    fi
fi

AM_CONDITIONAL(LIBMIMIC_DOXYGEN_DOCS_ENABLED, test x$enable_doxygen_docs = xyes)
AC_MSG_RESULT(yes)

dnl Check for libraries.
PKG_CHECK_MODULES(GLIB, glib-2.0,
  [GLIB_CFLAGS="-DG_DISABLE_DEPRECATED=1 $GLIB_CFLAGS"],
    AC_MSG_ERROR(Cannot find glib-2.0))

dnl Check for header files.
AC_STDC_HEADERS

AC_OUTPUT([
libmimic.pc
Makefile
doc/Makefile
doc/Doxyfile
src/Makefile
])

