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
	<?= MAEMO_INSTALL ;?>
        <a href="http://amsn-project.net/maemo/amsn.install"><img class="toc_icon" src="images/download-other-big.png" alt="AutoPackage"></a><br>

	<a
	<h3><?=SCREENSHOTS_MAEMO;?></h3>
	<img src="images/screenshot-maemo1.png" />
	<img src="images/screenshot-maemo2.png" />
	<img src="images/screenshot-maemo3.png" />
	<img src="images/screenshot-maemo4.png" />
	<dl>
	<dt>
	</dt>
        </dl>
    <br>
<?php include inc . 'footer.php'; ?>
