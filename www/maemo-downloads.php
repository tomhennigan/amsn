<?php
   define('source', 'download');
   include 'common.php';
   include inc . 'init.php';

   echo '<link rel="stylesheet" type="text/css" media="screen" href="download.css" />';
   
   include inc . 'header.php';
?>

<br>
<img style="display: block;margin-left: auto;margin-right: auto;" src="images/download-maemo.png" alt="Maemo Download" ><br>
	<a name="INSTALL"></a>
	<?= MAEMO_INSTALL ;?> <br/>
        <a href="http://amsn-project.net/maemo/amsn.install"><img class="toc_icon" src="images/download-other-big.png" alt="AutoPackage"></a><br> <br />

	<a
	<h3><?=SCREENSHOTS_MAEMO;?></h3> <br/>
	<img src="images/maemo-screenshot1.png" /> <br/>
	<img src="images/maemo-screenshot2.png" /> <br/>
	<img src="images/maemo-screenshot3.png" /> <br/>
	<img src="images/maemo-screenshot4.png" /> <br/>
	<dl>
	<dt>
	</dt>
        </dl>
    <br>
<?php include inc . 'footer.php'; ?>
