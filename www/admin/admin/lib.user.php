<?php

/*
 * That's intended to be a simple group of functions to manage user logins, etc.
 *
 * I assume that we are connected to the database (I don't make any new connection here)
 *
 * The following levels are required to:
 *     - Create new user: 5
 *     - Delete user: 5
 *     - Edit user: Must be the same user OR have level 5
 */

function user_login($user, $pass)
{
    /*
    * This function returns an integer containing the level of the user, or 0 if don't match
    * The session is started and the following superglobal variables defined
    *     - $_SESSION['user'] with the username
    *     - $_SESSION['leve'] with the level
    */
    if ((!is_string($user) || empty($user)) || (!is_string($pass) || empty($pass)))
        return false;

    $q = @mysql_query("SELECT `level`, `id` FROM `amsn_users` WHERE `user` = '" . mysql_real_escape_string($user) . "' AND `pass` = '" . sha1($pass) . "' LIMIT 1");
    if (0 === ($level = (int)@mysql_result($q, 0, 'level')))
        return false;

    if (!isset($_SESSION) || !session_id())
        if (headers_sent())
            return false;

        else 
            session_start();

    $_SESSION['user'] = $user;
    $_SESSION['id']   = (int)mysql_result($q, 0, 'id');

    return ($_SESSION['level'] = $level);
}

function user_new($user, $mail, $level)
{
    /*
    * Max length of the fields in the database can't be exceeded and the level must be numeric:
    *    - User: 20 characters
    *    - Mail: 50 characters
    * The password is always a 40-characters hash (SHA1), it's automatically hashed
    * The mail syntax and his DNS server are checked to avoid false mails on the database
    * If the user or e-mail exists in the database the function returns false to avoid duplicate rows
    */

    if (!user_level(5) || (!isset($user, $mail, $level)) || (!is_string($user) || empty($user) || isset($user{10})) || (!is_string($mail) || empty($mail) || isset($mail{50})) || !ereg('^[1-5]$', $level)) {
	echo "amsd";
        return false;
	}

    else if (!user_mail($mail)) {
	echo "mah";
        return false;
	}

    $pass = RandomString();
    if (!@mysql_num_rows(mysql_query("SELECT `id` FROM `amsn_users` WHERE `user` = '" . mysql_real_escape_string($user) . "' LIMIT 1"))) {
        if (@mysql_query("INSERT INTO `amsn_users` (user, pass, email, level) VALUES ('" . mysql_real_escape_string($user) . "', '" . sha1($pass) . "', '" . mysql_real_escape_string($mail) . "', '" . (int)$level . "')")) {
            if (!mail($mail, "aMSN Web administration", "You are now a part of the aMSN webpage administration, welcome!\nYour username and password are the following:\n\n - User: $user\n - Password: $pass\n\nYou can change the password anytime you want in your control panel", "From: aMSN Admin <admin@amsn.sf.net>")) {
                mysql_query("DELETE FROM `amsn_users` WHERE id = '" . mysql_insert_id() . "' LIMIT 1");
	echo "dude";
                return false;
            } else
                return true;
	} else {
		echo mysql_error();
		echo "insert problem";
		return false;
	}
    } else 
        return false;

}

function user_remove($user_id)
{
    /*
    * This function returns a boolean value
    * If the user is successfully deleted returns true, in other case return false
    */
    if (!isset($user_id) || user_level(5))
        return false;

    return mysql_query("DELETE FROM `amsn_users` WHERE `id` = '" . (int)$user_id . "' LIMIT 1");
}

function user_edit($user, $email, $level = null, $oldpass = null, $newpass = null)
{
    if (!isset($user, $email, $_SESSION['user'], $_SESSION['level']) || ($_SESSION['user'] != $user && $_SESSION['level'] < 5) || false === ($row = @mysql_fetch_assoc(mysql_query("SELECT `user`, `pass`, `email`, `level` FROM `amsn_users` WHERE `user` = '" . mysql_real_escape_string($user) . "' LIMIT 1"))))
        return false;

    $query = "UPDATE `amsn_users` SET";
    $param = array();
    $send_email = false;

    if ($email != $row['email'] && !user_mail($email))
        return false;

    else
        $param[] = " `email` = '" . mysql_real_escape_string($email) . "'";

    if (isset($level) && !empty($level)) {
        if (!ereg('^[1-5]$', $level))
            return false;

        if ((int)$level != (int)$row['level'])
            $param[] = "`level` = '" . (int)$level . "'";
    }

    if (isset($oldpass, $newpass) && !empty($oldpass) && !empty($newpass)) {
        if (sha1($oldpass) != $row['pass'])
            return false;

        if ($row['pass'] != ($sha1 = sha1($newpass)))  {
            $param[] = " `pass` = '{$sha1}'";
            $send_email = true;
        }
    }

    if (@mysql_query("$query " . implode(' ,', $param) . " WHERE `user` = '" . mysql_real_escape_string($user) ."' LIMIT 1") && $send_email)
        if (!@mail($email, 'aMSN administration', 'Your password for aMSN control panel has been changed (' . ($_SESSION['user'] == $row['user'] ? 'by your request' : "requested by the administrator \"{$_SESSION['user']}\"") . "). You can login with this new data:\n\nUser: {$row['user']}\nPassword: {$newpass}\n\nf you don't know anything about what this e-mail contains you can delete it safelly. Sorry for the inconvenience.\n\nRegards, the aMSN webpage team", "From: aMSN webpage administrator <web@amsn.sf.net>\n"))
            return false;

    return true;
}

function user_mail($mail)
{
    if (!preg_match("!^[a-z0-9\.+-_]+@([a-z0-9-]+(?:\.[a-z0-9-]+)+)$!i", $mail, $grab) && !checkdnsrr(@$grab[1]))
        return false;

    return true;    
}

function user_level($level = null)
{
    /*
    * This function returns true if the user is logged in and the level is between 1 and 5
    * Can be called with or without parameters
    * If the first (and unique) parameter is set adxitionally the level is checked
    * Returns true if all is valid, or false in other case
    */

    static $check = false;

	$check = isset($_SESSION['user'], $_SESSION['level']);

    if (!$check)
        return false;

    //The level must be in the range "1, 5"
    if (isset($level))
        return (ereg('[1-5]', $level) && $_SESSION['level'] >= $level);

    if ($_SESSION['user'] < 6 && $_SESSION['level'] > 0)
	    return true;

	return false;

}

?>
