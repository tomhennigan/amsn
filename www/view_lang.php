<?php
	define('source', 'index');
	include 'common.php';
	include inc . 'init.php';
	echo '<link rel="stylesheet" type="text/css" media="screen" href="view_lang.css" />';
	include inc . 'header.php';

	$langfile = basename($_GET['lang']);
	$fp = @fopen($lang_dir . DIRECTORY_SEPARATOR . $langfile,"r");
	if (!$fp) die("Can't open $langfile");
	$line = fgets($fp);
	$line=trim($line);
	list($encoding,$missingkeys,$langcode,$langname)=split(' ',$line,4);
?>
<table border="0" width="100%">
<tr>
<td width="33%" align="left" valign="bottom">lang<?php echo $langcode; ?></td>
<td width="33%" align="center" valign="bottom"><i>Encoding</i> : <b><?php echo $encoding; ?></b></td>
<td align="right" valign="bottom"><i>Missing keys</i> : <b><?php echo $missingkeys; ?></b></td>
</tr>
</table>
<br/>
Instructions :<br/>
1. : Read the <a href="http://cvs.sourceforge.net/cgi-bin/viewcvs.cgi/*checkout*/amsn/msn/lang/LANG-HOWTO?rev=HEAD&amp;content-type=text/plain"><b>LANG-HOWTO</b></a> file with instructions for translators<br/>
2. : Download the old language file here : <a href="http://cvs.sourceforge.net/cgi-bin/viewcvs.cgi/*checkout*/amsn/msn/lang/lang<?php echo $langcode?>?rev=HEAD&amp;content-type=text/plain"><b>lang<?php echo $langcode?></b></a><br/>
3. : Copy the keywords from the list below and add them to the language file.<br/>
4. : Translate the english explanations<br/>
5. : Send the updated file to <a href="mailto:amsn-translations@lists.sourceforge.net">amsn-translations@lists.sourceforge.net</a><br/>
<br/>
<?php
	if ($missingkeys == 0) { ?>
<i>No missing keys to translate</i>
<?php
	} else { ?>
<table class="missingkeys">
<tr><th>Key</th><th>Description</th></tr>
<?php
		while(!feof($fp) && $line != "") {
			$line=fgets($fp);
			$line=trim($line);
			list($key,$description)=split(' ',$line,2);
			echo '<tr><td><b>' . htmlentities($key) . '</b></td><td>' . htmlentities($description) . '</td></tr>'."\n";
		} ?>
</table>
<?php
	}
	fclose($fp);
?>

<?php include inc . 'footer.php'; ?>
