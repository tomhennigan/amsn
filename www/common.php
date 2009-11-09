<?php
require_once 'config.inc.php';
require_once 'mysql_sessions.inc.php';
require_once 'libs/lang.lib.php';
require_once 'libs/mail.lib.php';
require_once 'libs/files.lib.php';
require_once 'libs/cookie.php';

define('inc', 'includes' . DIRECTORY_SEPARATOR);
$_GET['section'] = (isset($_GET['section']) && !empty($_GET['section'])) ? $_GET['section'] : 'home';
sess_init(DBHOST,DBNAME_WWW,DBUSER,DBPASS,'');
mysql_select_db(DBNAME_WWW, mysql_connect(DBHOST,DBUSER,DBPASS)) or die(mysql_error());

header('Content-type: text/html;charset=utf-8');

if (file_exists('includes/languages/'.$lang_set.'/'.$lang_set.'.php')) {
  include("includes/languages/".$lang_set."/".$lang_set.".php");  
}
// Include english after the language because we can't redefine constants, so all defines
// from english will fail apart from the ones that were defined in the language
include("includes/languages/en/en.php");  

?>
