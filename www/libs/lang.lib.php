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
}
?>
