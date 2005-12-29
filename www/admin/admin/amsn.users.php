<?php

if (!defined('CPanel') || !isset($_SESSION['user'], $_SESSION['level'], $_GET['load'])) {
    require_once 'lib.misc.php';
    noperms();
    exit;
}

if ($_GET['action'] == 'add') {
    if (!user_level(5)) {
        noperms();
        return;
    }

    if (isset($_POST['user'], $_POST['mail'], $_POST['level'])) {
        if (user_new($_POST['user'], $_POST['mail'], $_POST['level'])) {
            echo "<p>New user <strong>{$_POST['user']}</strong> created with level <strong>{$_POST['level']}</strong></p>\n<p>An e-mail was sent to <strong>{$_POST['mail']}</strong> containing a random generated password</p>\n";
            return;
        } else
            echo "<p>An error ocurred, check the fields to find what happens</p>\n<p>The e-mail <strong>must</strong> be true</p>\n";
    }
?>
<form action="<?php echo htmlentities($_SERVER['REQUEST_URI']) ?>" method="post">
    <label for="user">User:</label><input type="text" name="user" id="user" maxlength="20"<?php if (isset($_POST['user'])) echo ' value="' . $_POST['user'] . '"' ?> /><br />
    <label for="mail">E-Mail:</label><input type="text" name="mail" id="mail" maxlength="50"<?php if (isset($_POST['mail'])) echo ' value="' . $_POST['mail'] . '"' ?> /><br />
    <label for="level">Level:</label><select name="level" id="level">
        <option>1</option>
        <option>2</option>
        <option>3</option>
        <option>4</option>
        <option>5</option>
    </select><br />
    <input type="submit" />
</form>
<?php
} else if ($_GET['action'] == 'remove') {
    if (!user_level(5)) {
        noperms();
        return;
    }

    if (isset($_POST['user'])) {
        if (user_remove($_POST['user'])) {
            echo "<p>User successfully deleted</p>\n";
            return;
        } else
                echo "<p>An error ocurred, maybe is a database error or you. Please, try it again later</p>\n";
    }

    $query = mysql_query("SELECT `id`, `user` FROM `amsn_users` ORDER BY `user` ASC");

if (!mysql_num_rows($query)) {
    echo "<p>There are no users to remove</p>\n";
    return;
}

?>
<form action="<?php echo htmlentities($_SERVER['REQUEST_URI']) ?>" method="post">
    <label for="user">User:</label><select name="user" id="user">
<?php
while ($row = mysql_fetch_row($query))
    echo '        <option value="' . $row[0] . '">' . $row[1] . "</option>\n";
?>
    </select><br />
    <input type="submit" />
</form>
<?php
} else if ($_GET['action'] == 'edit') {
    if ((isset($_POST['user']) && !isset($_POST['nick'], $_POST['oldpass'], $_POST['newpass'])) || (!user_level(5) && $_POST['user'] = $_SESSION['user'])) {
        if (!user_level(5) && $_SESSION['user'] != $_POST['user']) {
            noperms();
            return;
        }

        $query = @mysql_query("SELECT `user`, `email`, `level` FROM `amsn_users` WHERE `user` = '" . mysql_real_escape_string($_POST['user']) . "' LIMIT 1");
        if (!mysql_num_rows($query)) {
            echo "<p>The selected user don't exists on the database</p>\n";
            return;
        }

        $row = mysql_fetch_row($query);
?>
<form action="<?php echo htmlentities($_SERVER['REQUEST_URI']) ?>" method="post">
    User: <strong><?php echo $row[0] ?></strong><br />
    <input type="hidden" name="nick" value="<?php echo stripslashes($_POST['user']) ?>" />
    <label for="mail">E-Mail:</label><input type="text" name="mail" id="mail" value="<?php echo $row[1] ?>" /><br />
<?php
if (user_level(5)) {
    echo '    <label for="level">Level:</label><select name="level" id="level">' . "\n";
    for ($i = 1; $i < 6; $i++)
        echo "        <option" . ($i == (int)$row[2] ? ' selected="selected"': ''). ">$i</option>\n";
    echo "    </select><br />\n";
}
?>
    <label for="oldpass">Old Password:</label><input type="password" name="oldpass" id="oldpass" /><br />
    <label for="newpass">New Password:</label><input type="password" name="newpass" id="newpass" /><br />
    <input type="submit" />
</form>
<?php
    } else if (!isset($_POST['user']) && isset($_POST['nick'], $_POST['mail'], $_POST['oldpass'], $_POST['newpass'])) {
        if (user_edit($_POST['nick'], $_POST['mail'], (isset($_POST['level']) ? $_POST['level'] : null), $_POST['oldpass'], $_POST['newpass'])) {
            echo "<p>User " . stripslashes($_POST['nick']) . " successfully updated</p>\n";
        } else {
            echo "<p>An error ocurred when tried to update the user. Are you sure that the fields contain correct values?</p>\n";
        }
    } else {
        $query = @mysql_query("SELECT `user`, `level` FROM `amsn_users` ORDER BY `user` ASC");
        if (!@mysql_num_rows($query)) {
            echo "<p>There are no users to edit</p>\n";
            return;
        }
?>
<form action="<?php echo htmlentities($_SERVER['REQUEST_URI']) ?>" method="post">
    <label for="user">User:</label><select name="user" id="user">
<?php
        while ($user = mysql_fetch_row($query))
            echo "        <option value=\"{$user[0]}\">{$user[0]} (Level {$user[1]})</option>\n";
?>
    </select><br />
    <input type="submit" />
</form>
<?php
    }
} else {
    echo "<p>You have requested an unknow action</p>\n";
    return;
}

?>