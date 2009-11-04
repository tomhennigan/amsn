<?php
require_once('../common.php');
include("xmlparser.php");

if ($argc != 2) {
	die("Usage: ".$argv[0]." langcode\n\n");
}

$langcode=$argv[1];

echo "Dropping language ".$langcode." from the database\n";
 
$query="DELETE FROM amsn_translations WHERE lang='$langcode'";
$result=mysql_query($query) or die(mysql_error());
 
?>
