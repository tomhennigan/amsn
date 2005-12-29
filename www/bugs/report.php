<?php
include("../libs/lang.lib.php");
include("lang/en");
if(isset($_GET['lang']) && is_readable("lang/".$_GET['lang'])) {
  include("lang/".$_GET['lang']);
}

if(!isset($_FILES['file']) && !isset($_POST['report'])) {
  die(text("nomessage"));
}

include('../libs/xml.class.php');
include('../libs/bug.class.php');
include('../libsfunc.lib.php');
include('../config.inc.php');
include('common.inc.php');

if(blocked($_SERVER['REMOTE_ADDR'])!==false) 
     die(text('blocked'));

$bug=new Bug();

if(isset($_FILES['file'])) {
  $bug->load_report($_FILES['file']['tmp_name'],true);
} elseif(isset($_POST['report'])) {
  $bug->load_report(stripslashes($_POST['report']));
}

$r=$bug->check();
if(!$r) {
  die(text("invalid"));
}

$r=$bug->supported();
if(!$r) {
  die(text("notsupported"));
}

$r=$bug->spam($_SERVER['REMOTE_ADDR']);
if($r) {
  die(text("ipreported"));
}

$id=$bug->save2db();
     
echo text("thankyou",$id);
?>
