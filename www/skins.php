<?php
   define('source', 'skins');
   include 'common.php';
   include inc . 'init.php';

   echo '<link rel="stylesheet" type="text/css" media="screen" href="skins.css" />';

   include inc . 'header.php';
?>

<div>
<? echo '
        <strong>'.LOVES_CUSTOM.'</strong>'.SKIN_DESC.'<br /><br />
        '.INSTALL_SKIN.'
        <br /><br />
        '.SUBMIT_SKIN; ?>
	<br /><br />

<a name="top">
	<br />
</a>

<script type="text/javascript" src="libs/addEvent.js"></script>
<script type="text/javascript" src="libs/sweetTitles.js"></script>

<?php

if (!mysql_num_rows(($q = mysql_query("SELECT `amsn_skins`.*, (UNIX_TIMESTAMP(`amsn_files`.`lastmod`)-UNIX_TIMESTAMP(20070101))/86400+`amsn_files`.`count`/15 AS `score` FROM `amsn_skins` INNER JOIN `amsn_files` ON `amsn_files`.`id` = `amsn_skins`.`file_id` ORDER BY `score` DESC")))) {
    echo '<p>'.NO_SKIN."</p>\n";
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
    <li class="lg"><?php echo $skin['desc'.$lang_set] ?></li>
    <li class="dg"><?php echo CREATEDBY_SKIN.$skin['author'] ?></li>
    <li class="lg"><?php echo VERSION_SKIN.$skin['version'] ?></li>
<?php 
		if (getFileURL($skin['screen_id']) != '') {
?>
    <li class="dg"><a href="getURL.php?id=<?php echo $skin['screen_id'] ?>" title="&lt;img src='thumb.php?id=<?php echo $skin['screen_id'] ?>' /&gt;"><strong><?php echo SCREENSHOTS_SKIN; ?></strong></a></li>
<?php 
		}
		else {
?>
    <li class="dg"><strong><?php echo NOSCREEN_SKIN; ?></strong></li>
<?php
		}

		if (getFileURL($skin['file_id']) != '') {
?>
    <li class="lg"><a href="getURL.php?id=<?php echo $skin['file_id'] ?>"><strong><?php echo DOWN_SKIN; ?></strong></a></li>
<?php
		}
		else {
?>
    <li class="lg"><strong><?php echo DOWN_SOON_SKIN; ?></strong></li>
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
<div style="text-align:center"><strong><a href="#top"><?php echo BACK_TOP_SKIN; ?></a></strong></div>
</div>

<?php include inc . 'footer.php';?>
