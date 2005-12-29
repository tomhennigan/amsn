<?php
   define('source', 'poll-results');
   include 'common.php';
   include inc . 'init.php';
   include inc . 'header.php';
?>

<?php

$id = (isset($_GET['poll']) && ereg('^[0-9]+$', $_GET['poll'])) ? (int)$_GET['poll'] : 0;

$query_poll = mysql_query("SELECT `id`, `question` FROM `amsn_poll` " . ($id === 0 ? 'ORDER BY id DESC' : "WHERE `id` = '{$id}'"));

if (!mysql_num_rows($query_poll)) {
    echo "<p>The selected poll don't exists. Maybe it was removed</p>";
    return;
}

$poll = mysql_fetch_row($query_poll);

$query_answers = mysql_query("SELECT `answer`, `votes` FROM `amsn_poll_answers` WHERE `id_father` = '" . (int)$poll[0] . "' ORDER BY id");

if (mysql_num_rows($query_answers) > 1) {
    echo "<h3>{$poll[1]}</h3>\n<ul>\n";
    while ($row = mysql_fetch_row($query_answers))
        echo "<li>{$row[0]} (Votes: {$row[1]})</li>\n";
    echo "</ul>\n";
}

?>

<a href="index.php">Return to main page</a>

<?php include inc . 'footer.php'; ?>

