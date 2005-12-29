<?php
require_once '../common.php';
session_start();
$_SESSION = array();
session_unset();
session_destroy();
header("Location: " . (isset($_SERVER['HTTP_REFERER']) ? $_SERVER['HTTP_REFERER'] : '.'));

?>
