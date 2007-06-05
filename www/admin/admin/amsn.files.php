<?php
if (!defined('CPanel') || !isset($_SESSION['user'], $_SESSION['level'], $_GET['load']) || !user_level(3)) {
    require_once 'lib.misc.php';
    noperms();
    exit;
}

function treatUploadForm()
{
	if (isset($_FILES['file'])) {
		$_POST = clean4sql($_POST);
		if (move_uploaded_file($_FILES['file']['tmp_name'], getFilePath($_FILES['file']['name']))) {
			$q = mysql_query("SELECT * FROM `amsn_files` WHERE id = ".(int)$_POST['id'].";");
			$row = mysql_fetch_assoc($q);
			if ($row['filename'] != '' ) {
				unlink(getFilePath($row['filename']));
			}
			if (mysql_query("UPDATE `amsn_files` SET filename = '".$_FILES['file']['name']."', `url` = '', `lastmod` = NOW() WHERE id = '" . (int)$_POST['id'] . "' LIMIT 1")) {
				return array('success' => "File successfully modified");
			} else {
				#echo mysql_error();
				return array('error' => "There was an error when trying to update the database registry");
			}
		} else {
			return array('error' => "There was an error when trying to move the file");
		}
	}
}

function treatURLForm()
{
	if (isset($_POST['url'])) {
		$_POST = clean4sql($_POST);
		$q = mysql_query("SELECT id  FROM `amsn_files` WHERE id = ".(int)$_POST['id'].";");
		$row = mysql_fetch_assoc($q);
		if ($row['filename'] != '' ) {
			unlink(getFilePath($row['filename']));
		}
		if (mysql_query("UPDATE `amsn_files` SET filename = '', `url` = '{$_POST['url']}', `lastmod` = NOW() WHERE id = '" . (int)$_POST['id'] . "' LIMIT 1")) {
			return array('success' => "File successfully modified");
		} else {
			#echo mysql_error();
			return array('error' => "There was an error when trying to update the database registry");
            	}
	}
}

function treatURLUploadForm()
{
	if (isset($_POST['url'])) {
// Here we get the file name
		$filename = $_POST['url'];

		$ch = curl_init($_POST['url']);

		curl_setopt($ch, CURLOPT_HEADER, 1);
		curl_setopt($ch, CURLOPT_NOBODY, 1);
		curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
		$headers = curl_exec($ch);
		curl_close($ch);
		$headers = explode("\n",$headers);
		foreach($headers as $header) {
			$header = trim($header);
			if(strncasecmp($header,"Content-Disposition:",20) == 0) {
				$content = explode(";",$header);
				foreach($content as $tag) {
					$tag = trim($tag);
					if(strncasecmp($tag,"filename=",9) == 0) {
						$filename = trim(substr($tag,9));
						if (substr($filename,0,1) == '"' && substr($filename,strlen($filename)-1,1) == '"') {
							$filename = substr($filename,1,strlen($filename)-2);
						}
					}
				}
			}
		}
		$filename = basename($filename);
		if (copy($_POST['url'], getFilePath($filename))) {
			$q = mysql_query("SELECT * FROM `amsn_files` WHERE id = ".(int)$_POST['id'].";");
			$row = mysql_fetch_assoc($q);
			if ($row['filename'] != '' ) {
				unlink(getFilePath($row['filename']));
			}
			if (mysql_query("UPDATE `amsn_files` SET filename = '".$filename."', `url` = '', `lastmod` = NOW() WHERE id = '" . (int)$_POST['id'] . "' LIMIT 1")) {
				return array('success' => "File {$filename} successfully modified");
			} else {
				#echo mysql_error();
				return array('error' => "There was an error when trying to update the database registry");
			}
		} else {
			return array( 'error' => "Copy file error" );
		}
	}
}

