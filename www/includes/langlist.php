<?php
$langlist = $lang_dir . '/langlist.dat';
$fp = @fopen($langlist, "r");
if (!$fp) {
	echo "Error: Unable to open langlist file";
	return;
}
$line = fgets($fp);
echo '<table class="langlist">';
echo '<tr><th>Language</th><th>Missing keys</th></tr>';
while (!feof($fp) && $line != "\n") {
	$line = rtrim($line);
	list($file,$encoding,$missing,$langname) = split(' ',$line,4);
	echo '<tr><td><a href="view_lang.php?lang='.basename($file).'">'. utf2html($langname) .'</a></td><td>'.$missing.'</td></tr>'."\n";
	$line=fgets($fp);
}
fclose($fp);
?>
</table>
<?php

/*
switch($func) {
    default:
	AddonSample($page);
    break;

}*/

?>
