#!/usr/bin/php
<?php
include('../config.inc.php');
include('../bugs/common.inc.php');

$reports=array();
$max=0;

$query="SELECT * FROM ".TBUGS." WHERE bug_flag='0'";
$result=mysql_query($query) or die("MySQL Error: ".mysql_error());

while($row=mysql_fetch_array($result)) {
  $id=$row['bug_id'];
  $query="SELECT COUNT(*) as num FROM ".TBUGREPORTS." WHERE bug_parent='$id'";
  $result1=mysql_query($query) or die("MySQL Error: ".mysql_error());
  $row1=mysql_fetch_array($result1);
  $reports[$id]=$row1['num'];
  if($row1['num']>$max)
    $max=$row1['num'];
}

foreach($reports as $id => $count) {
  $priority=intval($count/$max*10);
  echo 'Bug #'.$id.' has priority '.$priority."\n";
  $query="UPDATE ".TBUGS." SET bug_priority='".$priority."' WHERE bug_id='".$id."'";
  mysql_query($query) or die("MySQL Error: ".mysql_error());
}

?>
