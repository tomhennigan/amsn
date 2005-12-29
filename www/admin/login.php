<?php
require_once '../common.php';

if (isset($_POST['user'], $_POST['pass'])) {
    define('CPanel', true);
    require_once 'admin/lib.user.php';
    if (!user_login($_POST['user'], $_POST['pass']))
        echo "\t<p>Incorrect user or password, try again please</p>\n", mysql_error();
    else {
        //session_regenerate_id();
        header('Refresh: 1; url=' . (isset($_SERVER['HTTP_REFERER']) ? $_SERVER['HTTP_REFERER'] : 'index.php'));
        echo '<p>Correct data, you are being redirected to the <a href="index.php">control panel</a></p>';
    }
}
?>
