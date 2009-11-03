<?php
   define('source', 'plugins');
   include 'common.php';
   include inc . 'init.php';

   echo '<link rel="stylesheet" type="text/css" media="screen" href="plugins.css" />';

   include inc . 'header.php';
?>

<div>
        <strong><?= FULL_FEATURES; ?></strong><?= PLUGIN_DESC;?>
        <br /><br />
           <?= INSTALL_PLUGIN; ?>
        <br /><br />
            <?= SUBMIT_PLUGIN; ?>
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
<a name="<?= $plugin['id']?>" />
  <ul class="plugins">
    <li class="plugintitle"><?= $plugin['name'] ?></li>
    <li class="lg"><?= trans($plugin['id'], 'plugin', $plugin['desc']);//plugin desc ?></li>
    <li class="dg"><?= CREATEDBY_PLUGIN.$plugin['author']; ?></li>
    <li class="lg"> <?= VERSION_PLUGIN.$plugin['version']; ?></li>
    <li class="dg"> <?= PLATFORM_PLUGIN.$plugin['platform']; ?></li>
    <li class="lg"><?= REQUIRES_PLUGIN.$plugin['requires']; ?></li>
<?php 
		if (getFileURL($plugin['screen_id']) != '') {
?>
    <li class="dg"><a href="getURL.php?id=<?= $plugin['screen_id']?>" title="&lt;img src='thumb.php?id=<?= $plugin['screen_id'] ?>' /&gt;"><strong><?= SCREENSHOTS_PLUGIN; ?> </strong></a></li>
<?php 
		}
		else {
?>
    <li class="dg"><strong> <?= NOSCREEN_PLUGIN; ?> </strong></li>
<?php
		}

		if (getFileURL($plugin['file_id']) != '') {
?>
    <li class="lg"><a href="getURL.php?id=<?= $plugin['file_id']?>"><strong><?= DOWN_PLUGIN; ?></strong></a></li>
<?php
		}
		else {
?>
    <li class="lg"><strong><?= DOWN_SOON_PLUGIN; ?></strong></li>
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
<div style="text-align:center"><strong><a href="#top"><?= BACK_TOP_PLUGIN; ?></a></strong></div>

</div>
<?php include inc . 'footer.php'; ?>
