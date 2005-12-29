<?
/*
  $Id$

  eTest Student Testing - Package 
  Copyright (c) 2003 eTest
  Released under the GNU General Public License

 * --------------------------------------------------------------------------
 * phpSecureSessions.inc.php
 * --------------------------------------------------------------------------
 * phpSecureSessions
 * Version 1.0.2
 * Last Modified: 28 Apr 2003
 *
 * Copyright (C) 2003  Laurent DINCLAUX (haj_at_KeasyPHP.org)
 *
 *   This program is free software; you can redistribute it and/or modify
 *   it under the terms of the GNU General Public License as published by
 *   the Free Software Foundation; either version 2 of the License, or
 *   (at your option) any later version.
 *
 *   This program is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details.
 *
 *   You should have received a copy of the GNU General Public License
 *   along with this program; if not, write to the Free Software
 *   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
 *
 * --------------------------------------------------------------------------
 * DESCRIPTION:
 * --------------------------------------------------------------------------
 * This library is a PHP4/MySQL Secure Session Handler
 * It tells the PHP4 session handler to write to a MySQL database
 * instead of creating individual files for each session.
 *
 * phpSecureSessions is secure as it can do a check against ip. This avoid a
 * hacking of the cookie containing session_id if it is intercept and used
 * on an other computer. phpSecureSessions retrives client ip and controls
 * that it doesn't change.
 *
 * phpSecureSessions also has default value to override session.use_trans_sid
 * so it disable it as it is not secure at all.
 *
 * --------------------------------------------------------------------------
 * INSTALLATION:
 * --------------------------------------------------------------------------
 * Create a new database in MySQL called "sessions" like so:
 *
 * CREATE TABLE $_sess_tblPrefix_sessions (
    session_id varchar(32) NOT NULL default '',
    session_created int(11) NOT NULL default '0',
    session_active int(11) NOT NULL default '0',
    session_counter int(11) NOT NULL default '0',
    session_remote_address varchar(128) NOT NULL default '',
    session_data longtext NOT NULL
  ) TYPE=MyISAM;
 *
 * Then call sess_init($DB_host, $DB_base, $DB_user, $DB_password,$_sess_tblPrefix) to open
 * session note that this function has many other arguments that are used to
 * override php.ini session_setting they have default value so check them
 * at the end of the script and the php documentation for explanations
 * http://www.php.net/manual/en/ref.session.php
 */

$_sqlLink = '';
$_sess_data_max = '';
$_sess_ip_check = true;
$_sess_tblPrefix = 'etest';
$_sess_property= '';

/**
 *This function retrive the more detailed info possible on client IP adress
 */
function get_full_ip(){
    // get client real ip
    if ( isset($_SERVER['HTTP_X_FORWARDED_FOR']) ):
        $IP_ADDR = $_SERVER['HTTP_X_FORWARDED_FOR'] ;
    elseif( isset($_SERVER['HTTP_CLIENT_IP']) ):
        $IP_ADDR =  $_SERVER['HTTP_CLIENT_IP'] ;
    else:
        $IP_ADDR = $_SERVER['REMOTE_ADDR'];
    endif;

    // get server ip and resolved it
    $FIRE_IP_ADDR = $_SERVER['REMOTE_ADDR'];
    $ip_resolved = gethostbyaddr($FIRE_IP_ADDR);

    // builds server ip infos string
    if ($FIRE_IP_ADDR != $ip_resolved && $ip_resolved):
        $FIRE_IP_LITT = $FIRE_IP_ADDR." - ". $ip_resolved;
    else:
        $FIRE_IP_LITT = $FIRE_IP_ADDR;
    endif;

    // builds client ip full infos string
    if ($IP_ADDR != $FIRE_IP_ADDR  ):
        $FULL_IP_INFOS = "$IP_ADDR | $FIRE_IP_LITT" ;
    else:
        $FULL_IP_INFOS = $FIRE_IP_LITT ;
    endif;
    return $FULL_IP_INFOS;

}

/**
 *Called by session_start()
 *only opens a Mysql connection
 */
function sess_open($save_path, $_session_name) {
    global $DB_host, $DB_base, $DB_user, $DB_password, $_sqlLink;

    if (! $_sqlLink = mysql_connect($DB_host, $DB_user, $DB_password)) {
        trigger_error('sess_open(): Failed to connect to MySql - '. mysql_error($_sqlLink),E_USER_ERROR);
        return false;
    }
    if (! mysql_select_db($DB_base, $_sqlLink)) {
        trigger_error("sess_open(): Unable to select database $DB_base - ". mysql_error($_sqlLink),E_USER_ERROR);
        return false;
    }
    return true;
}

