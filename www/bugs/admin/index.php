<?php
include('../../config.inc.php');
include('../common.inc.php');
include('../../libs/url.class.php');
include('../../libs/bugreport.class.php');
include('../../libs/func.lib.php');
include('../../libs/sf.lib.php');
include('../../libs/pager.class.php');
include('../../libs/tabler.class.php');
include('../../libs/bug.class.php');

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
<script type="text/javascript" src="../main.js"></script>
</head>
<body>
<div class="navig">
<?php
include 'navig.inc.php';
?>
</div>
<div class="top">
<?php
$show=(isset($_GET['show']))?$_GET['show']:'main';
include 'show'.$show.'.inc.php';
?>
</div>
<div class="footer">
<small>Created and owned by the <a href="http://amsn.sf.net">aMSN Project</a></small>
</div>
</body>
</html>
