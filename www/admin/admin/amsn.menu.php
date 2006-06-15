<?php

if (!defined('CPanel') || !isset($_SESSION['user'], $_SESSION['level'], $_GET['load']) || !user_level(5)) {
    require_once 'lib.misc.php';
    noperms();
    exit;
}

function form($id = '', $url = '', $pos = 9, $idn = 0) {
?>
<form action="<?php echo htmlentities($_SERVER['REQUEST_URI']) ?>" method="post" id="form">
    <label for="men_id">Identifier:</label><input type="text" maxlength="40" name="men_id" id="men_id"<?php echo !empty($id) ? " value=\"$id\"" : '' ?> /><br />
    <label for="url"><acronym title="Uniform Resource Locator">URL</acronym>:</label><input type="text" maxlength="255" name="url" id="url"<?php echo !empty($url) ? " value=\"$url\"" : '' ?> /><br />
<?php
    if ($idn != 0) {
?>
    <input type="hidden" name="id" value="<?php echo $idn ?>" />
<?php
}
?>
    <label for="pos">Position:</label><select name="pos" id="pos">
<?php
    for ($i = 0; $i < 10; $i++)
        echo '        <option ' . ($pos == $i ? ' selected="selected"' : '') . ">$i</option>\n";
?>
    </select><br />
    <input type="submit" />
</form>
<?php
}


if ($_GET['action'] == 'add') {
    if (isset($_POST['men_id'], $_POST['url'], $_POST['pos']) && ereg('^[0-9]$', $_POST['pos'])) {
        $_POST = clean4sql($_POST);
        if (mysql_query("INSERT INTO `amsn_menu` (men_id, men_url, men_pos) VALUES ('{$_POST['men_id']}', '{$_POST['url']}', '" . (int)$_POST['pos'] . "')")) {
            echo "<p>Button successfully created</p>\n";
            return;
        } else {
            echo "<p>An error ocurred while trying to add the button to the database</p>\n";
            form(htmlentities($_POST['men_id']), htmlentities($_POST['url']), $_POST['pos']);
            return;
        }
    } else
        form();
} else if ($_GET['action'] == 'remove' || $_GET['action'] == 'edit') {
    if (!mysql_num_rows(($q = @mysql_query("SELECT * FROM `amsn_menu` ORDER BY `men_pos`, `men_id` ASC")))) {
        echo "<p>There are no menu items yet, you can <a href=\"index.php?load=menu&amp;action=add\">create one</a></p>\n";
        return;
    }

    if (isset($_POST['id']) && ereg('^[1-9][0-9]*$', $_POST['id']) && !mysql_num_rows(($q = @mysql_query("SELECT * FROM `amsn_menu` WHERE id = '" . (int)$_POST['id'] . "' LIMIT 1")))) {
        echo "<p>The selected item don't exists</p>\n";
        return;
    }

    if ($_GET['action'] == 'remove' && isset($_POST['id']) && ereg('^[1-9][0-9]*$', $_POST['id'])) {
        if (mysql_query("DELETE FROM `amsn_menu` WHERE id = '" . (int)$_POST['id'] . "' LIMIT 1")) {
            echo "<p>Button successfully deleted</p>\n";
            return;
        } else {
            echo "<p>There was an error where trying to remove the database registry</p>\n";
        }
    }

    if ($_GET['action'] == 'edit' && isset($_POST['id'])) {
        if (isset($_POST['id'], $_POST['men_id'], $_POST['url'], $_POST['pos']) && ereg('^[0-9]$', $_POST['id'])) {
            $_POST = clean4sql($_POST);
            if (mysql_query("UPDATE `amsn_menu` SET men_id = '{$_POST['men_id']}', men_url = '{$_POST['url']}', men_pos = '{$_POST['pos']}' WHERE id = '" . (int)$_POST['id'] . "' LIMIT 1")) {
                echo "<p>Button successfully modified</p>\n";
                return;
            } else {
                echo "<p>There was an error where trying to update the database registry</p>\n";
            }
        }

        $row = mysql_fetch_assoc($q);
        form(htmlentities(stripslashes($row['men_id'])), htmlentities(stripslashes($row['men_url'])), $row['men_pos'], $row['id']);
        return;
    }
?>
<form action="<?php echo htmlentities($_SERVER['REQUEST_URI']) ?>" method="post" id="form">
    <label for="id">Identifier:</label><select name="id" id="id">
<?php
while ($row = mysql_fetch_assoc($q)) {
?>
        <option value="<?php echo $row['id'] ?>"><?php echo htmlentities(stripslashes($row['men_id'])) ?></option>
<?php
}
?>
</select>
<input type="submit" />
</form>
<?php
} else {
    echo "<p>You have requested an unknow action</p>\n";
    return;
}
?>