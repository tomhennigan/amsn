<?php
  $id=$_GET['id'];
  echo '<h2 style="text-align:center">Viewing Bug #'.$id.'</h2>';
  $bug=new Bug();
  $bug->loaddb($id);
  $bug->show();
?>
