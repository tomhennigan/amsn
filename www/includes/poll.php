<?php

if (!defined('inc')) exit;

$id = (isset($_GET['poll']) && ereg('^[0-9]+$', $_GET['poll'])) ? (int)$_GET['poll'] : 0;

$query = mysql_query("SELECT id, question FROM `amsn_poll`  " . ($id === 0 ? 'ORDER BY time DESC' : "WHERE `id` = '{$id}'") ." LIMIT 1");

if (mysql_num_rows($query) === 1) {
    $poll = mysql_fetch_assoc($query);
    $answers = mysql_query("SELECT id, answer FROM `amsn_poll_answers` WHERE id_father = '" . (int)$poll['id'] . "' ORDER BY id"); 
    if (mysql_num_rows($answers) > 1) {
?>
<h4><?php echo $poll['question'] ?></h4>
<form action="<?php echo inc . 'poll_vote.php' ?>" method="post">
<input type="hidden" name="idf" value="<?php echo $poll['id'] ?>" />
<ul>
<?php
        for ($i = 0; $row = mysql_fetch_row($answers); $i++) {
?>
    <li><input type="radio" value="<?php echo $row[0] ?>" name="poll_answer" id="answer<?php echo $i ?>" /><label for="answer<?php echo $i ?>"><?php echo $row[1] ?></label></li>
<?php
        }
?>
</ul>
<input type="submit" value="Vote" />
<a href="poll_results.php<?php if (isset($_GET['poll']) && ereg('^[0-9]+$', $_GET['poll'])) echo '?poll=' . $_GET['poll'] ?>">View results</a>
</form>
<?php
    }
}

?>
