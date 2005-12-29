<?php
$con=@mysql_connect(DBHOST,DBUSER,DBPASS) or die('Error connecting to MySQL Database! '.mysql_error());
$db=mysql_select_db(DBNAME_BUGS,$con) or die('Error selecting MySQL Database! '.mysql_error());

define('BUG_VERSION','0.3');

$FLAGS['NONE']=0;
$FLAGS_DESC['NONE']="This bug is new and has not been marked as anything yet.";
$query="SELECT * FROM ".TFLAGS;
$r=mysql_query($query) or die("Error loading the flags! ".mysql_error());
while($row=mysql_fetch_array($r)) {
  $FLAGS[strtoupper($row['flag_flag'])]=$row['flag_id'];
  $FLAGS_DESC[strtoupper($row['flag_flag'])]=$row['flag_desc'];
}
?>
