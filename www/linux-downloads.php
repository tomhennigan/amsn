<?php
   define('source', 'linux-downloads');
   include 'common.php';
   include inc . 'init.php';
   include inc . 'header.php';
?>


<?php include 'download-notice.php'?>

<img src="images/download-linux.png" alt="Linux Download" />
<br />
Please select your desired package from one of the drop-down menus:

<br /><br />


<b>aMSN Linux Downloads 32-bit</b>
<script language="JavaScript" type="text/javascript">
function formHandler(form){
        var URL = document.Downloads.Packages.options[document.Downloads.Packages.selectedIndex].value;
        window.location.href = URL;
}
</script>
<noscript>
<br />
<a href="http://prdownloads.sourceforge.net/amsn/amsn-0.95-1.linux-installer.bin">Linux Installer(need llibstdc++.so.6)</a><br />
<a href="http://prdownloads.sourceforge.net/amsn/amsn-0.95.x86.package">AutoPackage</a><br />
<a href="http://prdownloads.sourceforge.net/amsn/amsn_0.95-1.deb">Debian</a><br />
<a href="http://prdownloads.sourceforge.net/amsn/amsn_0.95-1.sarge.deb">Debian (Sarge)</a><br />
<a href="http://prdownloads.sourceforge.net/amsn/amsn_0.95-2.ubuntu.deb">Ubuntu</a><br />
<a href="http://prdownloads.sourceforge.net/amsn/amsn_0.95-ubuntu.powerpc.deb">Ubuntu (PowerPC)</a><br />
<a href="http://prdownloads.sourceforge.net/amsn/amsn-0.95-1.fc3.i686.rpm">Fedora Core 3</a><br />
<a href="http://prdownloads.sourceforge.net/amsn/amsn-0.95-2.fc4.i686.rpm">Fedora Core 4</a><br />
<a href="http://prdownloads.sourceforge.net/amsn/amsn-0.95-1-mdk92.i686.rpm">Mandrake 9.2</a><br />
<a href="http://prdownloads.sourceforge.net/amsn/amsn-0.95-1mdk.i686.rpm">Mandriva 2006 (Formerly Mandrake)</a><br />
<a href="http://prdownloads.sourceforge.net/amsn/amsn-0.95-i486.tgz">Slackware</a><br />
<a href="http://prdownloads.sourceforge.net/amsn/amsn-0.95-1.suse.i586.rpm">SUSE 10.0</a><br />
<a href="http://prdownloads.sourceforge.net/amsn/amsn-0.95-1.archlinux.tar.gz">Archlinux</a><br />
<a href="http://prdownloads.sourceforge.net/amsn/amsn-0.95.ebuild">Gentoo</a><br />
<a href="http://prdownloads.sourceforge.net/amsn/amsn-0.95.tar.gz">Other</a><br />
</noscript>
<form name="Downloads" action="#">
<select name="Packages" onchange="javascript:formHandler()">
<option value="" selected="selected" />

<option value="http://prdownloads.sourceforge.net/amsn/amsn-0.95-1.linux-installer.bin">Linux Installer (need llibstdc++.so.6)</option>
<option value="http://prdownloads.sourceforge.net/amsn/amsn-0.95.x86.package">AutoPackage</option>
<option value="http://prdownloads.sourceforge.net/amsn/amsn_0.95-1.deb">Debian</option>
<option value="http://prdownloads.sourceforge.net/amsn/amsn_0.95-1.sarge.deb">Debian (Sarge)</option>
<option value="http://prdownloads.sourceforge.net/amsn/amsn_0.95-2.ubuntu.deb">Ubuntu</option>
<option value="http://prdownloads.sourceforge.net/amsn/amsn_0.95-ubuntu.powerpc.deb">Ubuntu (PowerPC)</option>
<option value="http://prdownloads.sourceforge.net/amsn/amsn-0.95-1.fc3.i686.rpm">Fedora Core 3</option>
<option value="http://prdownloads.sourceforge.net/amsn/amsn-0.95-2.fc4.i686.rpm">Fedora Core 4</option>
<option value="http://prdownloads.sourceforge.net/amsn/amsn-0.95-1-mdk92.i686.rpm">Mandrake 9.2</option>
<option value="http://prdownloads.sourceforge.net/amsn/amsn-0.95-1mdk.i686.rpm">Mandriva 2006 (Formerly Mandrake)</option>
<option value="http://prdownloads.sourceforge.net/amsn/amsn-0.95-i486.tgz">Slackware</option>
<option value="http://prdownloads.sourceforge.net/amsn/amsn-0.95-1.suse.i586.rpm">SUSE 10.0</option>
<option value="http://prdownloads.sourceforge.net/amsn/amsn-0.95-1.archlinux.tar.gz">Archlinux</option>
<option value="http://prdownloads.sourceforge.net/amsn/amsn-0.95.ebuild">Gentoo</option>
<option value="http://prdownloads.sourceforge.net/amsn/amsn-0.95.tar.gz">Other</option>



<!--<option value="http://www.mteixeira.webset.net/amsn/">Conectiva-->
</select>
</form>

<?php include inc . 'footer.php'; ?>
