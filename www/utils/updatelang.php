<?php
require_once('../common.php');
include("xmlparser.php");

if ($argc != 3) {
	die("Usage: ".$argv[0]." langcode xml_file\n\n");
}

$langcode=$argv[1];
$filename=$argv[2];

if (!file_exists($filename)) {
	die("File ".$argv[2]." does not exist\n");
}

echo "Updating language ".$langcode." with file ".$filename."\n";
 
$trans_xml = file_get_contents($filename);
$parser_trans = new XMLParser($trans_xml);
$parser_trans->Parse();
foreach($parser_trans->document->amsn_translations as $transxml)
{
        $transxml_id    = mysql_escape_string(stripslashes(trim($transxml->id[0]->tagData)));
        $transxml_type  = mysql_escape_string(stripslashes(trim($transxml->type[0]->tagData)));
        $transxml_trans = mysql_escape_string(stripslashes(trim($transxml->translation[0]->tagData)));
        
	$query="SELECT id FROM amsn_translations WHERE lang='$langcode' AND id='$transxml_id' AND trans_type='$transxml_type'";
	$result=mysql_query($query) or die(mysql_error());
	/* If no translation found, insert */
	if(mysql_num_rows($result) > 0) {
		$request = ("UPDATE amsn_translations SET translation='$transxml_trans' WHERE lang='$langcode' AND id='$transxml_id' AND trans_type='$transxml_type';");
		echo "Updating ".$transxml_type."(".$transxml_id.") : ".$transxml_trans."\n";
        } else {
		$request = ("INSERT INTO amsn_translations (id, trans_type, lang, translation) VALUES ('$transxml_id', '$transxml_type', '$langcode', '$transxml_trans');");
		echo "Inserting ".$transxml_type."(".$transxml_id.") : ".$transxml_trans."\n";
	}
        mysql_query($request);
}
 
?>
