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
<li><a href="linux-downloads.php" class="screeny"><img class="thumb" src="images/download-linux.png" alt="Linux"></a><br><?=LINUX_DOWN;?></li>
<li><a href="http://sourceforge.net/projects/amsn/files/amsn/0.98.1/aMSN-0.98.1-tcl85-windows-installer.exe/download" class="screeny"><img class="thumb" src="images/download-windows.png" alt="Windows" ></a><br ><?=WIN_DOWN;?></li>
<li><a href="http://sourceforge.net/projects/amsn/files/amsn/0.98.1/aMSN-0.98.1-tcl84-windows-installer.exe/download" class="screeny"><img class="thumb" src="images/download-windows.png" alt="Windows" ></a><br><?=WIN95_DOWN;?></li>
<li><a href="http://sourceforge.net/projects/amsn/files/amsn/0.98.1/aMSN-0.98.1-1.dmg/download" class="screeny"><img class="thumb" src="images/download-macosx.png" alt="MacOSX" ></a><br ><?=MACOSX_DOWN;?></li>
<li><a href="http://www.freshports.org/net-im/amsn/" class="screeny"><img class="thumb" src="images/download-freebsd.png" alt="FreeBSD" ></a><br ><?=FREEBSD_DOWN;?></li>
<li><a href="http://sourceforge.net/projects/amsn/files/amsn/0.98.1/amsn-0.98.1.tar.gz/download" class="screeny"><img class="thumb" src="images/download-tarball.png" alt="Tarball"></a><br><?=TARBALL_DOWN;?></li>
     </ul>
    </li>
    <li>
     <br /><hr style="width:200px;" >
     <ul>
<li><a href="http://amsn.sourceforge.net/amsn_dev.tar.gz" class="screeny"><img class="thumb" src="images/download-svn.png" alt="SVN Snapshot" ></a><br ><?=LATEST_SVN;?>
<?php
  if (file_exists('amsn_dev.tar.gz')) {
    echo ' '.strftime(TIME_FORMAT, filectime('amsn_dev.tar.gz'));
  } 
  echo ')</li>';
?>
     </ul>
    </li></ul>
   </div>

<?php include inc . 'footer.php'; ?>
