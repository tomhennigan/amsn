<?php
include 'common.php';

if(!isset($_GET['id'])) {
	die('ERROR! No file specified!');
}
$file=getFileURL($_GET['id']);

if($file == '') {
	die('ERROR! Bad file specified!');
}

@mysql_query("UPDATE `amsn_files` SET `count` = `count` + 1 WHERE id = '" . (int)$_GET['id'] . "' LIMIT 1");

header("Location: {$file}");
?>

<!DOCTYPE html
PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html>
<head>
<title>Redirect...</title>
</head>
<body>
Your web browser should have redirected you automatically. If not, please <a href="<?php echo $file; ?>">click here</a>.
</body>
</html>