function form($url = '', $filename = '', $idn = -1) {
?>
<form action="<?php echo htmlentities($_SERVER['REQUEST_URI']) ?>" method="post" enctype="multipart/form-data">
    <label for="screen">File:</label><input type="file" id="file" name="file" /><br />
    <input type="hidden" name="type" value="upload"/>
<?php
    if ($idn != -1) {
?>
    <input type="hidden" name="id" value="<?php echo $idn ?>" />
<?php
}
?>
    <input type="submit" />
</form>
<form action="<?php echo htmlentities($_SERVER['REQUEST_URI']); ?>" method="post">
    <label for="screen">URL:</label>
    <input type="text" id="url" name="url" size=50/><br />
    <input type="button" onclick="document.getElementById('url').value = 'http://prdownloads.sourceforge.net/amsn/';" value="File on FRS" />
    <input type="button" onclick="document.getElementById('url').value = 'http://amsn.sourceforge.net/wiki/show_image.php?id=';" value="Image on Wiki" />
    <input type="checkbox" name="upload_file" value="yes">Upload file</input><br />
    <input type="hidden" name="type" value="url"/>
<?php
    if ($idn != -1) {
?>
    <input type="hidden" name="id" value="<?php echo $idn ?>" />
<?php
}
?>
    <input type="submit" />
</form>
<?php
}
if ($_GET['action'] == 'stats') {
    $q = @mysql_query("SELECT `name`, `count` FROM `amsn_skins`, `amsn_files` WHERE `amsn_skins`.`file_id` = `amsn_files`.`id` ORDER BY `count` DESC, `name`;");
?>
<table><strong>Skins statistics</strong>
    <tr><th>Name</th><th>Count</th></tr>
<?php
    while ($row = mysql_fetch_assoc($q)) {
?>
    <tr><td><?php echo $row['name']; ?></td><td><?php echo $row['count']; ?></td><tr>
<?php
    }
?>
</table></p>
<?php
    $q = @mysql_query("SELECT `name`, `count` FROM `amsn_plugins`, `amsn_files` WHERE `amsn_plugins`.`file_id` = `amsn_files`.`id` ORDER BY `count` DESC, `name`;");
?>
<p><strong>Plugins statistics</strong>
<table>
    <tr><th>Name</th><th>Count</th></tr>
<?php
    while ($row = mysql_fetch_assoc($q)) {
?>
    <tr><td><?php echo $row['name']; ?></td><td><?php echo $row['count']; ?></td><tr>
<?php
    }
?>
</table></p>
<?php
    $q = @mysql_query("SELECT `name`, `count` FROM `amsn_screenshots`, `amsn_files` WHERE `amsn_screenshots`.`screen_id` = `amsn_files`.`id` ORDER BY `count` DESC, `name`;");
?>
<p><strong>Screenshots statistics</strong>
<table>
    <tr><th>Name</th><th>Count</th></tr>
<?php
    while ($row = mysql_fetch_assoc($q)) {
?>
    <tr><td><?php echo $row['name']; ?></td><td><?php echo $row['count']; ?></td><tr>
<?php
    }
?>
</table></p>
<?php

} elseif ($_GET['action'] == 'clean') {
    $q = @mysql_query("SELECT * FROM `amsn_files` ORDER BY `filename`, `url`");
    while ($row = mysql_fetch_assoc($q)) {
        $count = 0;
        $count = $count + mysql_num_rows(@mysql_query("SELECT id FROM `amsn_skins` WHERE screen_id={$row['id']} OR file_id={$row['id']};"));
        $count = $count + mysql_num_rows(@mysql_query("SELECT id FROM `amsn_plugins` WHERE screen_id={$row['id']} OR file_id={$row['id']};"));
        $count = $count + mysql_num_rows(@mysql_query("SELECT id FROM `amsn_screenshots` WHERE screen_id={$row['id']};"));
        if ($count == 0) {
            if ($row['filename'] != '' ) {
                unlink(getFilePath($row['filename']));
            }
            echo "<p>Removing the file ".getFileName($row['id'])." from the database</p>\n";
            if (!mysql_query("DELETE FROM `amsn_files` WHERE id = '" . $row['id'] . "' LIMIT 1")) {
                echo "<p>There was an error when trying to remove the file ".getFileName($row['id'])." from the database</p>\n";
            }
        }
    }
} elseif ($_GET['action'] == 'edit') {
    if (!mysql_num_rows(($q = mysql_query("SELECT * FROM `amsn_files` ORDER BY `filename`, `url`")))) {
        echo "<p>There are no files yet</p>\n";
        return;
    }

    if (isset($_POST['id']) && ereg('^[1-9][0-9]*$', $_POST['id']) && !mysql_num_rows(($q = @mysql_query("SELECT * FROM `amsn_files` WHERE id = '" . (int)$_POST['id'] . "' LIMIT 1")))) {
        echo "<p>The selected item don't exists</p>\n";
        return;
    }

    if ($_GET['action'] == 'edit' && isset($_POST['id'])) {
        if (isset($_POST['id'], $_POST['type'])) {
            $_POST = clean4sql($_POST);
            if ( $_POST['type'] === 'upload' ) {
                $result = treatUploadForm();
            } else {
                if (isset($_POST['upload_file']) && $_POST['upload_file'] == 'yes') {
                    $result = treatURLUploadForm();
                } else {
                    $result = treatURLForm();
                }
            }
            if ( !array_key_exists('error',$result) ) {
                echo "<p>{$result['success']}</p>\n";
                return;
            } else {
                echo "<p>{$result['error']}</p>\n";
            }
        }

        $row = mysql_fetch_assoc($q);
        form(htmlentities(stripslashes($row['url'])), htmlentities(stripslashes($row['filename'])), $row['id']);
        return;
    }
?>
<form action="<?php echo htmlentities($_SERVER['REQUEST_URI']) ?>" method="post" id="form">
    <label for="id">File:</label><select name="id" id="id">
<?php
while ($row = mysql_fetch_assoc($q)) {
    if ($row['filename'] != '') {
        $name = $row['filename'];
    } else {
        $name = $row['url'];
    }
?>
        <option value="<?php echo $row['id'] ?>"><?php echo htmlentities(stripslashes($name)) ?></option>
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