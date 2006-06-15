<?php

if (!defined('CPanel') || !isset($_SESSION['user'], $_SESSION['level'], $_GET['load']) || !user_level(3)) {
    require_once 'lib.misc.php';
    noperms();
    exit;
}

function form($name = '', $desc = '', $author = '', $screen = 0, $url = '', $idn = 0) {
?>
<form action="<?php echo htmlentities($_SERVER['REQUEST_URI']) ?>" method="post" id="form">
    <label for="skin_name">Name:</label>
    <input type="text" maxlength="100" name="skin_name" id="skin_name"<?php echo !empty($name) ? " value=\"$name\"" : '' ?> /><br />
    <label for="skin_desc">Description:</label>
    <input type="text" maxlength="255" name="skin_desc" id="skin_desc"<?php echo !empty($desc) ? " value=\"$desc\"" : '' ?> /><br />
    <label for="skin_author">Author:</label>
    <input type="text" maxlength="100" name="skin_author" id="skin_author"<?php echo !empty($author) ? " value=\"$author\"" : '' ?> /><br />
    <label for="skin_screen">Screenshot number:</label>
    <input type="text" maxlength="10" name="skin_screen" id="skin_screen"<?php echo " value=\"$screen\"" ?> /><br />
    <label for="url"><acronym title="Uniform Resource Locator">URL</acronym>:</label>
    <input type="text" maxlength="255" name="url" id="url"<?php echo !empty($url) ? " value=\"$url\"" : '' ?> /><br />
<?php
    if ($idn != 0) {
?>
    <input type="hidden" name="id" value="<?php echo $idn ?>" />
<?php
}
?>
    <input type="submit" />
</form>
<?php
}


if ($_GET['action'] == 'add') {
    if (isset($_POST['skin_name'], $_POST['skin_desc'], $_POST['skin_author'], $_POST['skin_screen'], $_POST['url']) && ereg('^[0-9]+$', $_POST['skin_screen'])) {
        $_POST = clean4sql($_POST);
        if (mysql_query("INSERT INTO `amsn_skins` (name, `desc`, author, url, screen) VALUES ('{$_POST['skin_name']}', '{$_POST['skin_desc']}', '{$_POST['skin_author']}', '{$_POST['url']}', '" . (int)$_POST['skin_screen'] . "')")) {
            echo "<p>Skin successfully added</p>\n";
            return;
        } else {
            echo "<p>An error ocurred while trying to add the skin to the database</p>\n";
            #echo mysql_error();
            form(htmlentities($_POST['skin_name']), htmlentities($_POST['skin_desc']), htmlentities($_POST['skin_author']), $_POST['skin_screen'], htmlentities($_POST['url']));
            return;
        }
    } else
        form();
} else if ($_GET['action'] == 'remove' || $_GET['action'] == 'edit') {
    if (!mysql_num_rows(($q = @mysql_query("SELECT * FROM `amsn_skins` ORDER BY `name` ASC")))) {
        echo "<p>There are no skins yet, you can <a href=\"cpanel.php?load=skins&amp;action=add\">add one</a></p>\n";
        return;
    }

    if (isset($_POST['id']) && ereg('^[1-9][0-9]*$', $_POST['id']) && !mysql_num_rows(($q = @mysql_query("SELECT * FROM `amsn_skins` WHERE id = '" . (int)$_POST['id'] . "' LIMIT 1")))) {
        echo "<p>The selected item don't exists</p>\n";
        return;
    }

    if ($_GET['action'] == 'remove' && isset($_POST['id']) && ereg('^[1-9][0-9]*$', $_POST['id'])) {
        if (mysql_query("DELETE FROM `amsn_skins` WHERE id = '" . (int)$_POST['id'] . "' LIMIT 1")) {
            echo "<p>Skin successfully deleted</p>\n";
            return;
        } else {
            #echo mysql_error();
            echo "<p>There was an error where trying to remove the skin from the database</p>\n";
        }
    }

    if ($_GET['action'] == 'edit' && isset($_POST['id'])) {
        if (isset($_POST['id'], $_POST['skin_name'], $_POST['skin_desc'], $_POST['skin_author'], $_POST['skin_screen'], $_POST['url']) && ereg('^[0-9]+$', $_POST['id']) && ereg('^[0-9]+$', $_POST['skin_screen'])) {
            $_POST = clean4sql($_POST);
            if (mysql_query("UPDATE `amsn_skins` SET name = '{$_POST['skin_name']}', `desc` = '{$_POST['skin_desc']}', author = '{$_POST['skin_author']}', screen = '". (int)$_POST['skin_screen'] ."', url = '{$_POST['url']}' WHERE id = '" . (int)$_POST['id'] . "' LIMIT 1")) {
                echo "<p>Skin successfully modified</p>\n";
                return;
            } else {
                #echo mysql_error();
                echo "<p>There was an error where trying to update the database registry</p>\n";
            }
        }

        $row = mysql_fetch_assoc($q);
        form(htmlentities(stripslashes($row['name'])), htmlentities(stripslashes($row['desc'])), htmlentities(stripslashes($row['author'])), (int)$row['screen'], htmlentities(stripslashes($row['url'])), $row['id']);
        return;
    }
?>
<form action="<?php echo htmlentities($_SERVER['REQUEST_URI']) ?>" method="post" id="form">
    <label for="id">Name:</label><select name="id" id="id">
<?php
while ($row = mysql_fetch_assoc($q)) {
?>
        <option value="<?php echo $row['id'] ?>"><?php echo htmlentities(stripslashes($row['name'])) ?></option>
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