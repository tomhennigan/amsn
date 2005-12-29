<?php
include('../../config.inc.php');
include('../common.inc.php');
include('../../libs/url.class.php');
include('../../libs/bug.class.php');
include('../../libs/func.lib.php');
include('../../libs/pager.class.php');

//Default flag is NONE
$_GET['flag_filter']=(!isset($_GET['flag_filter']))?$FLAGS['NONE']:$_GET['flag_filter'];
$pager=new Pager();
$pager->incr(50);

$query="";
?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
        "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html>
<head>
<title>aMSN Bug Database</title>
<link rel="stylesheet" href="../main.css" type="text/css" />
</head>
<body>
<?php
if(isset($_GET['bug']) && $_GET['bug']!='') {
  $id=$_GET['bug'];
  echo '<h2 style="text-align:center">Viewing Bug #'.$id.'</h2>';
  echo '<div align="center"><a href="index.php">Index</a> </div>';
  $bug=new Bug();
  $bug->loaddb($id);
  $bug->show();
  echo '<br/><br/><div style="width: 100%;text-align:center"><code>Created and owned by the <a href="http://amsn.sf.net">aMSN Project</a></code></div>';
} else {
  $order=(isset($_GET['orderby']))?$_GET['orderby']:'bug_id DESC';
  $q=(isset($_GET['query']))?$_GET['query']:'';
  $search=($q!='')?'WHERE bug_text LIKE \'%'.$q.'%\'':'';
?>
    <form action="#" method="get">
       <table class="db" cellspacing="0" cellpadding="0">
       <tr><td class="title" colspan="3">
       <a href="index.php" class="normal">aMSN Bug Report Database</a>
       </td><td class="search" colspan="4">
       <div class="inline">Bug #</div><input type="text" name="bug"/>
       <td><input type="submit" class="button submit go_button" name="submit" value="Go"/></td>
       </td></tr>
<?php
       
 echo '<tr><td class="header" style="width:10px">';
 $by=($order=='bug_id')?'bug_id DESC':'bug_id';
 echo '<a href="'.URL::redirect('#',array('orderby'=>$by)).'" class="header"><div class="full">';
 echo '#';
 echo '</div></a>';
 echo '</td><td class="header">';
 $by=($order=='bug_text')?'bug_text DESC':'bug_text';
 echo '<a href="'.URL::redirect('#',array('orderby'=>$by)).'" class="header"><div class="full">';
 echo 'Error';
 echo '</div></a>';
 echo '</td><td class="header" style="width: 225px">';
 $by=($order=='bug_date')?'bug_date DESC':'bug_date';
 echo '<a href="'.URL::redirect('#',array('orderby'=>$by)).'" class="header"><div class="full">';
 echo 'Submitted';
 echo '</div></a>';
 echo '</td><td class="header" style="width: 225px">';
 $by=($order=='bug_cvsdate')?'bug_cvsdate DESC':'bug_cvsdate';
 echo '<a href="'.URL::redirect('#',array('orderby'=>$by)).'" class="header"><div class="full">';
 echo 'CVS Date';
 echo '</div></a>';
 echo '</td><td class="header" style="width: 95px">';
 $by=($order=='bug_amsn')?'bug_amsn DESC':'bug_amsn';
 echo '<a href="'.URL::redirect('#',array('orderby'=>$by)).'" class="header"><div class="full">';
 echo 'Version';
 echo '</div></a>';
 echo '</td><td class="header" style="width: 95px">';
 $by=($order=='bug_tcl')?'bug_tcl DESC':'bug_tcl';
 echo '<a href="'.URL::redirect('#',array('orderby'=>$by)).'" class="header"><div class="full">';
 echo 'Tcl Version';
 echo '</div></a>';
# echo '</td><td class="header" style="width: 95px">';
# $by=($order=='bug_tk')?'bug_tk DESC':'bug_tk';
# echo '<a href="'.URL::redirect('#',array('orderby'=>$by)).'" class="header"><div class="full">';
# echo 'Tk Version';
# echo '</div></a>';
 echo '</td><td class="header" style="width: 95px">';
 $by=($order=='bug_os')?'bug_os DESC':'bug_os';
 echo '<a href="'.URL::redirect('#',array('orderby'=>$by)).'" class="header"><div class="full">';
 echo 'OS';
 echo '</div></a>';
 echo '</td><td class="header" style="width: 95px">';
 $by=($order=='bug_flag')?'bug_flag DESC':'bug_flag';
 echo '<a href="'.URL::redirect('#',array('orderby'=>$by)).'" class="header"><div class="full">';
 echo 'Flag';
 echo '</div></a>';
 echo '</td></tr>';

 #generate the filter thing
 echo '<tr class="filter"><td>';
 echo '<input type="submit" value="Filter" />';
 echo '</td><td>';
 echo '<input type="text" name="query" class="text full" value="'.$q.'" />';
 echo '</td><td>';
 echo '<select class="filter" name="date_filter">';
 echo '<option value="">No Filter</option>';
 $query="SELECT DISTINCT DATE_FORMAT(FROM_UNIXTIME(bug_date),\"%M %e, %Y\") AS date FROM bugreports ORDER BY date;";
 $result=query($query);
 while($row=mysql_fetch_array($result)) {
   $value=$row['date'];
   echo '<option value="'.$value.'"';
   echo ($_GET['date_filter']==$value)?'selected="selected"':'';
   echo '>'.$value.'</option>';
 }
 echo '</select>';
 echo '</td><td>';
 echo '<select class="filter" name="cvs_filter">';
 echo '<option value="">No Filter</option>';
 $query="SELECT DISTINCT bug_cvsdate FROM bugreports ORDER BY bug_cvsdate DESC;";
 $result=query($query);
 while($row=mysql_fetch_array($result)) {
   $value=$row['bug_cvsdate'];
   echo '<option value="'.$value.'"';
   echo ($_GET['cvs_filter']==$value)?'selected="selected"':'';
   echo '>'.strftime('%c',$value).'</option>';
 }
 echo '</select>';
 echo '</td><td>';
 echo '<select class="filter" name="amsn_filter">';
 echo '<option value="">No Filter</option>';
 $query="SELECT DISTINCT bug_amsn FROM bugreports ORDER BY bug_amsn;";
 $result=query($query);
 while($row=mysql_fetch_array($result)) {
   $value=$row['bug_amsn'];
   echo '<option value="'.$value.'"';
   echo ($_GET['amsn_filter']==$value)?'selected="selected"':'';
   echo '>'.$value.'</option>';
 }
 echo '</select>';
 echo '</td><td>';
 echo '<select class="filter" name="tcl_filter">';
 echo '<option value="">No Filter</option>';
 $query="SELECT DISTINCT bug_tcl FROM bugreports ORDER BY bug_tcl;";
 $result=query($query);
 while($row=mysql_fetch_array($result)) {
   $value=$row['bug_tcl'];
   echo '<option value="'.$value.'"';
   echo ($_GET['tcl_filter']==$value)?'selected="selected"':'';
   echo '>'.$value.'</option>';
 }
 echo '</select>';
 echo '</td><td>';
# echo '<select class="filter" name="tk_filter">';
# echo '<option value="">No Filter</option>';
# $query="SELECT DISTINCT bug_tk FROM bugreports ORDER BY bug_tk;";
# $result=query($query);
# while($row=mysql_fetch_array($result)) {
#   $value=$row['bug_tk'];
#   echo '<option value="'.$value.'"';
#   echo ($_GET['tk_filter']==$value)?'selected="selected"':'';
#   echo '>'.$value.'</option>';
# }
# echo '</select>';
# echo '</td><td>';
 echo '<select class="filter" name="os_filter">';
 echo '<option value="">No Filter</option>';
 $query="SELECT DISTINCT bug_os FROM bugreports ORDER BY bug_os;";
 $result=query($query);
 while($row=mysql_fetch_array($result)) {
   $value=$row['bug_os'];
   echo '<option value="'.$value.'"';
   echo ($_GET['os_filter']==$value)?'selected="selected"':'';
   echo '>'.$value.'</option>';
 }
 echo '</select>';
 echo '</td><td>';
 echo '<select class="filter" name="flag_filter">';
 echo '<option value="-1">No Filter</option>';
 // $query="SELECT DISTINCT bug_flag FROM bugreports ORDER BY bug_flag;";
 // $result=query($query);
 // while($row=mysql_fetch_array($result)) {
 //flags are preset in the FLAG array
 foreach($FLAGS as $key => $value) {
   echo '<option value="'.$value.'"';
   echo ($_GET['flag_filter']==$value)?'selected="selected"':'';
   echo '>'.$key.'</option>';
 }
 echo '</select>';
 echo '</td></tr>';
 
 $filter=($_GET['date_filter']=='')?' bug_date LIKE \'%\'':' DATE_FORMAT(FROM_UNIXTIME(bug_date),"%M %e, %Y")=\''.$_GET['date_filter'].'\'';
 $filter.=' AND ';
 $filter.=($_GET['cvs_filter']=='')?'bug_cvsdate LIKE \'%\'':" bug_cvsdate='".$_GET['cvs_filter']."'";
 $filter.=' AND ';
 $filter.=($_GET['tcl_filter']=='')?'bug_tcl LIKE \'%\'':" bug_tcl='".$_GET['tcl_filter']."'";
 $filter.=' AND ';
 $filter.=($_GET['amsn_filter']=='')?'bug_amsn LIKE \'%\'':" bug_amsn='".$_GET['amsn_filter']."'";
 $filter.=' AND ';
 $filter.=($_GET['os_filter']=='')?'bug_os LIKE \'%\'':" bug_os='".$_GET['os_filter']."'";
 $filter.=' AND ';
 $filter.=($_GET['flag_filter']<0)?'bug_flag LIKE \'%\'':" bug_flag='".$_GET['flag_filter']."'";
 $filter=($search=="")?"WHERE $filter":"AND $filter";

 $query="SELECT COUNT(*) AS max FROM ".TABLE." $search $filter";
 $r=query($query);
 $row=mysql_fetch_array($r);
 $pager->max($row['max']);

 $limit="LIMIT ".$pager->from().",".$pager->incr();
 
 $query="SELECT * FROM ".TABLE." $search $filter ORDER BY $order $limit";
 $result=query($query);
 $filters=array();
 while($row=mysql_fetch_array($result)) {
   $date=$row['bug_date'];
   //Find out the date without the time of the subbmision
   $arr=getdate($row['bug_date']);
   $row['bug_date']=mktime(0,0,0,$arr['mon'],$arr['mday'],$arr['year']);
   
   $x++;
   $odd=$x%2;
   echo '<tr class="row r_'.$odd.'"><td class="row r_id">';
   echo '<a href="'.URL::redirect('#',array('bug'=>$row['bug_id']),true).'" class="normal"><div class="full">';
   echo $row['bug_id'];
   echo '</div></a>';
   echo '</td><td class="row r_error">';
   echo '<a href="'.URL::redirect('#',array('bug'=>$row['bug_id']),true).'" class="normal"><div class="full">';
   $text=translucate(html_entity_decode($row['bug_text']),45);
   $text=str_replace($q,'<div class="found">'.$q.'</div>',$text);
   echo $text;
   echo '</div></a>';
   echo '</td><td class="row r_date">';
   echo '<a href="'.URL::redirect('#',array('bug'=>$row['bug_id']),true).'" class="normal"><div class="full">';
   echo strftime('%c',$date);
   echo '</div></a>';
   echo '</td><td class="row r_cvs">';
   echo '<a href="'.URL::redirect('#',array('bug'=>$row['bug_id']),true).'" class="normal"><div class="full">';
   echo strftime('%c',$row['bug_cvsdate']);
   echo '</div></a>';
   echo '</td><td class="row r_amsn">';
   echo '<a href="'.URL::redirect('#',array('bug'=>$row['bug_id']),true).'" class="normal"><div class="full">';
   echo $row['bug_amsn'];
   echo '</div></a>';
   echo '</td><td class="row r_tcl">';
   echo '<a href="'.URL::redirect('#',array('bug'=>$row['bug_id']),true).'" class="normal"><div class="full">';
   echo $row['bug_tcl'];
   echo '</div></a>';
   echo '</td><td class="row r_os">';
   echo '<a href="'.URL::redirect('#',array('bug'=>$row['bug_id']),true).'" class="normal"><div class="full">';
   echo $row['bug_os'];
   echo '</div></a>';
   echo '</td><td class="row r_flag">';
   echo '<a href="'.URL::redirect('#',array('bug'=>$row['bug_id']),true).'" class="normal"><div class="full">';
   $flag=array_search($row['bug_flag'],$FLAGS);
   $flag=($flag===false)?'NONE':$flag;
   echo $flag;
   echo '</div></a>';
   echo '</td></tr>';
 }

 echo '<tr class="footer"><td colspan="8">
<table style="width: 100%">
<tr><td style="width: 10%">';
 $pager->display_prev();
echo '</td><td style="width: 80%; text-align: center">
<small>Created and owned by the <a href="http://amsn.sf.net">aMSN Project</a></small>
</td><td style="width:10%; text-align: right">';
 $pager->display_next();
echo '</td></tr>
</table></td></tr>';
 echo '</table>';
 echo '</form>';
}
?>
</body>
</html>