function sess_close() {
    return true;
}

/**
 *Reads session data in mySql
 *also do an ip check
 */
function sess_read($session_id) {
    global $_sqlLink, $_sess_property, $_sess_tblPrefix, $_sess_ip_check;

    //session_id check
    if (strlen($session_id) != 32) {
        trigger_error("sess_read(): Invalid SessionID = " . $session_id,E_USER_ERROR);
        return '';
    }

    $session_id = addslashes($session_id);
    $result = mysql_query("SELECT * FROM {$_sess_tblPrefix}_sessions WHERE session_id = '$session_id'",$_sqlLink);
    if (mysql_num_rows($result) == 1) {
        $_sess_property= mysql_fetch_assoc($result);
        return $_sess_property['session_data'];
        // ip check
        if(!$_sess_ip_check and $_sess_property){
            return $_sess_property['session_data'];
        }
        else if($_sess_property and $_sess_property['session_remote_address']==get_full_ip() and $_sess_ip_check){
            return $_sess_property['session_data'];
        }
        else{
           echo "<DIV align=center><font face=verdana size=1><b>Session Error</b><br>Your IP address has changed...<br>'".get_full_ip()."'<br>'{$_sess_property['session_remote_address']}'<br>Remember: hacking is not good for your health !</font></div>";
           session_destroy();
           exit;
           return '';
        }

    }
    elseif (mysql_errno($_sqlLink)) {
        trigger_error('sess_read(): Failed to read sessions - '. mysql_error($_sqlLink),E_USER_ERROR);
        return '';
    }
    else {
        $_sess_property = null; // For session_write()
        return '';
    }
}
/**
 *Write session data in mySql
 *also do an ip check
 */
function sess_write($session_id, $session_data) {
    global $_sqlLink, $_sess_property, $_sess_tblPrefix, $_sess_data_max, $_sess_ip_check;

    //session_id check
    if (strlen($session_id) != 32) {
        trigger_error('sess_write(): Invalid Session ID = '.$session_id,E_USER_ERROR);
        return false;
    }
    //session data max size check
    if ($_sess_data_max > 0 and strlen($session_data) > intval($_sess_data_max)) {
        trigger_error('sess_write(): Session data too large. '. $session_id, E_USER_ERROR);
    }
    // ip check
    if($_sess_property and $_sess_property['session_remote_address']!=get_full_ip() and $_sess_ip_check){
        echo get_full_ip()."<DIV align=center><font face=verdana size=1><b>Session Error</b><br>Your IP address has changed...<br>'".get_full_ip()."'<br>'{$_sess_property['session_remote_address']}'<br>Remember: hacking is not good for your health !</font></div>";
        session_destroy();
        exit;
        return '';
    }


    // escape session_data to be insert in Mysql
    if(version_compare(phpversion(), "4.3.0", "<")){
        $_sess_data = mysql_escape_string($session_data);
    }
    else{
        $_sess_data = mysql_real_escape_string($session_data,$_sqlLink);
    }
    //UPDATE/INSERT data
    if ($_sess_property) {
        $query = "UPDATE {$_sess_tblPrefix}_sessions SET session_active = ". time() .", session_counter = ". ++$_sess_property['session_counter'] .", session_data = '$_sess_data' WHERE session_id = '$session_id';";
    }
    else {
        $query = "INSERT INTO {$_sess_tblPrefix}_sessions (session_id, session_created, session_active, session_remote_address, session_data) VALUES ('$session_id', ". time() .", ". time() .", '". get_full_ip() ."', '$_sess_data');";
    }
    mysql_query($query, $_sqlLink);

    if (mysql_errno($_sqlLink)) {
        trigger_error('sess_write(): Failed to INSERT/UPDATE session. '.mysql_error($_sqlLink). "<br> Query: ".$query,E_USER_ERROR);
    }
    return true;
}
/**
 *detroys the session
 */
function sess_destroy($session_id) {
    global $_sqlLink, $_sess_tblPrefix;

    mysql_query("DELETE FROM {$_sess_tblPrefix}_sessions WHERE session_id = '". addslashes($session_id). "'",$_sqlLink);
    if (mysql_errno($_sqlLink)) {
        trigger_error('sess_destory(): Failed to DELETE session. '.mysql_error($_sqlLink),E_USER_ERROR);
        return false;
    }
    else {
        return true;
    }
}
/**
 *delete old sessions
 */
