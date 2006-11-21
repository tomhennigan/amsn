<?php
function email($to,$subject,$body) {
  mail($to, $subject, $body);
}
?>
