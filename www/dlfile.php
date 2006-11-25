<?php
require_once 'common.php';

if(isset($_GET['file'])) {
  $file=$_GET['file'];
} else {
  die("No file selected!");
}

$url="http://prdownloads.sourceforge.net/amsn/".$file;

header("Location: ".$url);
?>

<!DOCTYPE html
PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html>
<head>
<title>Redirect...</title>
</head>
<body>
Your web browser should have redirected you automaticly. If not, please <a href="<?php echo $url; ?>">click here</a>.
</body>
</html>
