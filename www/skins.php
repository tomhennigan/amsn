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
        You can find instructions on how to install skins in our <a href="http://amsn.sourceforge.net/devwiki/tiki-index.php?page=Installing+Plugins+and+Skins">skin and plugin installation guide</a>.
        <br /><br />
        If you would like to submit your skin to this page, please read the <a href="http://amsn.sourceforge.net/devwiki/tiki-index.php?page=Skin+and+plugin+submitting+guide">skin submitting guide</a>.
	<br /><br />

<a name="top">
	<br />
</a>

<script type="text/javascript" src="libs/addEvent.js"></script>
<script type="text/javascript" src="libs/sweetTitles.js"></script>

<?php

if (!mysql_num_rows(($q = mysql_query("SELECT *  FROM `amsn_skins` ORDER BY `name`")))) {
    echo "<p>There are no skins available.</p>\n";
} else {
	$elements_per_line=5;
	$i = 0;
	echo '<div style="text-align:center">';
	while ($skin = mysql_fetch_assoc($q)) {
		if ($i > 0 )
			echo ' | ';
		echo '<a href="#'. $skin['id']. '"> ' . $skin['name'] . ' </a>';
		$i = $i + 1;
        	if ($i == $elements_per_line) {
			echo "<br />\n";
			$i = 0;
        	}
	}
	echo "</div> <br/> <br/>\n";
	mysql_data_seek($q, 0);
	while ($skin = mysql_fetch_assoc($q)) {
?>
<a name="<?php echo $skin['id']?>" />
  <ul class="skins">
    <li class="skintitle"><?php echo $skin['name'] ?></li>
    <li class="lg"><?php echo $skin['desc'] ?></li>
    <li class="dg">Created by: <?php echo $skin['author'] ?></li>
<?php 
		if (getFileURL($skin['screen_id']) != '') {
?>
    <li class="lg"><a href="getURL.php?id=<?php echo $skin['screen_id'] ?>" title="&lt;img src='thumb.php?id=<?php echo $skin['screen_id'] ?>' /&gt;"><strong>Screenshot</strong></a></li>
<?php 
		}
		else {
?>
    <li class="lg"><strong>No screenshot</strong></li>
<?php
		}

		if (getFileURL($skin['file_id']) != '') {
?>
    <li class="dg"><a href="getURL.php?id=<?php echo $skin['file_id'] ?>"><strong>Download this skin</strong></a></li>
<?php
		}
		else {
?>
    <li class="dg"><strong>Download comming soon!</strong></li>
<?php
		}
?>
  </ul>
<br />
<?php
	}
}
?>

<br/><br/>
<div style="text-align:center"><strong><a href="#top">Back to top</a></strong></div>


<?php include inc . 'footer.php';?>
