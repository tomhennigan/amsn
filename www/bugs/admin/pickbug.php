<?php
include('../../config.inc.php');
include('../common.inc.php');
include('../../libs/url.class.php');
include('../../libs/bugreport.class.php');
include('../../libs/func.lib.php');
include('../../libs/pager.class.php');

if(!bug_exists($_GET['bug'])) {
  die('Specify a bug report!');
}

if(isset($_GET['pick'])) {
  if($_GET['pick']=='new') {
    $bug=new BugReport();
    $bug->loaddb($_GET['bug']);
    $text=ereg_prepare($bug->text);
    $stack=ereg_prepare($bug->stack);
    $query="INSERT INTO ".TBUGS." (bug_error_regexp,bug_stack_regexp) VALUES ('".mysql_real_escape_string($text)."','".mysql_real_escape_string($stack)."')";
    $result=mysql_query($query) or die("MySQL Error: ".mysql_error());
    $bug->bug=mysql_insert_id();
    $bug->update2db();
    echo "<script type=\"text/javascript\">\n";
    echo "<!--\n";
    echo "window.opener.location='index.php?show=bug&id=".$bug->bug."'\n";
    echo "window.close()\n";
    echo "-->\n";
    echo "</script>";
  } else {
    $bug=new BugReport();
    $bug->loaddb($_GET['bug']);
    $bug->bug=$_GET['pick'];
    $bug->update2db();
    echo "<script type=\"text/javascript\">\n";
    echo "<!--\n";
    echo "window.opener.location.reload()\n";
    echo "window.close()\n";
    echo "-->\n";
    echo "</script>";
  }
}
?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html>
<head>
<title>Pick a Bug</title>
<link rel="stylesheet" href="../main.css" type="text/css" />
<script type="text/javascript" src="../main.js"></script>
</head>
<body class="picker">
<b style="text-align: center;display:block">Pick a Bug</b>
<table cellpadding="0" cellspacing="0" class="db">
<?php
echo '<tr class="header" style="height: 10px"><td class="header" style="text-align: left;"><a class="header" href="?bug='.$_GET['bug'].'&amp;pick=new">New</a></td>';
?>
<td style="text-align:right">
<form action="#" method="post" class="inline">
<span><input type="text" name="search" /></span>
</form>
</td></tr>

<?php
$search=(isset($_POST['search']))?' WHERE bug_name LIKE \'%'.$_POST['search'].'%\'':'';
$pager=new Pager();
$query="SELECT COUNT(*) AS max FROM ".TBUGS." $search";
$r=query($query);
$row=mysql_fetch_array($r);
$pager->max($row['max']);

$limit="LIMIT ".$pager->from().",".$pager->incr();

$query="SELECT * FROM ".TBUGS." $search ORDER BY bug_id DESC $limit";
$result=mysql_query($query) or die("MySQL Error: ".mysql_error());
while($row=mysql_fetch_array($result)) {
  $odd=($x++)%2;
  echo '<tr class="row r_'.$odd.'"><td class="row" colspan="2"><a href="?bug='.$_GET['bug'].'&amp;pick='.$row['bug_id'].'">'.$row['bug_id'].' - '.translucate($row['bug_name'],20).'</a></td></tr>';
}

echo '<tr class="footer"><td colspan="2">';
$pager->display();
echo '</td></tr>';
?>

</table>
</body>
</html>