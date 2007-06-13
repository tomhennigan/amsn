<?php
if (!defined('CPanel') || !isset($_SESSION['user'], $_SESSION['level'], $_GET['load']) || !user_level(3)) {
    require_once 'lib.misc.php';
    noperms();
    exit;
}

function form($name = '', $desc = '', $screen = -1, $idn = 0) {
?>
<script type="text/javascript" src="admin/files.js"> </script>

<form action="<?php echo htmlentities($_SERVER['REQUEST_URI']) ?>" method="post" id="form">
    <label for="shot_name">Name:</label>
    <input type="text" maxlength="100" size=70 name="shot_name" id="shot_name"<?php echo !empty($name) ? " value=\"$name\"" : '' ?> /><br />
    <label for="shot_desc">Description:</label>
    <input type="text" maxlength="255" size=100 name="shot_desc" id="shot_desc"<?php echo !empty($desc) ? " value=\"$desc\"" : '' ?> /><br />

    <label for="shot_screen_disp">Screenshot:</label>
    <input type="text" name="shot_screen_disp" readonly=true size=60 id="shot_screen_disp" value="<?php echo htmlentities(stripslashes(getFileName($screen))) ; ?>" />
    <input type="hidden" name="shot_screen" id="shot_screen" value="<?php echo getFileID($screen) ; ?>" /><br />
    <input type="button" onclick="javascript:switchVisibility('shot_screen',-1)" value='Pick a file' /><br />
    <div id="shot_screen_div" style="display: none;">
    <iframe src="" id="shot_screen_frame" width=600 ></iframe>
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
    if (isset($_POST['shot_name'], $_POST['shot_desc'], $_POST['shot_screen']) && ereg('^[0-9-]+$', $_POST['shot_screen'])) {
        $_POST = clean4sql($_POST);
        if (mysql_query("INSERT INTO `amsn_screenshots` (name, `desc`, screen_id) VALUES ('{$_POST['shot_name']}', '{$_POST['shot_desc']}', '" . (int)$_POST['shot_screen'] . "');")) {
            echo "<p>Screenshot successfully added</p>\n";
            return;
        } else {
            echo "<p>An error ocurred while trying to add the screenshot to the database</p>\n";
            #echo mysql_error();
            form(htmlentities($_POST['shot_name']), htmlentities($_POST['shot_desc']), $_POST['shot_screen']);
            return;
        }
    } else
        form();
} else if ($_GET['action'] == 'remove' || $_GET['action'] == 'edit' || $_GET['action'] == 'sort') {
    if (!mysql_num_rows(($all = @mysql_query("SELECT * FROM `amsn_screenshots` ORDER BY `order` DESC, `name` ASC")))) {
        echo "<p>There are no screenshots yet, you can <a href=\"index.php?load=screenshots&amp;action=add\">add one</a></p>\n";
        return;
    }

    if ($_GET['action'] == 'sort') {
?>

<div id="sort_list_div">
<iframe src="" id="sort_list_frame" name="sort_list_frame" style="width: 0px; height: 0px; border: 0px;"></iframe>
</div>
<script language="javascript"><!--
    function setid()
    {
        var field = document.getElementById("sort_id");
        var list = document.getElementById("list_ids");
        field.value = list.selectedIndex;
        return true;
    }
    //-->
</script>
<form action="admin/sort.screenshots.php" onsubmit="setid();" method="post" id="form" target="sort_list_frame">
<select size="20" id="list_ids">
<?php
        while ($row = mysql_fetch_assoc($all)) {
?>
        <option><?php echo htmlentities(stripslashes($row['name'])) ?></option>
<?php
        }
?>
</select>
<br />
<button name="sort" value="up" type="submit">Up</button>
<button name="sort" value="down" type="submit">Down</button>
<input type="hidden" name="sort_id" id="sort_id" value="" />
</form>
<?php
        return;
    }

    if (isset($_POST['id']) && ereg('^[1-9][0-9]*$', $_POST['id']) && !mysql_num_rows(($q = @mysql_query("SELECT * FROM `amsn_screenshots` WHERE id = '" . (int)$_POST['id'] . "' LIMIT 1")))) {
        echo "<p>The selected item don't exists</p>\n";
        return;
    }

    if ($_GET['action'] == 'remove' && isset($_POST['id']) && ereg('^[1-9][0-9]*$', $_POST['id'])) {
        if (mysql_query("DELETE FROM `amsn_screenshots` WHERE id = '" . (int)$_POST['id'] . "' LIMIT 1")) {
            echo "<p>Screenshot successfully deleted</p>\n";
            return;
        } else {
            #echo mysql_error();
            echo "<p>There was an error where trying to remove the screenshot from the database</p>\n";
        }
    }

    if ($_GET['action'] == 'edit' && isset($_POST['id'])) {
        if (isset($_POST['id'], $_POST['shot_name'], $_POST['shot_desc'], $_POST['shot_screen']) && ereg('^[0-9]+$', $_POST['id']) && ereg('^[0-9-]+$', $_POST['shot_screen'])) {
            $_POST = clean4sql($_POST);
            if (mysql_query("UPDATE `amsn_screenshots` SET name = '{$_POST['shot_name']}', `desc` = '{$_POST['shot_desc']}', screen_id = '". (int)$_POST['shot_screen'] ."' WHERE id = '" . (int)$_POST['id'] . "' LIMIT 1")) {
                echo "<p>Screenshot successfully modified</p>\n";
                return;
            } else {
                #echo mysql_error();
                echo "<p>There was an error where trying to update the database registry</p>\n";
            }
        }

        $row = mysql_fetch_assoc($q);
        form(htmlentities(stripslashes($row['name'])), htmlentities(stripslashes($row['desc'])), (int)$row['screen_id'], $row['id']);
        return;
    }
?>
<form action="<?php echo htmlentities($_SERVER['REQUEST_URI']) ?>" method="post" id="form">
    <label for="id">Name:</label><select name="id" id="id">
<?php
while ($row = mysql_fetch_assoc($all)) {
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