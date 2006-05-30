<?php
   define('source', 'download');
   include 'common.php';
   include inc . 'init.php';

   echo '<link rel="stylesheet" type="text/css" media="screen" href="download.css" />';

   include inc . 'header.php';
?>
    <div class="IEFixPNG" id="screenshots">
	  <ul>
           <li>
	      <a href="dlfile.php?file=amsn-0.95.tar.gz" class="screeny"><img class="thumb" src="images/download-tarball.png" alt="Screenshot" /></a>
	      <br />Tarball Source</li>
            <li><a href="linux-downloads.php" class="screeny"><img class="thumb" src="images/download-linux.png" alt="Screenshot" /></a><br />Linux</li>
            <li><a href="http://www.freshports.org/net-im/amsn/" class="screeny"><img class="thumb" src="images/download-freebsd.png" alt="Screenshot" /></a><br />FreeBSD</li>
            <li><a href="dlfile.php?file=amsn-0.95-windows-installer-2.exe" class="screeny"><img class="thumb" src="images/download-windows.png" alt="Screenshot" /></a><br />Windows</li>
            <li><a href="dlfile.php?file=amsn-0-95-final.dmg" class="screeny"><img class="thumb" src="images/download-macosx.png" alt="Screenshot" /></a><br />Mac OS X</li>
            <li><a href="http://sourceforge.net/project/showfiles.php?group_id=54091" class="screeny"><img class="thumb" src="images/download-other.png" alt="Screenshot" /></a><br />Other Packages</li>
            <li><hr width=200> <a href="http://amsn.sourceforge.net/amsn_dev.tar.gz" class="screeny"><img class="thumb" src="images/download-svn.png" alt="Screenshot" /></a><br />Latest development version (SVN Snapshot <?php if (file_exists('amsn_dev.tar.gz')) { echo 'of '.date("F d Y H:i:s.", filectime('amsn_dev.tar.gz')); } ?> )</li>
          </ul>
   </div>

<?php include inc . 'footer.php'; ?>
