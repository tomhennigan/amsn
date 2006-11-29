<?php
   define('source', 'download');
   include 'common.php';
   include inc . 'init.php';

   echo '<link rel="stylesheet" type="text/css" media="screen" href="download.css" />';

   include inc . 'header.php';
?>
   <div class="IEFixPNG" id="screenshots">
    <ul><li>
     <ul>
       <li><a href="linux-downloads.php" class="screeny"><img class="thumb" src="images/download-linux.png" alt="Linux" /></a><br />Linux</li>
       <li><a href="http://prdownloads.sourceforge.net/amsn/aMSN-0.96-3-windows-installer.exe" class="screeny"><img class="thumb" src="images/download-windows.png" alt="Windows" /></a><br />Windows</li>
       <li><a href="http://prdownloads.sourceforge.net/amsn/amsn_0-96-mac.dmg" class="screeny"><img class="thumb" src="images/download-macosx.png" alt="MacOSX" /></a><br />Mac OS X  (Universal)</li>
       <li><a href="http://www.freshports.org/net-im/amsn/" class="screeny"><img class="thumb" src="images/download-freebsd.png" alt="FreeBSD" /></a><br />FreeBSD</li>
       <li><a href="http://prdownloads.sourceforge.net/amsn/amsn-0.96.tar.bz2" class="screeny"><img class="thumb" src="images/download-tarball.png" alt="Tarball" /></a><br />Tarball Source</li>
     </ul>
    </li>
    <li>
     <br /><hr style="width:200px;" />
     <ul>
       <li><a href="http://amsn.sourceforge.net/amsn_dev.tar.gz" class="screeny"><img class="thumb" src="images/download-svn.png" alt="SVN Snapshot" /></a><br />Latest development version (SVN Snapshot <?php if (file_exists('amsn_dev.tar.gz')) { echo 'of '.date("F d Y H:i:s.", filectime('amsn_dev.tar.gz')); } ?> )</li>
     </ul>
    </li></ul>
   </div>

<?php include inc . 'footer.php'; ?>
