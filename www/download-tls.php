<?php
switch ($_GET["arch"]) {
	case "linuxx86":
		$filename = "tls-1.5.0-linux-x86.tar.gz";
		break;
	case "linuxx86_64":
		$filename = "tls1.5-linux-x86_64.tar.gz";
		break;
	case "linuxppc":
		$filename = "tls1.4.1-linux-ppc.tar.gz";
		break;
	case "linuxsparc":
		$filename = "tls1.4.1-linux-sparc.tar.gz";
		break;
	case "netbsdx86":
		$filename = "ls1.4.1-netbsd-x86.tar.gz";
		break;
	case "netbsdsparc64":
		$filename = "tls1.4.1-netbsd-sparc64.tar.gz";
		break;
	case "freebsdx86":
		$filename = "tls1.4.1-freebsd-x86.tar.gz";
		break;
	case "solaris26"
		$filename = "tls1.4.1-solaris26-sparc.tar.gz";
		break;
	case "solaris28":
		$filename = "tls1.5.0-solaris28-sparc.tar.gz";
		break;
	case "win32":
		$filename = "tls1.5.0-win32.zip";
		break;
	case "mac":
		$filename = "tls1.5.0-mac.tar.gz";
		break;
	case "src":
		$filename = "tls1.5.0-src.tar.gz";
		break;
}
if (isset($filename)){
	header("Location: http://switch.dl.sourceforge.net/sourceforge/amsn/".$filename);
} else {
	header("HTTP/1.0 404 Not Found");
}
?>
