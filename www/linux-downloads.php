<?php
   define('source', 'linux-downloads');
   include 'common.php';
   include inc . 'init.php';
   include inc . 'header.php';
?>

<img src="images/download-linux.png" alt="Linux Download" />
<br />
Please select your desired package from one of the drop-down menus:

<br /><br />


<b>aMSN Linux Downloads 32-bit</b>
<form action="dlfile.php" method="GET">
<p>
<select class="dlselector" name="file" onchange="this.form.submit()">
<option value="" selected="selected" />
<option value="amsn-0.96RC1-linux-installer.bin">Bitrock Installer</option>
<option value="amsn-0.96-1.tcl84.x86.package">AutoPackage</option>
<option value="amsn_0.96rc1-1.i386.stable.deb">Debian</option>
<option value="amsn_0.96rc1-1.i386.testing.deb">Debian (Sarge)</option>
<option value="amsn_0.96RC1-1kubuntu1_i386.deb">KUbuntu</option>
<option value="amsn_0.96RC1-1.deb">Ubuntu</option>
<option value="amsn_0.96rc1-PPC.deb">Ubuntu (PowerPC)</option>
<option value="amsn-0.96RC1-1.fc4.i686.rpm">Fedora Core 4</option>
<option value="amsn-0.96RC1-1-mandriva.i686.rpm">Mandriva 2006 (Formerly Mandrake)</option>
<option value="amsn-0.96RC1-i686.tgz">Slackware</option>
<option value="amsn-0.96RC1-1-suse.i686.rpm">SUSE 10.0</option>
<option value="amsn-0.96RC1-1.archlinux.pkg.tar.gz">Archlinux</option>
<option value="amsn-0.96_rc1.ebuild">Gentoo</option>
<option value="amsn-0.96RC1.tar.gz">Other</option>
</select>
<input type="submit" value="Download"/>
</p>
</form>

<br /><br />
<b>aMSN Linux Downloads 64-bit</b>
<form action="dlfile.php" method="GET">
<p>
<select class="dlselector" name="file" onchange="this.form.submit()">
<option value="" selected="selected" />
<option value="amsn-0.95-1.linux-installer.x86_64.bin">Linux Installer</option>
<option value="amsn-0.95-1.x86_64.package">AutoPackage</option>
<option value="amsn-0.96.tar.bz2">Other</option>
</select>
<input type="submit" value="Download"/>
</p>
</form>

<?php include inc . 'footer.php'; ?>
