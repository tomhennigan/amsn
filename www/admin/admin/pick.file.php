<?php
require_once '../../common.php';
session_start();

header("Cache-control: private");

require_once 'lib.user.php';
require_once 'lib.misc.php';

function renderFileList()
{
	if (!($result = mysql_query("SELECT * FROM `amsn_files` ORDER BY LOWER(filename), LOWER(url);"))) {
		echo "<p>An error ocurred</p>\n" . mysql_error();
	} else {
		$href = $_SERVER['PHP_SELF'] . '?field='.$_GET['field'].'&file_id=new';
?>
    <b style="text-align: center;display:block">Pick a file</b>
    <table>
        <tr><td>
            <a name="f-1"  href="#" onclick="javascript:applyFile(-1,'No file')">No file</a>
        </td></tr>
        <tr><td><a href="<?php echo $href; ?>">New file</a></td></tr>
<?php
		while ($row = mysql_fetch_assoc($result)) {
			if ($row['filename'] != '') {
				$name = $row['filename'];
			} else {
				$name = $row['url'];
			}
?>
        <tr><td>
            <a name="f<?php echo $row['id']; ?>"  href="#" onclick="javascript:applyFile(<?php echo $row['id']; ?>,'<?php echo $name; ?>')"><?php echo $name; ?></a>
        </td></tr>
<?php
		}
?>
    </table>
<?php
	}
}

function renderUploadForm($prefix)
{
?>
<form action="<?php echo htmlentities($_SERVER['REQUEST_URI']) ?>" method="post" enctype="multipart/form-data">
    <label for="screen">File to upload:</label><input type="file" id="<?php echo $prefix; ?>file" name="<?php echo $prefix; ?>file" /><br />
    <input type="hidden" name="<?php echo $prefix; ?>type" value="upload"/>
    <input type="submit" />
</form>
<?php
}

function renderURLForm($prefix)
{
?>
<form action="<?php echo htmlentities($_SERVER['REQUEST_URI']); ?>" method="post">
    <label for="screen">URL:</label>
    <input type="text" id="<?php echo $prefix; ?>url" name="<?php echo $prefix; ?>url" size=50/><br />
    <input type="button" onclick="document.getElementById('<?php echo $prefix; ?>url').value = 'http://prdownloads.sourceforge.net/amsn/';" value="File on FRS" />
    <input type="button" onclick="document.getElementById('<?php echo $prefix; ?>url').value = 'http://amsn.sourceforge.net/wiki/show_image.php?id=';" value="Image on Wiki" />
    <input type="checkbox" name="<?php echo $prefix; ?>upload_file" value="yes">Upload file</input><br />
    <input type="hidden" name="<?php echo $prefix; ?>type" value="url"/>
    <input type="submit" />
</form>
<?php
}

function treatUploadForm($prefix)
{
	$field_name = $prefix.'file';
	if (isset($_FILES[$field_name]['name']) && is_uploaded_file($_FILES[$field_name]['tmp_name'])) {
		$_POST = clean4sql($_POST);
		if (move_uploaded_file($_FILES[$field_name]['tmp_name'], getFilePath($_FILES[$field_name]['name']))) {
			if (!mysql_num_rows($q = mysql_query("SELECT id FROM `amsn_files` WHERE `filename` = '".$_FILES[$field_name]['name']."';"))) {
				if (mysql_query("INSERT INTO `amsn_files` (filename) VALUES ('".$_FILES[$field_name]['name']."');"))
				{
					return array( 'id' => mysql_insert_id(), 'name' => $_FILES[$field_name]['name'] );
				} else {
					unlink(getFilePath($_FILES[$field_name]['name']));
					return array( 'error' => mysql_error() );
				}
			} else {
				$row = mysql_fetch_assoc($q);
				return array( 'id' => $row['id'], 'name' => $_FILES[$field_name]['name'] );
			}
		} else {
			return array( 'error' => "Move file error" );
		}
	}
}

function treatURLForm($prefix)
{
	$field_name = $prefix.'url';
	if (isset($_POST[$field_name])) {
		$_POST = clean4sql($_POST);
		if (!mysql_num_rows($q = mysql_query("SELECT id  FROM `amsn_files` WHERE LOWER(`url`) = LOWER('".$_POST[$field_name]."');"))) {
			if (mysql_query("INSERT INTO `amsn_files` (url) VALUES ('".$_POST[$field_name]."');")) {
				return array( 'id' => mysql_insert_id(), 'name' => $_POST[$field_name] );
			} else {
				return array( 'error' => mysql_error() );
			}
		} else {
			$row = mysql_fetch_assoc($q);
			return array( 'id' => $row['id'], 'name' => $_POST[$field_name] );
		}
	}
}

function treatURLUploadForm($prefix)
{
	$field_name = $prefix.'url';
	if (isset($_POST[$field_name])) {
// Here we get the file name
		$filename = $_POST[$field_name];

		$ch = curl_init($_POST[$field_name]);

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
		if (copy($_POST[$field_name], getFilePath($filename))) {
			if (!mysql_num_rows($q = mysql_query("SELECT id FROM `amsn_files` WHERE `filename` = '".$filename."';"))) {
				if (mysql_query("INSERT INTO `amsn_files` (filename) VALUES ('".$filename."');"))
				{
					return array( 'id' => mysql_insert_id(), 'name' => $filename );
				} else {
					unlink(getFilePath($filename));
					return array( 'error' => mysql_error() );
				}
			} else {
				$row = mysql_fetch_assoc($q);
				return array( 'id' => $row['id'], 'name' => $filename );
			}
		} else {
			return array( 'error' => "Copy file error" );
		}
	}
}
?>
<html>
<head>
<title>Pick a file</title>
</head>
<?php
if (isset($_GET['field'])) {
?>
<script language="javascript"><!--
    function applyFile(id,name)
    {
        var field = window.parent.document.getElementById("<?php echo $_GET['field']; ?>");
        field.value = id;
        var field = window.parent.document.getElementById("<?php echo $_GET['field']; ?>_disp");
        field.value = name;
        window.parent.switchVisibility("<?php echo $_GET['field']; ?>",0);
    }
    //-->
</script>
<?php
}
?>
<body>
<?php
if (!user_level()) {
	noperms();
	exit;
}

if (!isset($_GET['field'])) {
?>
<b style="text-align: center;display:block">No parent information defined</b>
<?php
} else {
	if (isset($_GET['file_id']) && $_GET['file_id'] === 'new') {
		if (!isset($_POST['type']) || (strcmp($_POST['type'],'upload') && strcmp($_POST['type'], 'url'))) {
			renderUploadForm('');
			renderURLForm('');
		} else {
			if ( $_POST['type'] === 'upload' ) {
				$result = treatUploadForm('');
			} else {
				if (isset($_POST['upload_file']) && $_POST['upload_file'] == 'yes') {
					$result = treatURLUploadForm('');
				} else {
					$result = treatURLForm('');
				}
			}
			if ( !array_key_exists('error',$result) ) {
?>
<script language="javascript"><!--
    applyFile(<?php echo $result['id']; ?>,"<?php echo $result['name']; ?>");
    //-->
</script>
<?php
			} else {
?>
<b style="text-align: center;display:block"><?php echo $result['error']; ?></b>
<?php
			}
		}
	} else {
		renderFileList();
	}
}
?>
</body>
</html>
<?php
?>