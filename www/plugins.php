<?php
   define('source', 'plugins');
   include 'common.php';
   include inc . 'init.php';

   echo '<link rel="stylesheet" type="text/css" media="screen" href="plugins.css" />';

   include inc . 'header.php';
?>

<div>
        <strong>aMSN is full of features</strong>, but you can extend its functionality even more now, getting extra features by installing plugins. Plugins are simply that - they "plug in" to aMSN and give it extra features. Here you can download plugins developed by us and by contributors. Make sure you have the right version of aMSN for the plugin (check "requirements") and the right OS (check "platform")
        <br /><br />
        You can find instructions on how to install plugins in our <a href="http://amsn.sourceforge.net/devwiki/tiki-index.php?page=Installing+Plugins+and+Skins">skin and plugin installation guide</a>.
        <br /><br />
        If you would like to submit your plugin to this page, please read the <a href="http://amsn.sourceforge.net/devwiki/tiki-index.php?page=Skin+and+plugin+submitting+guide">plugin submitting guide</a>.
        <br /><br />

<a name="top">
	<br />
</a>

<script type="text/javascript" src="libs/addEvent.js"></script>
<script type="text/javascript" src="libs/sweetTitles.js"></script>

<?php

if (!mysql_num_rows(($q = mysql_query("SELECT `amsn_plugins`.*, (UNIX_TIMESTAMP(`amsn_files`.`lastmod`)-UNIX_TIMESTAMP(20070101))/86400+`amsn_files`.`count`/15 AS `score` FROM `amsn_plugins` INNER JOIN `amsn_files` ON `amsn_files`.`id` = `amsn_plugins`.`file_id` ORDER BY `score` DESC")))) {
    echo "<p>There are no plugins available.</p>\n";
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
    <li class="lg"><?php echo $plugin['desc'] ?></li>
    <li class="dg">Created by: <?php echo $plugin['author'] ?></li>
    <li class="lg">Version: <?php echo $plugin['version'] ?></li>
    <li class="dg">Platform/OS: <?php echo $plugin['platform'] ?></li>
    <li class="lg">Requires: <?php echo $plugin['requires'] ?></li>
<?php 
		if (getFileURL($plugin['screen_id']) != '') {
?>
    <li class="dg"><a href="getURL.php?id=<?php echo $plugin['screen_id']?>" title="&lt;img src='thumb.php?id=<?php echo $plugin['screen_id'] ?>' /&gt;"><strong>Screenshot</strong></a></li>
<?php 
		}
		else {
?>
    <li class="dg"><strong>No screenshot</strong></li>
<?php
		}

		if (getFileURL($plugin['file_id']) != '') {
?>
    <li class="lg"><a href="getURL.php?id=<?php echo $plugin['file_id']?>"><strong>Download this plugin</strong></a></li>
<?php
		}
		else {
?>
    <li class="lg"><strong>Download comming soon!</strong></li>
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

</div>
<?php include inc . 'footer.php'; ?>
