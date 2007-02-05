<?php
function email($to,$subject,$body) {
  mail($to, $subject, $body,"From: aMSN Team <noreply@amsn-project.net>\n");
}
?>
