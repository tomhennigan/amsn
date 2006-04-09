<?php
if(!defined('_PAGER_CLASS_')) {
  define('_PAGER_CLASS_',1);

  /* Version 1 */
  //Added CSSclass

  class Pager {
    var $from=0;
    var $to=100;
    var $incr=10;
    var $max=false;
    var $cssclass="pager";
    
    function Pager() {
      if(isset($_GET['from']))
	$this->from($_GET['from']);
      if(isset($_GET['to']))
	$this->to($_GET['to']);
      $this->incr=$this->to - $this->from;
    }

    function from($from="") {
      if($from!="") {
	$this->from=$from;
      }
      return $this->from;
    }

    function to($to="") {
      if($to!="") {
	$this->to=$to;
      }
      return $this->to;
    }

    function incr($incr="") {
      if($incr!="") {
	$this->to($this->from()+$incr);
        $this->incr=$incr;
      }
      return $this->incr;
    }
    
    function max($max="") {
      if($max!="") {
	$this->max=$max;
      }
      return $this->max;
    }

    function cssclass($cssclass="") {
      if($cssclass!="") {
        $this->cssclass=$cssclass;
      }
      return $this->cssclass;
    }

    function display() {
      $class=$this->cssclass();
      echo '<table class="'.$class.'_table" style="width:100%">';
      echo '<tr class="'.$class.'_row"><td class="'.$class.'_left">';
      $this->display_prev();
      echo '</td><td class="'.$class.'_center" style="text-align:center">';
      $this->display_current();
      echo '</td><td class="'.$class.'_right" style="text-align:right">';
      $this->display_next();
      echo '</td></tr>';
      echo '</table>';
    }

    function display_current() {
      $from=$this->from();
      $to=$this->to();
      $incr=$this->incr();
      $max=$this->max();
      $class=$this->cssclass();

      if ($max != false && $to > $max)
         $to = $max;

      echo '*Viewing reports '.$from.' to '.$to.' out of '.$max.'*';
    }

    function display_next() {
      $from=$this->from();
      $to=$this->to();
      $incr=$this->incr();
      $max=$this->max();
      $class=$this->cssclass();

      $url=new URL();
      
      $nfrom=$from+$incr;
      $nto=$to+$incr;
      $url->initCurURL();
      $url->setGet('to',$nto);
      $url->setGet('from',$nfrom);
      $next=$url->getURL();

      $pfrom=$from-$incr;
      $pto=$from;
      $url->initCurURL();
      $url->setGet('to',$pto);
      $url->setGet('from',$pfrom);
      $previous=$url->getURL();

      if($max===false || $nfrom<$max)
        echo '<a class="'.$class.'_next" href="'.$next.'">';

      echo 'Next';
      if($max===false || $nfrom<$max)
          echo ' ('.$nfrom.') -&gt;';
       else
          echo ' -&gt;';

      if($max===false || $nfrom<$max)
        echo '</a>';
    }

    function display_prev() {
      $from=$this->from();
      $to=$this->to();
      $incr=$this->incr();
      $max=$this->max();
      $class=$this->cssclass();
      
      $url=new URL();

      $nfrom=$from+$incr;
      $nto=$to+$incr;
      $url->initCurURL();
      $url->setGet('to',$nto);
      $url->setGet('from',$nfrom);
      $next=$url->getURL();

      $pfrom=$from-$incr;
      $pto=$from;
      $url->initCurURL();
      $url->setGet('to',$pto);
      $url->setGet('from',$pfrom);
      $previous=$url->getURL();
      
      if($pfrom>=0 && $pto>=0)
        echo '<a class="'.$class.'_prev" href="'.$previous.'">';

      echo '&lt;- Prev';
      if ($pfrom>=0 && $pto>=0) 
         echo ' ('.$pfrom.')';

      if($pfrom>=0 && $pto>=0)
        echo '</a>';
    }
  }
}
?>
