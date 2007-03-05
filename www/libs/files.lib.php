<?php
function getFilePath($file)
{
	$lib = dirname(__FILE__);
	$files = realpath($lib . '/../files/');
	
	return $files . DIRECTORY_SEPARATOR . basename($file);
}

function getFileName($id)
{
	if ( $id == -1) {
		return "No file";
	}
	if (@mysql_num_rows(($result = @mysql_query("SELECT * FROM `amsn_files` WHERE id=".$id.";"))) != 1) {
		return "Invalid file";
	} else {
		$row = mysql_fetch_assoc($result);
		if ($row['filename'] !== '') {
			return $row['filename'];
		} else {
			return $row['url'];
		}
	}
}

function getFileSysName($id)
{
	if ( $id == -1) {
		return "";
	}
	if (mysql_num_rows(($result = mysql_query("SELECT * FROM `amsn_files` WHERE id=".$id.";"))) != 1) {
		return "";
	} else {
		$row = mysql_fetch_assoc($result);
		if ($row['filename'] !== '') {
			return getFilePath($row['filename']);
		} else {
			return $row['url'];
		}
	}
}

function getFileURL($id)
{
	if ( $id == -1) {
		return "";
	}
	if (mysql_num_rows(($result = mysql_query("SELECT * FROM `amsn_files` WHERE id=".$id.";"))) != 1) {
		return "";
	} else {
		$row = mysql_fetch_assoc($result);
		if ($row['filename'] !== '') {
			return dirname($_SERVER['PHP_SELF']) . '/files/' . $row['filename'];
		} else {
			return $row['url'];
		}
	}
}

function getFileCount($id)
{
	if ( $id == -1) {
		return "";
	}
	if (mysql_num_rows(($result = mysql_query("SELECT `count` FROM `amsn_files` WHERE id=".$id.";"))) != 1) {
		return "";
	} else {
		$row = mysql_fetch_assoc($result);
		return $row['count'];
	}
}

function getFileID($id)
{
	if (@mysql_num_rows(@mysql_query("SELECT * FROM `amsn_files` WHERE id=".$id.";")) != 1) {
		return -1;
	} else {
		return $id;
	}
}
?>