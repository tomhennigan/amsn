<?php
  $id=$_GET['id'];
  echo '<h2 style="text-align:center">Viewing Bug Report #'.$id.'</h2>';
  $bug=new BugReport();
  $bug->loaddb($id);
  $bug->show();
?>