# Installation prefix:
%define _prefix		/usr

# Version information:
%define _version	0.71
%define __release	1

# Category for .desktop file:
%define _applnk_cat	Internet

# Default paths for KDE and GNOME .desktop files,
# may be overriden by distribution-specific settings
%define _kde_applnk	/usr/share/applnk
%define _gnome_applnk	/etc/X11/applnk

%define _src_version	%(echo %_version|%{__sed} 's/\\./_/g')

# Default is not to set the distribution tag
%define _has_distribution 0

####################################################################################
# Distribution-specific customization
#
### Autodetect distribution
%define _suse		%(if [ -e /etc/SuSE-release ]; then echo 1; else echo 0; fi)

### Begin - SuSE Linux
# (has different paths for KDE and GNOME)
%if %_suse
%define _not_suse	0
# retrieve SuSE version
%define _suse_version	%(grep VERSION /etc/SuSE-release|cut -f3 -d" ")
%define _suse_ver_num	%(echo %_suse_version|tr -d '.')

%define _has_distribution 1
%define _distribution	SuSE Linux %{_suse_version}

%define _release	%{__release}suse

%define _gnome_applnk	/opt/gnome/etc/X11/applnk

# determine KDE version/directory based on SuSE version:
%define _suse_kde3	%(if [ %_suse_ver_num -ge 80 ]; then echo 1; else echo 0; fi)
%define _suse_kde2	%(if [ %_suse_ver_num -lt 80 ]; then echo 1; else echo 0; fi)
%define _kde3_applnk	/opt/kde3/share/applnk
%define _kde2_applnk	/opt/kde2/share/applnk
# define some dummy directory to install file, will be copied afterwards for SuSE
%define _kde_applnk	/opt/kde/share/applnk
%else
%define _not_suse	1
%define _release	%{__release}
%endif
### End - SuSE Linux
####################################################################################

Summary:	MSN Messenger clone for Linux
Summary(fr):	Clône MSN Messenger pour Linux
Summary(de):	MSN Messenger-Klon für Linux
Name:		amsn
Version:	%{_version}
Release:	%{_release}
Copyright:	GPL
Group:		Productivity/Networking/InstantMessaging
URL:		http://amsn.sourceforge.net/
Source:		ftp://ftp.sourceforge.net/projects/amsn/%{name}-%{_src_version}.tar.gz
Requires:	tcl >= 8.4
Requires:	tk >= 8.4
BuildRoot:	%{_tmppath}/build-%{name}-%{_version}
Packager:	Pascal Bleser <guru@unixtech.be>
BuildArch:	noarch
%if %_has_distribution
Distribution:	%{_distribution}
%endif

%description
This is Tcl/Tk clone that implements the Microsoft Messenger (MSN) for
Unix,Windows, or Macintosh platforms. It supports file transfers,
groups, and many more features. Visit http://amsn.sourceforge.net/ for
details. This is an ongoing project, and it is already going pretty
well.

%description -l fr
amsn est un client Microsoft Messenger (MSN) pour UNIX, Windows et
Macintosh écrit en Tcl/Tk.  Il supporte les tranferts de fichiers, les
groupes et beaucoup d'autres possibilités. 
Visitez http://amsn.sourceforge.net/ pour de plus amples détails.

%description -l de
amsn ist ein Microsoft Messenger (MSN) Client für UNIX, Windows und
Macintosh, der in Tcl/Tk geschrieben ist. Es unterstützt
Dateiübertragungen, Gruppen uvm.
Begeben Sie sich auf http://amsn.sourceforge.net/ um mehr über dieses
Projekt zu erfahren.

%prep
%setup -q -n "msn"
%patch0
%patch1
%patch2

%build
%{__mv} amsn.desktop amsn.desktop.in
%{__sed} -e "s+@@ICON_PATH@@+%{_datadir}/amsn/i+g" \
	< amsn.desktop.in \
	> amsn.desktop

