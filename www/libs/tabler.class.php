<?php
if(!defined("_TABLER_CLASS_")) {
  define("_TABLER_CLASS_",0);

  class Tabler {
    var $cols=array();
    var $pager;
    var $table;
    var $link;
    var $idcol;
    
    function Tabler($table,$cols=array(),$filters=array(),$order="") {
      $this->table($table);
      $this->pager=new Pager();
      if(count($cols)==0) {
	$what='*';
      } else {
	foreach($cols as $title=>$name) {
	  if($name!="") {
	    $this->addCol($name);
	    $this->col_option($name,'title',$title);
	  }
	  $what.=$name.',';
	}
	$what=substr($what,0,strlen($what)-1);
      }

      if(count($filters)>0) {
	foreach($filters as $add) {
	  $filter=(isset($filter))?"$filter AND $add":" WHERE $add";
	}
      }

      foreach($_GET as $key => $value) {
	if(ereg('^filter_',$key)) {
	  $name=substr($key,7);
	  if($value!='') {
	    if($_GET['f_'.$name.'_type']=='search') {
	      $filter=(isset($filter))?"$filter AND $name LIKE '%$value%'":" WHERE $name LIKE '%$value%'";
	    } else {
	      $filter=(isset($filter))?"$filter AND $name='$value'":" WHERE $name='$value'";
	    }
	  }
	}
      }
      
      $query="SELECT count(*) as max FROM $table $filter";
      $result=mysql_query($query) or die("MySQL Error: ".mysql_error());
      $row=mysql_fetch_array($result);
      $this->pager->max($row['max']);

      $query="SELECT $what FROM $table $filter";
      $keys=array_keys($this->cols);
      $order=(isset($_GET['orderby']))?$_GET['orderby']:(($order=="")?$keys['0'].' DESC':$order);
      $query.=" ORDER BY $order";
      $query.=" LIMIT ".$this->pager->from().",".$this->pager->incr();
      $result=mysql_query($query) or die("MySQL Error: ".mysql_error());
      
      while($row=mysql_fetch_array($result,MYSQL_ASSOC)) {
	$this->add($row);
      }

      $fields=mysql_num_fields($result);
      for($x=0;$x<$fields;$x++) {
	$colinfo=@mysql_field_flags($result,$x);
	$colinfo=explode(' ',$colinfo);
	$name=mysql_field_name($result,$x);
	$type=mysql_field_type($result,$x);
	if(array_search('auto_increment',$colinfo)!==false) {
	  $this->col_option($name,'filter','submit');
	  $this->idcol=$name;
	} else {
	  $this->col_option($name,'filter','select');
	}
      }

    }

    function cols($cols="") {
      if($cols!="" && is_array($cols)) {
	$this->cols=$cols;
      }
      return $this->cols;
    }
    
    function rows($rows="") {
      if($rows!="" && is_array($rows)) {
        $this->rows=$rows;
      }
      return $this->rows;
    }

    function table($table="") {
      if($table!="" && is_string($table)) {
        $this->table=$table;
      }
      return $this->table;
    }

    function link($link="") {
      if($link!="" && is_string($link)) {
        $this->link=$link;
      }
      return $this->link;
    }
    
    function idcol($idcol="") {
      if($idcol!="" && is_string($idcol)) {
        $this->idcol=$idcol;
      }
      return $this->idcol;
    }

    function col_option($col,$key,$value) {
      $this->cols[$col][$key]=$value;
    }

    function addCol($name) {
      $this->cols[$name]=array();
    }
    
    function add($row) {
      $rows=$this->rows();
      $rows[]=$row;
      $this->rows($rows);
    }
    
    function rename($col,$value) {
      $cols=$this->cols();
      if(!isset($cols[$col]['rename'])) {
	return $value;
      } else if(is_string($cols[$col]['rename'])) {
	$func='return '.str_replace('$arg',$value,$cols[$col]['rename']).';';
	return eval($func);
      } else {
	return $cols[$col]['rename'][$value];
      }
    }

    function show() {
      $cols=$this->cols();
      $rows=$this->rows();
      $table=$this->table();
      $link=$this->link();

      echo '<form action="#" method="get">';
      echo '<span>';
      foreach($_GET as $key => $value) {
	echo '<input type="hidden" name="'.$key.'" value="'.$value.'"/>';
      }
      echo '</span>';
      echo '<table cellspacing="0" cellpadding="0" class="db">';
      $order=(isset($_GET['orderby']))?$_GET['orderby']:'bug_id DESC';
      echo '<tr class="header">';
      foreach($cols as $name => $column) {
	if($column['title']=="") 
	  $title=humantitle($name);
	else 
	  $title=$column['title'];
	echo '<th>';
	$by=($order==$name)?$name.' DESC':$name;
	echo '<a href="'.URL::redirect('#',array('orderby'=>$by)).'" class="header">';
	echo '<div class="full">'.$title.'</div>';
	echo '</a>';
	echo '</th>';
      }
      echo '</tr>';

      echo '<tr class="filter">';
      foreach($cols as $name => $cfg) {
	echo '<td>';
	switch($cfg['filter']) {
	case 'search':
	  echo '<input type="text" name="filter_'.$name.'" class="full" />';
	  echo '<span><input type="hidden" name="f_'.$name.'_type" value="search" /></span>';
	  break;
	case 'submit':
	  echo '<input class="full" type="submit" value="Filter" />';
	  break;
	default:
	case 'select':
	  echo '<select name="filter_'.$name.'" class="full">';
	  echo '<option value="">No Filter</option>';
	  $query="SELECT DISTINCT $name FROM $table ORDER BY $name";
	  $result=mysql_query($query) or die('MySQL Error: '.mysql_error());
	  while($row=mysql_fetch_array($result)) {
	    echo '<option value="'.$row[$name].'"'.(($_GET['filter_'.$name]==$row[$name])?' selected="selected"':'').'>'.$this->rename($name,$row[$name]).'</option>';
	  }
	  echo '</select>';
	  break;
	}
	echo '</td>';
      }
      echo '</tr>';

      for($i=0;$i<count($rows);$i++) {
	echo '<tr class="row r_'.($x++%2).'">';
	foreach($rows[$i] as $name => $value) {
	  
	  $value=$this->rename($name,$value);
	  if($_GET['f_'.$name.'_type']=='search') {
	    $value=str_replace($_GET['filter_'.$name],'<span class="found">'.$_GET['filter_'.$name].'</span>',$value);
	  }
	  echo '<td class="row"';
	  if($cols[$name]['css']!="") {
	    echo ' style="'.$cols[$name]['css'].'"';
	  }
	  echo '><a class="normal" href="?show='.$link.'&amp;id='.$rows[$i][$this->idcol].'"><div class="full">'.$value.'</div></a></td>';
	}
	echo '</tr>';
      }

      echo '<tr class="footer"><td colspan="'.count($cols).'">';
      $this->pager->display();
      echo '</td></tr>';
      echo '</table>';
      echo '</form>';
    }
  }
}
?>