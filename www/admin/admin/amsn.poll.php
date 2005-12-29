<?php

if (!defined('CPanel') || !isset($_SESSION['user'], $_SESSION['level'], $_GET['load'], $_GET['action'])) {
    require_once 'lib.misc.php';
    noperms();
    exit;
}

if ($_GET['action'] == 'add') {
    if (!user_level(3)) {
        noperms();
        return;
    }

    if (isset($_POST['question'], $_POST['answers']) && ($c = @count($_POST['answers'])) > 1 && $c < 11) {
        $_POST = clean4sql($_POST);
        clean_empty_keys($_POST['answers']);
        if (empty($_POST['question']) || count($_POST['answers']) < 2) {
        	echo "<p>You must provide a valid question and at least two possible answers</p>\n";
        	return;
        }

		if (!@mysql_query("INSERT INTO `amsn_poll` SET `question` = '{$_POST['question']}', `time` = UNIX_TIMESTAMP()")) {
			echo "<p>An error ocurred while trying to add the question. MySQL returned: <samp>" . mysql_error() . "</samp></p>\n";
			return;
		}

		$values = array();
		$id = (int)mysql_insert_id();
		foreach ($_POST['answers'] as $v)
			$values[] = "($id, '$v')";
		$values = implode(', ', $values);
		
		if (!@mysql_query(($s = "INSERT INTO `amsn_poll_answers` (id_father, answer) VALUES $values"))) {
		    echo "<p>An error ocurred while trying to insert the answers. MySQL returned: <samp>" . mysql_error() . "</samp><br />$s</p>\n";
		    mysql_query("DELETE FROM `amsn_poll` WHERE `id` = $id LIMIT 1");
		    return;
		}

        echo "<p>The poll is successfully created</p>\n";
        return;
    }
?>
<form action="<?php echo htmlentities($_SERVER['REQUEST_URI']) ?>" method="post" id="form">
    <label for="question">Question:</label><input type="text" name="question" id="question" maxlength="150" /><br />
    <p>Fill only the fields that you need:</p>
<?php
for ($i = 1; $i < 11; $i++)
    echo '     <label for="answer' . $i . '">Answer ' . $i . ':</label><input type="text" name="answers[]" id="answer' . $i . "\" /><br />\n";
?>
    <input type="submit" />
</form>
<?php
} else if ($_GET['action'] == 'remove') {
    if (!user_level(4)) {
        noperms();
        return;
    }

    if (isset($_POST['question']) && ereg('^[1-9][0-9]*$', ($_POST['question'] = (int)$_POST['question']))) {
        if (mysql_query("DELETE FROM `amsn_poll` WHERE id = '{$_POST['question']}' LIMIT 1") && mysql_query("DELETE FROM `amsn_poll_answers` WHERE id_father = '{$_POST['question']}'")) {
            echo "<p>The poll was successfully removed</p>";
            return;
        } else {
            echo "<p>An error ocurred while trying to remove the poll or the answers</p>";
            return;
        }
        
    }

    $query = mysql_query("SELECT id, question FROM `amsn_poll` ORDER BY time ASC");
    if (!mysql_num_rows($query)) {
        echo "There are no polls yet, you can <a href=\"cpanel.php?load=poll&action=add\">create one</a>.\n";
        return;    
    }
?>
<form action="<?php echo htmlentities($_SERVER['REQUEST_URI']) ?>" method="post">
    <label for="question">Question:</label><select name="question" id="question">
<?php
    for ($i = 1; $row = mysql_fetch_row($query); $i++)
        echo "        <option value=\"{$row[0]}\">$i: {$row[1]}</option>\n";
?></select><br />
    <input type="submit" onclick="if(confirm('Are you sure?\nThe poll and the answers will be removed')){return true;}else{return false;}" />
</form>
<?php
} else {
    echo "<p>You have requested an unknow action</p>\n";
    return;
}

?>