%install
%{__mkdir_p} "${RPM_BUILD_ROOT}%{_prefix}"

%{__make} \
   	proot="%{_prefix}" \
	prefix="${RPM_BUILD_ROOT}%{_prefix}" \
	version="%{_version}" \
	gnomelinks="${RPM_BUILD_ROOT}%{_gnome_applnk}/%{_applnk_cat}" \
	kdelinks="${RPM_BUILD_ROOT}%{_kde_applnk}/%{_applnk_cat}" \
	install

%{__mkdir_p} "${RPM_BUILD_ROOT}%{_bindir}"
%{__ln_s} -f "%{_datadir}/amsn/amsn" "${RPM_BUILD_ROOT}%{_bindir}/amsn"
%{__ln_s} -f "${RPM_DOC_DIR}/amsn-{_version}/README" "${RPM_BUILD_ROOT}%{_datadir}/amsn/README"

# manually copy the .desktop file for KDE, it's broken in the Makefile
%{__mkdir_p} "${RPM_BUILD_ROOT}%{_kde_applnk}/%{_applnk_cat}/"
%{__cp} "${RPM_BUILD_ROOT}%{_gnome_applnk}/%{_applnk_cat}"/*.desktop \
	"${RPM_BUILD_ROOT}%{_kde_applnk}/%{_applnk_cat}/"
#
# SuSE-specific handling of KDE2 and/or KDE3
#
%if %_suse_kde2
%{__mkdir_p} "${RPM_BUILD_ROOT}%{_kde2_applnk}/%{_applnk_cat}/"
%{__cp} "${RPM_BUILD_ROOT}%{_kde_applnk}/%{_applnk_cat}"/*.desktop \
	"${RPM_BUILD_ROOT}%{_kde2_applnk}/%{_applnk_cat}/"
%endif
%if %_suse_kde3
%{__mkdir_p} "${RPM_BUILD_ROOT}%{_kde3_applnk}/%{_applnk_cat}/"
%{__cp} "${RPM_BUILD_ROOT}%{_kde_applnk}/%{_applnk_cat}"/*.desktop \
	"${RPM_BUILD_ROOT}%{_kde3_applnk}/%{_applnk_cat}/"
%endif

%clean
%{__rm} -rf "${RPM_BUILD_ROOT}"

# Post Install
%post
test -x /usr/bin/update-menus && /usr/bin/update-menus

# Tasks after Uninstall
%postun
test -x /usr/bin/update-menus && /usr/bin/update-menus

%files
%doc FAQ GNUGPL HELP LEEME rEADME TODO changelog
%{_bindir}/amsn
%{_datadir}/amsn
%{_gnome_applnk}/%{_applnk_cat}/*.desktop
%if %_not_suse
%{_kde_applnk}/%{_applnk_cat}/*.desktop
%endif
%if %_suse_kde3
%{_kde3_applnk}/%{_applnk_cat}/*.desktop
%endif
%if %_suse_kde2
%{_kde2_applnk}/%{_applnk_cat}/*.desktop
%endif

%changelog
* Wed Nov 27 2002 Pascal Bleser <guru@unixtech.be> 0.71-1
- added BuildArch, set to noarch
- added french and german translations for summary and description
- added myself as the packager ;-)
- added patch to .desktop file to use full path to .png file out of amsn %_datadir
- many other changes and enhancements
- added %define's at top of file for easier maintaining
- cleaned up %files section
- made more portable: SuSE autodetected and sets paths accordingly (KDE and GNOME)
- added _-macros
- revamped spec-file

* Thu Jun 27 2002  D.E. Grimaldo <lordofscripts AT users.sourceforge.net>
- Added update-menus to post/postun scripts (Manuel Amador)
- Updated file section

* Thu Jun 06 2002 D.E. Grimaldo <lordofscripts AT users.sourceforge.net>
- Created RPM spec file
