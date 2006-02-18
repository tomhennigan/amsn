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
    return uft2html($text);
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

  #all the functions for parsing the lang files that are part of the program

  #Taken from php.net
  function utf2html ($utf2html_string) {
    $f = 0xffff;
    $convmap = array(
		     /* <!ENTITY % HTMLlat1 PUBLIC "-//W3C//ENTITIES Latin 1//EN//HTML">
   %HTMLlat1; */
		     160,  255, 0, $f,
		     /* <!ENTITY % HTMLsymbol PUBLIC "-//W3C//ENTITIES Symbols//EN//HTML">
   %HTMLsymbol; */
		     402,  402, 0, $f,  913,  929, 0, $f,  931,  937, 0, $f,
		     945,  969, 0, $f,  977,  978, 0, $f,  982,  982, 0, $f,
		     8226, 8226, 0, $f, 8230, 8230, 0, $f, 8242, 8243, 0, $f,
		     8254, 8254, 0, $f, 8260, 8260, 0, $f, 8465, 8465, 0, $f,
		     8472, 8472, 0, $f, 8476, 8476, 0, $f, 8482, 8482, 0, $f,
		     8501, 8501, 0, $f, 8592, 8596, 0, $f, 8629, 8629, 0, $f,
		     8656, 8660, 0, $f, 8704, 8704, 0, $f, 8706, 8707, 0, $f,
		     8709, 8709, 0, $f, 8711, 8713, 0, $f, 8715, 8715, 0, $f,
		     8719, 8719, 0, $f, 8721, 8722, 0, $f, 8727, 8727, 0, $f,
		     8730, 8730, 0, $f, 8733, 8734, 0, $f, 8736, 8736, 0, $f,
		     8743, 8747, 0, $f, 8756, 8756, 0, $f, 8764, 8764, 0, $f,
		     8773, 8773, 0, $f, 8776, 8776, 0, $f, 8800, 8801, 0, $f,
		     8804, 8805, 0, $f, 8834, 8836, 0, $f, 8838, 8839, 0, $f,
		     8853, 8853, 0, $f, 8855, 8855, 0, $f, 8869, 8869, 0, $f,
		     8901, 8901, 0, $f, 8968, 8971, 0, $f, 9001, 9002, 0, $f,
		     9674, 9674, 0, $f, 9824, 9824, 0, $f, 9827, 9827, 0, $f,
		     9829, 9830, 0, $f,
		     /* <!ENTITY % HTMLspecial PUBLIC "-//W3C//ENTITIES Special//EN//HTML">
   %HTMLspecial; */
		     /* These ones are excluded to enable HTML: 34, 38, 60, 62 */
		     338,  339, 0, $f,  352,  353, 0, $f,  376,  376, 0, $f,
		     710,  710, 0, $f,  732,  732, 0, $f, 8194, 8195, 0, $f,
		     8201, 8201, 0, $f, 8204, 8207, 0, $f, 8211, 8212, 0, $f,
		     8216, 8218, 0, $f, 8218, 8218, 0, $f, 8220, 8222, 0, $f,
		     8224, 8225, 0, $f, 8240, 8240, 0, $f, 8249, 8250, 0, $f,
		     8364, 8364, 0, $f);
    
    return mb_encode_numericentity($utf2html_string, $convmap, "UTF-8");
  }
}
?>
