<?php
$con=@mysql_connect(DBHOST,DBUSER,DBPASS) or die('Error connecting to MySQL Database! '.mysql_error());
$db=mysql_select_db(DBNAME_BUGS,$con) or die('Error selecting MySQL Database! '.mysql_error());

define('BUG_VERSION','0.3');

$FLAGS[0]='NONE';
$FLAGS[1]='FIXED';
$FLAGS[2]='REOPENED';
$FLAGS[3]='INVALID';
$FLAGS_DESC[0]="This bug is new and has not been marked as anything yet.";
$FLAGS_DESC[1]="This bug has been fixed.";
$FLAGS_DESC[2]="This bug has been found in new version again.";
$FLAGS_DESC[3]="This bug has nothing to do with aMSN.";
?>
