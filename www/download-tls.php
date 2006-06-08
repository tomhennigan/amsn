<?php
switch ($_GET["arch"]) {
	case "src":
		$filename = "tls1.5.0-src.tar.gz";
		break;
	case "linuxx86":
		$filename = "tls-1.5.0-linux-x86.tar.gz";
		break;
}
if (isset($filename)){
	header("Location: http://switch.dl.sourceforge.net/sourceforge/amsn/".$filename);
} else {
	header("HTTP/1.0 404 Not Found");
}
?>
