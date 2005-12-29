<?php
   define('source', 'skins');
   include 'common.php';
   include inc . 'init.php';

   echo '<link rel="stylesheet" type="text/css" media="screen" href="skins.css" />';

   include inc . 'header.php';
?>


        <strong>aMSN loves customization!</strong>,
	and one way to customise it is to change its "skin". A skin changes the
	look of aMSN. Here you can download skins developed by aMSN and by
	contributors. <br /><br />
        You can find instructions on how to install skins in our <a href="http://amsn.sourceforge.net/wiki/tiki-index.php?page=Installing+Plugins+and+Skins">skin and plugin installation guide</a>.
        <br /><br />
	If you would like to submit your skin to this page, email it as a zip
	archive to amsn-skins at lists dot sourceforge dot net. Please include
	a screenshot, description, and which version(s) of aMSN it is for.
	<br /><br />

	<center><strong>0.95 Skins</strong></center>
	<br />
<?php
foreach($skins as $skin) {
	echo '<table class="skins">';
	echo " <tbody><tr>\n";
        echo "  <td>\n";
	echo "   <ul>\n";
	echo '    <li class="skintitle">'.$skin[0]."</li>\n";
	echo '    <li class="lg">'.$skin[1]."</li>\n";
	echo '    <li class="dg">Created by: '.$skin[2]." </li>\n";
	if($skin[3]>0)
		echo '    <li class="lg"><a href="http://amsn.sourceforge.net/wiki/show_image.php?id='.$skin[3].'"><strong>Screenshot</strong></a></li>'."\n";
	if($skin[4]!='')
		echo '    <li class="dg"><a href="http://prdownloads.sourceforge.net/amsn/'.$skin[4].'"><strong>Download this skin</strong></a></li>'."\n";
	else
		echo '    <li class="dg"><strong>Download comming soon!</strong></li>'."\n";
	echo "   </ul>\n";
	echo "  </td>\n";
	echo " </tr>\n";
	echo " </tbody>\n";
	echo "</table>\n";
	echo "<br/>\n";
}
?>

<center><strong><a href="skins094.php">0.94 skins</a></strong></center>

<?php include inc . 'footer.php';?>
