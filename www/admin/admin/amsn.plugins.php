<?php

if (!defined('CPanel') || !isset($_SESSION['user'], $_SESSION['level'], $_GET['load']) || !user_level(3)) {
    require_once 'lib.misc.php';
    noperms();
    exit;
}

function form($name = '', $desc = '', $author = '', $version = '', $platform = '', $requires = '', $screen = -1, $file = -1, $idn = -1) {
?>
<script type="text/javascript" src="admin/files.js"> </script>

<form action="<?php echo htmlentities($_SERVER['REQUEST_URI']) ?>" method="post" id="form">
    <label for="plugin_name">Name:</label>
    <input type="text" maxlength="100" size=70 name="plugin_name" id="plugin_name"<?php echo !empty($name) ? " value=\"$name\"" : '' ?> /><br />
    <label for="plugin_desc">Description:</label>
    <input type="text" maxlength="255" size=100 name="plugin_desc" id="plugin_desc"<?php echo !empty($desc) ? " value=\"$desc\"" : '' ?> /><br />
    <label for="plugin_author">Author:</label>
    <input type="text" maxlength="100" name="plugin_author" id="plugin_author"<?php echo !empty($author) ? " value=\"$author\"" : '' ?> /><br />
    <label for="plugin_version">Version:</label>
    <input type="text" maxlength="20" name="plugin_version" id="plugin_version"<?php echo !empty($version) ? " value=\"$version\"" : '' ?> /><br />
    <label for="plugin_platform">Platform/OS:</label>
    <input type="text" maxlength="50" name="plugin_platform" id="plugin_platform"<?php echo !empty($platform) ? " value=\"$platform\"" : '' ?> /><br />
    <label for="plugin_requires">Requires:</label>
    <input type="text" maxlength="50" name="plugin_requires" id="plugin_requires"<?php echo !empty($requires) ? " value=\"$requires\"" : '' ?> /><br />

    <label for="plugin_screen_disp">Screenshot:</label>
    <input type="text" name="plugin_screen_disp" readonly=true size=60 id="plugin_screen_disp" value="<?php echo htmlentities(stripslashes(getFileName($screen))) ; ?>" />
    <input type="hidden" name="plugin_screen" id="plugin_screen" value="<?php echo getFileID($screen) ; ?>" /><br />
    <input type="button" onclick="javascript:switchVisibility('plugin_screen',-1)" value='Pick a file' /><br />
    <div id="plugin_screen_div" style="display: none;">
    <iframe src="" id="plugin_screen_frame" width=600 ></iframe>
    </div><br />

    <label for="plugin_file_disp">File:</label>
    <input type="text" name="plugin_file_disp" readonly=true size=60 id="plugin_file_disp" value="<?php echo htmlentities(stripslashes(getFileName($file))) ; ?>" />
    <input type="hidden" name="plugin_file" id="plugin_file" value="<?php echo getFileID($file) ; ?>" /><br />
    <input type="button" onclick="javascript:switchVisibility('plugin_file',-1)" value='Pick a file' /><br />
    <div id="plugin_file_div" style="display: none;">
    <iframe src="" id="plugin_file_frame" width=600 ></iframe>
    </div><br />
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
    if (isset($_POST['plugin_name'], $_POST['plugin_desc'], $_POST['plugin_author'], $_POST['plugin_version'], $_POST['plugin_platform'], $_POST['plugin_requires'], $_POST['plugin_screen'], $_POST['plugin_file']) && ereg('^[0-9-]+$', $_POST['plugin_screen']) && ereg('^[0-9-]+$', $_POST['plugin_file'])) {
        $_POST = clean4sql($_POST);
        if (mysql_query("INSERT INTO `amsn_plugins` (name, `desc`, author, version, platform, requires, file_id, screen_id) VALUES ('{$_POST['plugin_name']}', '{$_POST['plugin_desc']}', '{$_POST['plugin_author']}', '{$_POST['plugin_version']}', '{$_POST['plugin_platform']}', '{$_POST['plugin_requires']}', " . (int)$_POST['plugin_file'] . ", " . (int)$_POST['plugin_screen'] . "')")) {
            echo "<p>Plugin successfully added</p>\n";
            return;
        } else {
            echo "<p>An error ocurred while trying to add the plugin to the database</p>\n";
            #echo mysql_error();
            form(htmlentities($_POST['plugin_name']), htmlentities($_POST['plugin_desc']), htmlentities($_POST['plugin_author']), htmlentities($_POST['plugin_version']), htmlentities($_POST['plugin_platform']), htmlentities($_POST['plugin_requires']), $_POST['plugin_screen'], htmlentities($_POST['plugin_file']));
            return;
        }
    } else
        form();
} else if ($_GET['action'] == 'remove' || $_GET['action'] == 'edit') {
    if (!mysql_num_rows(($q = @mysql_query("SELECT * FROM `amsn_plugins` ORDER BY `name` ASC")))) {
        echo "<p>There are no plugins yet, you can <a href=\"index.php?load=plugins&amp;action=add\">add one</a></p>\n";
        return;
    }

    if (isset($_POST['id']) && ereg('^[1-9][0-9]*$', $_POST['id']) && !mysql_num_rows(($q = @mysql_query("SELECT * FROM `amsn_plugins` WHERE id = '" . (int)$_POST['id'] . "' LIMIT 1")))) {
        echo "<p>The selected item don't exists</p>\n";
        return;
    }

    if ($_GET['action'] == 'remove' && isset($_POST['id']) && ereg('^[1-9][0-9]*$', $_POST['id'])) {
        if (mysql_query("DELETE FROM `amsn_plugins` WHERE id = '" . (int)$_POST['id'] . "' LIMIT 1")) {
            echo "<p>Plugin successfully deleted</p>\n";
            return;
        } else {
            #echo mysql_error();
            echo "<p>There was an error where trying to remove the plugin from the database</p>\n";
        }
    }

    if ($_GET['action'] == 'edit' && isset($_POST['id'])) {
        if (isset($_POST['plugin_name'], $_POST['plugin_desc'], $_POST['plugin_author'], $_POST['plugin_version'], $_POST['plugin_platform'], $_POST['plugin_requires'], $_POST['plugin_screen'], $_POST['plugin_file']) && ereg('^[0-9-]+$', $_POST['plugin_screen']) && ereg('^[0-9-]+$', $_POST['plugin_file'])) {
            $_POST = clean4sql($_POST);
            if (mysql_query("UPDATE `amsn_plugins` SET name = '{$_POST['plugin_name']}', `desc` = '{$_POST['plugin_desc']}', author = '{$_POST['plugin_author']}', version = '{$_POST['plugin_version']}', platform = '{$_POST['plugin_platform']}', requires = '{$_POST['plugin_requires']}', screen_id = '". (int)$_POST['plugin_screen'] ."', file_id = '".(int)$_POST['plugin_file']."' WHERE id = '" . (int)$_POST['id'] . "' LIMIT 1")) {
                echo "<p>Plugin successfully modified</p>\n";
                return;
            } else {
                #echo mysql_error();
                echo "<p>There was an error where trying to update the database registry</p>\n";
            }
        }

        $row = mysql_fetch_assoc($q);
        form(htmlentities(stripslashes($row['name'])), htmlentities(stripslashes($row['desc'])), htmlentities(stripslashes($row['author'])), htmlentities(stripslashes($row['version'])), htmlentities(stripslashes($row['platform'])), htmlentities(stripslashes($row['requires'])), (int)$row['screen_id'], (int)$row['file_id'], $row['id']);
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