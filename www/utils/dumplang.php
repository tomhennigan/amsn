<?php
require_once '../common.php';
echo 'TRUNCATE TABLE `amsn_langs`;';
$query="SELECT * FROM amsn_langs";
$result=mysql_query($query) or die(mysql_error());

while($row=mysql_fetch_array($result)) {
  echo 'INSERT INTO amsn_langs (';
  $names='';
  $values='';
  foreach($row as $key=>$value) {
    if($key!==intval($key) && $key!='lang_id') {
      $names.=$key.",";
      $values.="'".$value."',";
    }
  }
  

  echo substr($names,0,strlen($names)-1).') VALUES ('.substr($values,0,strlen($values)-1).");\n";
}
?>
