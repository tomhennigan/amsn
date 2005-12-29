<?php
if(!defined("_URL_CLASS_")) {
  define("_URL_CLASS_",1);

  class URL {
    var $scheme='http';
    var $host='localhost';
    var $path='/';
    var $fragment='';
    var $get=array(); //array of gets
    function URL($url="") {
      $this->page($url);
    }

    function scheme($scheme="") {
      if($scheme!="" && is_string($scheme)) {
	$this->scheme=$scheme;
      }
      return $this->scheme;
    }

    function host($host="") {
      if($host!="" && is_string($host)) {
        $this->host=$host;
      }
      return $this->host;
    }

    function path($path="") {
      if($path!="" && is_string($path)) {
        $this->path=$path;
      }
      return $this->path;
    }

    function fragment($fragment="") {
      if($fragment!="" && is_string($fragment)) {
        $this->fragment=$fragment;
      }
      return $this->fragment;
    }

    function page($page="") {
      if($page!="" && is_string($page)) {
	$info=parse_url($page);
	if(isset($info['scheme'])) {
          $this->scheme($info['scheme']);
        }
	if(isset($info['host'])) {
          $this->host($info['host']);
        }
	if(isset($info['path'])) {
          $this->path($info['path']);
        }
	if(isset($info['fragment'])) {
          $this->fragment($info['fragment']);
        }
	if(isset($info['query'])) {
	  $this->get($info['query']);
	} 
      }
      return $this->page;
    }

    function get($get="") {
      if($get!="" && is_string($get)) {
	$tmp=array();
	$get=html_entity_decode($get);
	$get=explode("&",$get);
	foreach($get as $arg) {
	  $tmpa=explode("=",$arg);
	  if(isset($tmpa[1]))
	    $tmp[$tmpa[0]]=$tmpa[1];
	}
	$this->get=$tmp;
      }
      return $this->get;
    }

    function setGet($key,$value) {
      if($value=='')
	unset($this->get[$key]);
      else
	$this->get[$key]=trim($value);
    }

    function getGet($key) {
      $get=$this->get();
      if(isset($get[$key])) {
	return $get[$key];
      }
      return;
    }

    function getURL($html=true) {
      $scheme=$this->scheme();
      $host=$this->host();
      $path=$this->path();
      $fragment=$this->fragment();
      $get=$this->get();
      $url=$scheme.'://'.$host.$path;
      $x=0;
      foreach($get as $key => $value) {
	if($x==0) {
	  $url.="?";
	} else {
	  if($html) {
	    $url.="&amp;";
	  } else {
	    $url.='&';
	  }
	}
	$url.=$key."=".$value;
	$x++;
      }
      $url.='#'.$fragment;
      return $url;
    }

    function getCurURL() {
      $url="http://";
      $url.=$_SERVER["HTTP_HOST"];
      $url.=$_SERVER["REQUEST_URI"];
      return $url;
    }

    function initCurURL() {
      $this->URL($this->getCurURL());
    }

    function clean() {
      $this->get=array();
    }

    function redirect($link,$extra=array(),$clean=false) {
      $url=new URL();
      $url->initCurURL();
      if($clean)
	$url->clean();
      $url->page($link);
      foreach($extra as $key => $value) {
	$url->setGet($key,$value);
      }
      return $url->getUrl();
    }

    function redirect_nohtml($link,$extra=array()) {
      $url=new URL();
      $url->initCurURL();
      //$url->clean();
      $url->setGet($key,$link);
      foreach($extra as $key => $value) {
        $url->setGet($key,$value);
      }
      return $url->getUrl(false);
    }

    function js_redirect($link,$timeout) {
      $timeout*=1000;
      echo '<script type="text/javascript">';
      echo 'setTimeout("document.location=\''.$link.'\'",'.$timeout.')';
      echo '</script>';
    }
  } #end class
      } #end def
?>