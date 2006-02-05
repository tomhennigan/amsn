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
include('../libs/bugreport.class.php');
include('../libs/bug.class.php');
include('../libs/func.lib.php');
include('../config.inc.php');
include('common.inc.php');

if(blocked($_SERVER['REMOTE_ADDR'])!==false) 
     die(text('blocked'));

$bugreport=new BugReport();

if(isset($_FILES['file'])) {
  $bugreport->load_report($_FILES['file']['tmp_name'],true);
} elseif(isset($_POST['report'])) {
  $bugreport->load_report(stripslashes($_POST['report']));
}

$r=$bugreport->check();
if(!$r) {
  die(text("invalid"));
}

$r=$bugreport->supported();
if(!$r) {
  die(text("notsupported"));
}

$r=$bugreport->spam($_SERVER['REMOTE_ADDR']);
if($r) {
  die(text("ipreported"));
}

$ret=$bugreport->searchForParents();
if($ret>0) {
  $bug=new Bug();
  $bug->loaddb($ret);
  if(!$bug->checkReport($bugreport)) {
    echo text("fixed");
    die();
  }
}

$id=$bugreport->save2db();
     
echo text("thankyou",$id);
?>
