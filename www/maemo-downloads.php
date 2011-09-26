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
	<?php echo MAEMO_INSTALL; ?> <br/>
        <a href="http://amsn-project.net/maemo/amsn.install"><img class="toc_icon" src="images/download-other-big.png" alt="AutoPackage"></a><br> <br />

	
	<h3><?php echo SCREENSHOTS_MAEMO; ?></h3> <br/>
	<a href="images/maemo-screenshot1.png"><img width="100%" src="images/maemo-screenshot1.png"> <br/></a>
	<a href="images/maemo-screenshot2.png"><img width="100%" src="images/maemo-screenshot2.png"> <br/></a>
	<a href="images/maemo-screenshot3.png"><img width="100%" src="images/maemo-screenshot3.png"> <br/></a>
	<br>

<?php include inc . 'footer.php'; ?>
