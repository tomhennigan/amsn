#
# $Id$
#
%define prefix		/usr

Summary: MSN Messenger clone for Linux
Name: amsn
Version: 0.70
Release: 1
Copyright: GPL
Group: Applications/Internet
Source0: ftp://ftp.sourceforge.net/projects/amsn/%{name}-%{version}-%{release}.tar.gz
Prereq: tcl tk
BuildRoot: %{_tmppath}/%{name}-root

%description
This is Tcl/Tk clone that implements the Microsoft Messenger (MSN)
for Unix,Windows, or Macintosh platforms. It supports file transfers,
groups, and many more features. Visit http://amsn.sourceforge.net/ for
details. This is an ongoing project, and it is already going pretty well.

%prep
%setup -q

%build

# Pre Install
%pre

%install

%define localroot	${RPM_BUILD_ROOT}%{prefix}
%define gnomelinks	/etc/X11/applnk/Internet
%define kdelinks	/usr/share/applnk/Internet
%define wmapps		${RPM_BUILD_ROOT}%{gnomelinks}
%define docdirname	%{name}-%{version}
#make  localroot=%{localroot} prefix=%{prefix} version=%{version} wmapps=%{wmapps} install
make  proot=%{prefix} prefix=${RPM_BUILD_ROOT}%{prefix} version=%{version} wmapps=%{wmapps} install

ln -sf %{prefix}/share/amsn/amsn ${RPM_BUILD_ROOT}%{prefix}/bin/amsn
ln -sf %{prefix}/share/doc/%{docdirname}/README ${RPM_BUILD_ROOT}%{prefix}/share/amsn/README

%clean
#rm -rf ${RPM_BUILD_ROOT}
#echo clean ${RPM_BUILD_ROOT}

# Post Install
%post
if test -x /usr/bin/update-menus; then /usr/bin/update-menus; fi

# Before Uninstall (Triggers get executed at this stage too)
%preun
rm -f %{prefix}/share/amsn/README

# Tasks after Uninstall
%postun
rm -f %{prefix}/bin/amsn
if test -x /usr/bin/update-menus; then /usr/bin/update-menus; fi

%files
%doc README LEEME TODO changelog GNUGPL FAQ HELP
/usr/bin/amsn
/usr/share/amsn/*
/usr/share/amsn/i/*
/usr/share/amsn/s/*
/usr/share/amsn/lang/*
/usr/share/pixmaps/messenger.png
/etc/X11/applnk/Internet/amsn.desktop

%changelog
* Mon Nov 25 2002  Olivier Crete <tester@tester.ca>
- Fix it for version 0.70
* Thu Jun 27 2002  D.E. Grimaldo <lordofscripts AT users.sourceforge.net>
- Added update-menus to post/postun scripts (Manuel Amador)
- Updated file section
* Thu Jun 06 2002 D.E. Grimaldo <lordofscripts AT users.sourceforge.net>
- Created RPM spec file

