<?php
   define('source', 'plugins');
   include 'common.php';
   include inc . 'init.php';

   echo '<link rel="stylesheet" type="text/css" media="screen" href="plugins.css" />';

   include inc . 'header.php';
?>


        <strong>aMSN is full of features</strong>, but you can extend its functionality even more now, getting extra features by installing plugins. Plugins are simply that - they "plug in" to aMSN and give it extra features. Here you can download plugins developed by us and by contributors. Make sure you have the right version of aMSN for the plugin (check "requirements") and the right OS (check "platform")
        <br /><br />
        You can find instructions on how to install plugins in our <a href="http://amsn.sourceforge.net/devwiki/tiki-index.php?page=Installing+Plugins+and+Skins">skin and plugin installation guide</a>.
        <br /><br />
        If you would like to submit your plugin to this page, please read the <a href="http://amsn.sourceforge.net/devwiki/tiki-index.php?page=Skin+and+plugin+submitting+guide">plugin submitting guide</a>.
        <br /><br />

<a name="top">
	<br />
</a>
<?php

if (!mysql_num_rows(($q = mysql_query("SELECT *  FROM `amsn_plugins` ORDER BY `name`")))) {
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
		if ($plugin['screen']>0) {
?>
    <li class="dg"><a href="http://amsn.sourceforge.net/wiki/show_image.php?id=<?php echo $plugin['screen']?>"><strong>Screenshot</strong></a></li>
<?php 
		}
		else {
?>
    <li class="dg"><strong>No screenshot</strong></li>
<?php
		}

		if ($plugin['url']!='') {
?>
    <li class="lg"><a href="http://prdownloads.sourceforge.net/amsn/<?php echo $plugin['url']?>"><strong>Download this plugin</strong></a></li>
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


<?php include inc . 'footer.php'; ?>
