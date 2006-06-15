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

<a NAME="top">
	<br />
</a>

<?php

if (!mysql_num_rows(($q = mysql_query("SELECT *  FROM `amsn_skins` ORDER BY `name`")))) {
    echo "<p>There are no screenshots available.</p>\n";
} else {
	$elements_per_line=5;
	$i = 0;
	echo '<div style="text-align:center">';
	while ($skin = mysql_fetch_assoc($q)) {
		if ($i > 0 )
			echo ' | ';
		echo '<a href="#'. $skin['name']. '"> ' . $skin['name'] . ' </a>';
		$i = $i + 1;
        	if ($i == $elements_per_line) {
			echo '<br />';
			$i = 0;
        	}
	}
	echo '</div> <br/> <br/>';
	mysql_data_seek($q, 0);
	while ($skin = mysql_fetch_assoc($q)) {
?>
<a NAME="<?php echo $skin['name']?>">
<table class="skins">
  <tbody><tr>
    <td>
      <ul>
        <li class="skintitle"><?php echo $skin['name'] ?></li>
        <li class="lg"><?php echo $skin['desc'] ?></li>
        <li class="dg">Created by: <?php echo $skin['author'] ?></li>
<?php 
		if ($skin['screen']>0) {
?>
        <li class="lg"><a href="http://amsn.sourceforge.net/wiki/show_image.php?id=<?php echo $skin['screen']?>"><strong>Screenshot</strong></a></li>
<?php 
		}
		else {
?>
        <li class="lg"><strong>No screenshot</strong></li>
<?php
		}

		if ($skin['url']!='') {
?>
        <li class="dg"><a href="http://prdownloads.sourceforge.net/amsn/<?php echo $skin['url']?>"><strong>Download this skin</strong></a></li>
<?php
		}
		else {
?>
        <li class="dg"><strong>Download comming soon!</strong></li>
<?php
		}
?>
      </ul>
    </td>
  </tr></tbody>
</table>
<br/>
<a/>
<?php
	}
}
?>

<br/><br/>
<center><strong><a href="#top">Back to top</a></strong></center>


<?php include inc . 'footer.php';?>
