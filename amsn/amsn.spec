#
# $Id$
#
%define prefix		/usr

Summary: MSN Messenger clone for Linux
Name: amsn
Version: 0.62
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
%doc README LEEME TODO changelog GNUGPL
/usr/bin/amsn
/usr/share/amsn/README
/usr/share/amsn/amsn
/usr/share/amsn/uninstall.sh
/usr/share/amsn/abook.tcl
/usr/share/amsn/checkver.tcl
/usr/share/amsn/config.tcl
/usr/share/amsn/ctadverts.tcl
/usr/share/amsn/ctdegt.tcl
/usr/share/amsn/ctthemes.tcl
/usr/share/amsn/dkffont.tcl
/usr/share/amsn/emoticons.htm
/usr/share/amsn/groups.tcl
/usr/share/amsn/gui.tcl
/usr/share/amsn/hotmail.tcl
/usr/share/amsn/hotmlog.htm
/usr/share/amsn/langlist
/usr/share/amsn/lang.tcl
/usr/share/amsn/migmd5.tcl
/usr/share/amsn/notebook.tcl
/usr/share/amsn/notebook1.tcl
/usr/share/amsn/progressbar.tcl
/usr/share/amsn/protocol.tcl
/usr/share/amsn/proxy.tcl
/usr/share/amsn/smileys.tcl
/usr/share/amsn/socks.tcl
/usr/share/amsn/icons/amsn.png
/usr/share/amsn/i/amsn.xbm
/usr/share/amsn/i/angel.gif
/usr/share/amsn/i/angry.gif
/usr/share/amsn/i/asl.gif
/usr/share/amsn/i/away.gif
/usr/share/amsn/i/back.gif
/usr/share/amsn/i/baway.gif
/usr/share/amsn/i/bbusy.gif
/usr/share/amsn/i/beer.gif
/usr/share/amsn/i/blocked.gif
/usr/share/amsn/i/boffline.gif
/usr/share/amsn/i/bonline.gif
/usr/share/amsn/i/boyhug.gif
/usr/share/amsn/i/busy.gif
/usr/share/amsn/i/butblock.gif
/usr/share/amsn/i/butfont.gif
/usr/share/amsn/i/butsmile.gif
/usr/share/amsn/i/cake.gif
/usr/share/amsn/i/clk.gif
/usr/share/amsn/i/coctail.gif
/usr/share/amsn/i/colorbar.gif
/usr/share/amsn/i/contract.gif
/usr/share/amsn/i/crooked.gif
/usr/share/amsn/i/devil.gif
/usr/share/amsn/i/disgust.gif
/usr/share/amsn/i/dog.gif
/usr/share/amsn/i/email.gif
/usr/share/amsn/i/emboy.gif
/usr/share/amsn/i/embulb.gif
/usr/share/amsn/i/emcat.gif
/usr/share/amsn/i/emcup.gif
/usr/share/amsn/i/emgirl.gif
/usr/share/amsn/i/emhottie.gif
/usr/share/amsn/i/emnote.gif
/usr/share/amsn/i/emphone.gif
/usr/share/amsn/i/emsleep.gif
/usr/share/amsn/i/emstar.gif
/usr/share/amsn/i/expand.gif
/usr/share/amsn/i/film.gif
/usr/share/amsn/i/fticon.gif
/usr/share/amsn/i/ftreject.gif
/usr/share/amsn/i/gift.gif
/usr/share/amsn/i/girlhug.gif
/usr/share/amsn/i/globe.gif
/usr/share/amsn/i/handcuffs.gif
/usr/share/amsn/i/lips.gif
/usr/share/amsn/i/logolinmsn.gif
/usr/share/amsn/i/love.gif
/usr/share/amsn/i/messenger.gif
/usr/share/amsn/i/messenger.png
/usr/share/amsn/i/msnbot.gif
/usr/share/amsn/i/notifico.gif
/usr/share/amsn/i/offline.gif
/usr/share/amsn/i/online.gif
/usr/share/amsn/i/photo.gif
/usr/share/amsn/i/rainbow.gif
/usr/share/amsn/i/rose.gif
/usr/share/amsn/i/rosew.gif
/usr/share/amsn/i/sad.gif
/usr/share/amsn/i/smilec.gif
/usr/share/amsn/i/smiled.gif
/usr/share/amsn/i/smile.gif
/usr/share/amsn/i/smilemb.gif
/usr/share/amsn/i/smileo.gif
/usr/share/amsn/i/smilep.gif
/usr/share/amsn/i/sun.gif
/usr/share/amsn/i/thumbd.gif
/usr/share/amsn/i/thumbu.gif
/usr/share/amsn/i/typing.gif
/usr/share/amsn/i/unlove.gif
/usr/share/amsn/i/unread.gif
/usr/share/amsn/i/vampire.gif
/usr/share/amsn/i/wink.gif
/usr/share/amsn/s/newemail.wav
/usr/share/amsn/s/online.wav
/usr/share/amsn/s/type.wav
/usr/share/amsn/lang/langal
/usr/share/amsn/lang/langbr
/usr/share/amsn/lang/langca
/usr/share/amsn/lang/langda
/usr/share/amsn/lang/langde
/usr/share/amsn/lang/langen
/usr/share/amsn/lang/langes
/usr/share/amsn/lang/langeu
/usr/share/amsn/lang/langfi
/usr/share/amsn/lang/langfr
/usr/share/amsn/lang/langga
/usr/share/amsn/lang/langgr
/usr/share/amsn/lang/langit
/usr/share/amsn/lang/langja
/usr/share/amsn/lang/langko
/usr/share/amsn/lang/langnl
/usr/share/amsn/lang/langno
/usr/share/amsn/lang/langpt
/usr/share/amsn/lang/langro
/usr/share/amsn/lang/langru
/usr/share/amsn/lang/langsw
/usr/share/amsn/lang/langtr
/usr/share/amsn/lang/langva
/usr/share/amsn/lang/langzh-tw
/usr/share/amsn/lang/missing.py
/usr/share/pixmaps/messenger.png
/etc/X11/applnk/Internet/amsn.desktop

%changelog
* Thu Jun 27 2002  D.E. Grimaldo <lordofscripts AT users.sourceforge.net>
- Added update-menus to post/postun scripts (Manuel Amador)
- Updated file section
* Thu Jun 06 2002 D.E. Grimaldo <lordofscripts AT users.sourceforge.net>
- Created RPM spec file

