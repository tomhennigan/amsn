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

<?php
  echo '<li><a href="linux-downloads.php" class="screeny"><img class="thumb" src="images/download-linux.png" alt="Linux" /></a><br />'.LINUX_DOWN.'</li>';
  echo'<li><a href="http://prdownloads.sourceforge.net/amsn/aMSN-0.97.2-tcl85-windows-installer.exe" class="screeny"><img class="thumb" src="images/download-windows.png" alt="Windows" /></a><br />'.WIN_DOWN.'</li>';
  echo '<li><a href="http://prdownloads.sourceforge.net/amsn/aMSN-0.97.2-tcl84-windows-installer.exe" class="screeny"><img class="thumb" src="images/download-windows.png" alt="Windows" /></a><br />'.WIN95_DOWN.'</li>';
  echo '<li><a href="http://prdownloads.sourceforge.net/amsn/amsn-0-97-final2-2.dmg" class="screeny"><img class="thumb" src="images/download-macosx.png" alt="MacOSX" /></a><br />'.MACOSX_DOWN.'</li>';
  echo '<li><a href="http://www.freshports.org/net-im/amsn/" class="screeny"><img class="thumb" src="images/download-freebsd.png" alt="FreeBSD" /></a><br />'.FREEBSD_DOWN.'</li>';
  echo '<li><a href="http://prdownloads.sourceforge.net/amsn/amsn-0.97.2.tar.bz2" class="screeny"><img class="thumb" src="images/download-tarball.png" alt="Tarball" /></a><br />'.TARBALL_DOWN.'</li>';
?>

     </ul>
    </li>
    <li>
     <br /><hr style="width:200px;" />
     <ul>

<?php
  echo '<li><a href="http://amsn.sourceforge.net/amsn_dev.tar.gz" class="screeny"><img class="thumb" src="images/download-svn.png" alt="SVN Snapshot" /></a><br />'.LATEST_SVN.':';

  if (file_exists('amsn_dev.tar.gz')) {
    echo ' '.date("F d Y H:i:s.", filectime('amsn_dev.tar.gz'));
  } 
  echo ')</li>';
?>
     </ul>
    </li></ul>
   </div>

<?php include inc . 'footer.php'; ?>
