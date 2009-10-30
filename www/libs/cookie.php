<?php
  $timeplus=time()+60*60*24*365;
  $timeminus=time()-60*60*24*365;

  if(isset($lang_set)) {
    if(isset($_GET['lang'])) {
      $lang_set=$_GET['lang'];
    }
    setcookie("lang",$lang_set,$timeminus);
    setcookie("lang",$lang_set,$timeplus);
  } else {
    if(isset($_COOKIE['lang'])) {
      $lang_set=$_COOKIE['lang'];
      if(isset($_GET['lang'])) {
        $lang_set=$_GET['lang'];  
      }
      setcookie("lang",$lang_set,$timeminus);
      setcookie("lang",$lang_set,$timeplus);
    } else {
      $lang_set = substr($_SERVER['HTTP_ACCEPT_LANGUAGE'],0,2);
      setcookie("lang",$lang_set,$timeminus);
      setcookie("lang",$lang_set,$timeplus);
    }
  }
?>
