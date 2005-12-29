<?php

if (!isset($_POST['poll_answer'], $_POST['idf']) || !ereg('^[0-9]+$', $_POST['poll_answer']) || !ereg('^[0-9]+$', $_POST['idf'])) exit;

require_once '../common.php';

function getip() {
    if (isset($_SERVER['HTTP_X_FORWARDED_FOR']))
        $ip = $_SERVER['HTTP_X_FORWARDED_FOR'];
    elseif (isset($_SERVER['HTTP_VIA']))
        $ip = $_SERVER['HTTP_VIA'];
    elseif (isset($_SERVER['REMOTE_ADDR']))
        $ip = $_SERVER['REMOTE_ADDR'];
    else
        $ip = false;
    
    return gethostbyname($ip);
}

$ip = mysql_real_escape_string(getip());

if (false !== ($ip = mysql_real_escape_string(getip()))) {
    $query = "SELECT `ip` FROM `amsn_poll_votes` WHERE `ip` = '$ip' AND poll_id = '{$_POST['idf']}' LIMIT 1";
    $query = @mysql_query($query) or die(mysql_error());
    if (!mysql_num_rows($query)) {
        mysql_query("UPDATE `amsn_poll_answers` SET `votes` = `votes` + 1 WHERE id = '{$_POST['poll_answer']}' LIMIT 1") or die(mysql_error());
        mysql_query("INSERT INTO `amsn_poll_votes` SET ip = '$ip', poll_id = '{$_POST['idf']}', time = UNIX_TIMESTAMP()") or die(mysql_error());
    }
}

header('Location: ../poll_results.php?poll=' . $_POST['idf']);

?>