<?php
error_reporting(0);
header("Pragma: no-cache"); 
header("Content-type: text/plain");

function addr(){ 
	if (getenv('HTTP_X_FORWARDED_FOR')) {
		$ip = getenv('HTTP_X_FORWARD_FOR');
		return $ip;
	} else {
		$ip = getenv('REMOTE_ADDR');
		return $ip;
	}
}

if(!isset($_GET['port']) || !is_numeric($_GET['port']) || !isset($_GET['id'])) {
	echo "-1";
} else {

	$socket = @socket_create(AF_INET, SOCK_STREAM, SOL_TCP);
	if ($socket < 0) {
		echo "-1";
		return;
	}

	@socket_set_option( $socket, SOL_SOCKET, SO_SNDTIMEO, array("sec"=>8,"usec"=>0) );

	$result = @socket_connect($socket, addr(), $_GET['port']);


	if ($result == 0) {
		echo "0";
	} else {
		if ( socket_select($r = array($socket), $w = NULL, $f = NULL, 8) > 0 ) { 
			$retval = @socket_read($socket, 10000, PHP_NORMAL_READ);
			#echo '"'.$retval.'"';
			if (!strncmp($retval,"AMSNPING".$_GET['id'],strlen("AMSNPING".$_GET['id']))) {
				echo "1";
			} else {
				echo "0";
			}
		} else {
			#Timeout : it's not aMSN on the other end
			echo "0";
		}

	}

	@socket_close($socket);
}
?>
