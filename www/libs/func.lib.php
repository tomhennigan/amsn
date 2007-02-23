<?php
if(!defined('_FUNC_LIB_')) {
  define("_FUNC_LIB_",0);

  function translucate($text,$len=10) {
    if(strlen($text)>$len) {
      //len-3 in order to count in the added ...
      $text=substr($text,0,$len-3).'...';
    }
    return $text;
  }

  function private_ip($ip) {
    if($ip=="")
      $ip="0.0.0.0";
    $arr=explode('.',$ip);
    $arr[3]='xxx';
    return implode('.',$arr);
  }

  function blocked($ip) {
    $query="SELECT * FROM ".TBLOCK." WHERE block_ip='".$ip."' AND block_until>UNIX_TIMESTAMP()";
    $r=query($query);
    while($row=mysql_fetch_array($r)) {
      return $row['block_id'];
    }
    $query="DELETE FROM ".TBLOCK." WHERE block_ip='".$ip."'";
    query($query);
    return false;
  }
  
  function bug_exists($bug) {
    $query="SELECT * FROM ".TBUGREPORTS." WHERE bug_id='$bug'";
    $r=query($query);
    if(mysql_num_rows($r)>0) {
      return true;
    } else {
      return false;
    }
  }

  function query($query) {
    $res=mysql_query($query) or die("MySQL Error: ".mysql_error());
    return $res;
  }

  function hideemail($email) {
    $email=str_replace('@',' [ at ] ',$email);
    $email=str_replace('.',' [ dot ] ',$email);
    return $email;
  }

  function humantitle($txt) {
    $txt=str_replace('_',' ',$txt);
    $txt=ucwords($txt);
    return $txt;
  }

  /* REMOTE OS IDENTIFICATION */
  function remoteOS() {
    $agent = $_SERVER['HTTP_USER_AGENT'];
    if (eregi("win", $agent))
      return "Windows";
    elseif (eregi("mac", $agent))
      return "Mac";
    elseif (eregi("linux", $agent))
      return "Linux";
    elseif (eregi("OS/2", $agent))
      return "OS/2";
    elseif (eregi("BeOS", $agent))
      return "BeOS";
    elseif (eregi("FreeBSD", $agent))
      return "FreeBSD";
  }

  function ereg_mline($reg,$string) {
    $regs=explode("\n",$reg);
    $lines=explode("\n",$string);

    # We reset the time limit here so that the 'search' function of bugs will not exceed the 10s limit
    set_time_limit(30);

    foreach($regs as $num => $reg) {
      $reg=trim($reg);
      $lines[$num]=trim($lines[$num]);
      if($reg === '') {
        if($lines[$num] !== '')
          return false;
      }
      else {
        if(!ereg($reg,$lines[$num])) {
          return false;
        }
      }
    }
    return true;
  }

  function ereg_prepare($text) {
    $text=str_replace('{','\{',$text);
    $text=str_replace('}','\}',$text);
    $text=str_replace('[','\[',$text);
    $text=str_replace(']','\]',$text);
    $text=str_replace('(','\(',$text);
    $text=str_replace(')','\)',$text);
    $text=str_replace('$','\$',$text);
    $text=str_replace('.','\.',$text);
    return $text;
  }
}
?>