function sess_gc($_sess_gc_maxlifetime=720) {
   /**
    *you may want to uncomment this to test if garbage
    *collection get called properly
    */

    /* $fp =fopen('gc.txt',ab);
    fwrite ($fp,"gc\n"."DELETE FROM {$_sess_tblPrefix}_sessions WHERE session_active < ". (time() - $_sess_gc_maxlifetime));
    fclose($fp);
    */

    global $_sqlLink, $_sess_tblPrefix;
    mysql_query("DELETE FROM {$_sess_tblPrefix}_sessions WHERE session_active < ". (time() - $_sess_gc_maxlifetime));
    mysql_query("OPTIMIZE TABLE `{$_sess_tblPrefix}_sessions` ",$_sqlLink);
    if (mysql_errno($_sqlLink)) {
        trigger_error('sess_gc(): Failed to DELETE old sessions.'. mysql_error($_sqlLink),E_USER_WARNING);
        return false;
    }
    else {
        return true;
    }
}

/**
 *initaializing session function
 *call that to open session
 */
function sess_init($host, $base, $user, $password, $session_tblPrefix, //vars to connect to mysql
                   $session_ip_check = true, // do an ip check ?
                   $session_data_max = 0, // max lenght of session data (0 for unlimited)
                   $session_name="PHPSESSID",
                   $session_serialize_handler = 'php',
                   $session_gc_probability = 50,
                   $session_gc_maxlifetime = 1440,
                   $session_referer_check  ='',
                   $session_entropy_file = '',
                   $session_entropy_length = 0,
                   $session_use_cookies = 1,
                   $session_use_only_cookies = 1, // only available from php 4.3.0
                   $session_cookie_lifetime = 0,
                   $session_cookie_secure = false, // automaticly set if you use https connection but you can force it to true
                   $session_cookie_path = '/',
                   $session_cookie_domain = '',
                   $session_cache_limiter = 'nocache', // none, nocache, private, private_no_expire, public
                   $session_cache_expire = 180,
                   $session_use_trans_sid = 0,
                   $session_url_rewriter_tags = "a=href,area=href,frame=src,input=src,form=,fieldset=")
{
    global $DB_host, $DB_base, $DB_user, $DB_password, $_sess_tblPrefix, $_sess_ip_check, $_sess_data_max, $_sess_gc_maxlifetime;
	$DB_host=$host;
	$DB_base=$base;
	$DB_user=$user;
	$DB_password=$password;

    $_sess_data_max = $session_data_max;
    $_sess_ip_check = $session_ip_check;
    $_sess_tblPrefix = $session_tblPrefix;
    // have to or the staff won't work
    ini_set ( "session.save_handler", "user" );

    // set the cookie secure if HTTPS is on
    if( ( isset($_SERVER["HTTPS"]) && $_SERVER["HTTPS"] == "on" )  or $session_cookie_secure) $session_cookie_secure = true;

    session_name($session_name);

    ini_set ( "session.serialize_handler", $session_serialize_handler );
    ini_set ( "session.gc_probability", $session_gc_probability );
    ini_set ( "session.gc_maxlifetime", $session_gc_maxlifetime );
    ini_set ( "session.referer_check", $session_referer_check );
    ini_set ( "session.entropy_file", $session_entropy_file);
    ini_set ( "session.entropy_length", $session_entropy_length );
    ini_set ( "session.use_cookies", $session_use_cookies );
    ini_set ( "session.use_trans_sid", $session_use_trans_sid );
    ini_set ( "session.url_rewriter.tags ", $session_url_rewriter_tags );

    if(version_compare(phpversion(), "4.3.0", ">=")) ini_set ( "session.use_only_cookies", $session_use_only_cookies );
    if(version_compare(phpversion(), "4.2.0", ">=")) session_cache_expire ($session_cache_expire);

    session_set_cookie_params ( $session_cookie_lifetime,$session_cookie_path,$session_cookie_domain,$session_cookie_secure);
    session_cache_limiter($session_cache_limiter);

    $_sess_gc_maxlifetime = ini_get("session.gc_maxlifetime");

}


session_set_save_handler(
        "sess_open",
        "sess_close",
        "sess_read",
        "sess_write",
        "sess_destroy",
        "sess_gc");
?>
