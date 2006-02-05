<?php
if(!defined("_LANG_LIB_")) {
  define("_LANG_LIB_",0);

  function text($key) {
    global $trans;
    if(isset($trans[$key])) {
      $str=$trans[$key];
      for($x=1;$x<func_num_args();$x++) {
	$arg=func_get_arg($x);
	$str=str_replace("\$$x",$arg,$str);
      }
    } else {
      $str=$key;
    }
    return $str;
  }

  function trans($key) {
    $code=getLangKey();
    $skey=mysql_escape_string(stripslashes(trim($key)));
    
    $query="SELECT lang_text FROM amsn_langs WHERE lang_code='$code' AND lang_key='$skey'";
    $result=mysql_query($query) or die(mysql_error());

    /* If no translation found, look up english */
    if(mysql_num_rows($result)==0) {
      $query="SELECT lang_text FROM amsn_langs WHERE lang_code='en' AND lang_key='$skey'";
      $result=mysql_query($query) or die(mysql_error());
    }

    /* If no translation found in english, return key */
    if(mysql_num_rows($result)==0) {
      $text=$key;
    } else {
      $row=mysql_fetch_array($result);
      $text=$row['lang_text'];
    }

    /* Get rid of $x$ by replacing with arguments */
    for($x=1;$x<func_num_args();$x++) {
      $arg=func_get_arg($x);
      $text=str_replace("\$$x\$",$arg,$text);
    }
    return $text;
  }

  function getLangKey() {
    if(isset($_COOKIE['lang'])) {
      return $_COOKIE['lang'];
      } elseif(isset($_SESSION['lang'])) {
      return $_SESSION['lang'];
    } else {
      return 'en';
    }
  }

  function setLangKey($code) {
    $_COOKIE['lang']=$code;
    $_SESSION['lang']=$code;
  }
}
?>
