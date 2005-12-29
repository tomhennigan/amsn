<?php

function cf($file)
{
    /*
    * This function checks if a file can be called with include
    * Returns a boolean value (true if can be included or false in other case)
    */
    return (@file_exists($file) && is_readable($file));
}

function noperms()
{
    echo "<p>You don't have permission to do the requested action, please contact to an administrator if you think that this is incorrect.</p>\n";
}

function RandomString($length = 7)
{
    $chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNPQRSTUVWXYZ0123456789';

    for ($string = ''; strlen($string) < $length;)
        $string .= $chars{rand(0, strlen($chars) - 1)};

    return $string;
}

function canModerateNews()
//Assumption: only level 0 and level 1 user can moderate (i.e.:add, delete and edit) news.
{
	if (isLoggedIn()==true)
	{
		if ($_SESSION['level'] == 1 || $_SESSION['level'] == 1)
			return true;
	}
	return false;
}

/**
 * Allow these tags
 */
$allowedTags = '<h1><b><i><a><ul><li><pre><hr><blockquote><img><u><br />';

/**
 * Disallow these attributes/prefix within a tag
 */
$stripAttrib = 'javascript:|onclick|ondblclick|onmousedown|onmouseup|onmouseover|'.
               'onmousemove|onmouseout|onkeypress|onkeydown|onkeyup|onload';



function removeEvilAttributes($tagSource)
{
   global $stripAttrib;
   return stripslashes(preg_replace("/$stripAttrib/i", 'forbidden', $tagSource));
}

/**
 * @return string
 * @param string
 * @desc Strip forbidden tags and delegate tag-source check to removeEvilAttributes()
 */
function removeEvilTags($source)
{
   global $allowedTags;
   $source = strip_tags($source, $allowedTags);
   return addslashes(preg_replace('/<(.*?)>/ie', "'<'.removeEvilAttributes('\\1').'>'", $source));
}

function clean_empty_keys(&$array)
{
	/*
	* This function removes the empty keys of an array
	* Returns the key-cleaned array on success, or false in other case
	*/

	foreach ((array)$array as $k => $v)
		if (empty($v))
			unset($array[$k]);
}

function clean4sql($var)
{
    if (!is_array($var) && is_string($var))
        $var = (array)$var;

    foreach ($var as $k => $v)
        $var[$k] = is_array($v) ? clean4sql($v) : mysql_escape_string(stripslashes(trim($v)));

    return $var;
}

?>