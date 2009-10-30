<?php
   define('source', 'plugins');
   include 'common.php';
   include inc . 'init.php';

   echo '<link rel="stylesheet" type="text/css" media="screen" href="plugins.css" />';

   include inc . 'header.php';
?>

<div>
        <strong><?php echo FULL_FEATURES; ?></strong><?php echo PLUGIN_DESC;?>
        <br /><br />
           <?php echo INSTALL_PLUGIN; ?>
        <br /><br />
            <?php echo SUBMIT_PLUGIN; ?>
        <br /><br />

<a name="top">
	<br />
</a>

<script type="text/javascript" src="libs/addEvent.js"></script>
<script type="text/javascript" src="libs/sweetTitles.js"></script>

<?php

if (!mysql_num_rows(($q = mysql_query("SELECT `amsn_plugins`.*, (UNIX_TIMESTAMP(`amsn_files`.`lastmod`)-UNIX_TIMESTAMP(20070101))/86400+`amsn_files`.`count`/15 AS `score` FROM `amsn_plugins` INNER JOIN `amsn_files` ON `amsn_files`.`id` = `amsn_plugins`.`file_id` ORDER BY `score` DESC")))) {
    echo '<p>'.NO_PLUGINS."</p>\n";
} else {
	$elements_per_line=5;
	$i = 0;
	echo '<div style="text-align:center">';
	while ($plugin = mysql_fetch_assoc($q)) {
		if ($i > 0 )
			echo ' | ';
		echo '<a href="#'. $plugin['id']. '"> ' . $plugin['name'] . ' </a>';
		$i = $i + 1;
        	if ($i == $elements_per_line) {
			echo "<br />\n";
			$i = 0;
        	}
	}
	echo "</div> <br/> <br />\n";
	mysql_data_seek($q, 0);
	while ($plugin = mysql_fetch_assoc($q)) {
?>
<a name="<?php echo $plugin['id']?>" />
  <ul class="plugins">
    <li class="plugintitle"><?php echo $plugin['name'] ?></li>
    <li class="lg"><?php echo trans($plugin['id'], 'plugin', $plugin['desc']);//plugin desc ?></li>
    <li class="dg"><?php echo CREATEDBY_PLUGIN.$plugin['author']; ?></li>
    <li class="lg"> <?php echo VERSION_PLUGIN.$plugin['version']; ?></li>
    <li class="dg"> <?php echo PLATFORM_PLUGIN.$plugin['platform']; ?></li>
    <li class="lg"><?php echo REQUIRES_PLUGIN.$plugin['requires']; ?></li>
<?php 
		if (getFileURL($plugin['screen_id']) != '') {
?>
    <li class="dg"><a href="getURL.php?id=<?php echo $plugin['screen_id']?>" title="&lt;img src='thumb.php?id=<?php echo $plugin['screen_id'] ?>' /&gt;"><strong><?php echo SCREENSHOTS_PLUGIN; ?> </strong></a></li>
<?php 
		}
		else {
?>
    <li class="dg"><strong> <?php echo NOSCREEN_PLUGIN; ?> </strong></li>
<?php
		}

		if (getFileURL($plugin['file_id']) != '') {
?>
    <li class="lg"><a href="getURL.php?id=<?php echo $plugin['file_id']?>"><strong><?php echo DOWN_PLUGIN; ?></strong></a></li>
<?php
		}
		else {
?>
    <li class="lg"><strong><?php echo DOWN_SOON_PLUGIN; ?></strong></li>
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
<div style="text-align:center"><strong><a href="#top"><?php echo BACK_TOP_PLUGIN; ?></a></strong></div>

</div>
<?php include inc . 'footer.php'; ?>
