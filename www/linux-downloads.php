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
<option value="amsn-0.95-2.linux-installer.bin">Bitrock Installer</option>
<option value="amsn-0.95-2.x86.package">AutoPackage</option>
<option value="amsn_0.95-3.deb">Debian</option>
<option value="amsn_0.95-1.sarge.deb">Debian (Sarge)</option>
<option value="amsn_0.95-3.ubuntu.deb">Ubuntu</option>
<option value="amsn_0.95-ubuntu.powerpc.deb">Ubuntu (PowerPC)</option>
<option value="amsn-0.95-3.fc3.i686.rpm">Fedora Core 3</option>
<option value="amsn-0.95-3.fc4.i686.rpm">Fedora Core 4</option>
<option value="amsn-0.95-1-mdk92.i686.rpm">Mandrake 9.2</option>
<option value="amsn-0.95-3mdk.i686.rpm">Mandriva 2006 (Formerly Mandrake)</option>
<option value="amsn-0.95-i486.tgz">Slackware</option>
<option value="amsn-0.95-2.suse.i586.rpm">SUSE 10.0</option>
<option value="amsn-0.95-1.archlinux.tar.gz">Archlinux</option>
<option value="amsn-0.95.tar.gz">Other</option>
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
<option value="amsn-0.95.tar.gz">Other</option>
</select>
<input type="submit" value="Download"/>
</p>
</form>

<?php include inc . 'footer.php'; ?>
