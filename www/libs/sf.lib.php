<?php
function email($to,$subject,$body) {
  $r = mysql_query("SELECT DATABASE()") or die('MySQL Error: '.mysql_error());
  $last=mysql_result($r,0);
  $db=mysql_select_db(DBNAME_WWW);
  $query="INSERT INTO _email (email_to,email_subject,email_body) VALUES ('$to','$subject','$body')";
  mysql_query($query) or die('MySQL Error: '.mysql_error());
  mysql_select_db($last);
}
?>