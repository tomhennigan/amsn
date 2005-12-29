<?php
require_once '../common.php';
session_start();
header("Cache-control: private");

//$_SESSION = array();

define('CPanel', true);
require_once 'admin/lib.user.php';
require_once 'admin/lib.misc.php';

if (!user_level()) {
?>
<form action="login.php" method="post">
    <label for="user">User:</label><input type="text" name="user" id="user" maxlength="20" />
    <label for="pass">Password:</label><input type="password" id="pass" name="pass" />
    <input type="submit" />
</form>
<?php
} else {
    echo "<p>Welcome to the control panel, <strong>{$_SESSION['user']}</strong>. You have the power ;)</p>\n<p>Your level is {$_SESSION['level']}</p>\n";
?>
<ul>
    <li>News<ul>
        <li><a href="index.php?load=news&amp;action=add">Write a post</a></li>
<?php if (user_level(2)) { ?>
        <li><a href="index.php?load=news&amp;action=edit">Edit a post</a></li>
<?php } if (user_level(3)) { ?>
        <li><a href="index.php?load=news&amp;action=remove">Delete a post</a></li>
<?php } ?>
    </ul></li>
    <li>Users<ul>
<?php if (user_level(5)) { ?>
        <li><a href="index.php?load=users&amp;action=add">Add users</a></li>
        <li><a href="index.php?load=users&amp;action=remove">Remove users</a></li>
<?php } ?>
        <li><a href="index.php?load=users&amp;action=edit">Edit users</a></li>
    </ul></li>
<?php if (user_level(5)) { ?>
    <li>Menu<ul>
        <li><a href="index.php?load=menu&amp;action=add">Add button</a></li>
        <li><a href="index.php?load=menu&amp;action=edit">Edit button</a></li>
        <li><a href="index.php?load=menu&amp;action=remove">Remove button</a></li>
    </ul></li>
<?php } if (user_level(3)) { ?>
    <li>Polls<ul>
        <li><a href="index.php?load=poll&amp;action=add">New poll</a></li>
<?php if (user_level(4)) { ?>
        <li><a href="index.php?load=poll&amp;action=remove">Remove poll</a></li>
<?php } ?>
    </ul></li>
<?php } if (user_level(3)) { ?>
    <li>Screenshots<ul>
        <li><a href="index.php?load=screenshots&amp;action=add">New screenshot</a></li>
    </ul></li>
<?php } ?>
    <li><a href="logout.php">Logout</a></li>
</ul>
<?php

    if (!isset($_GET['load'])) $_GET['load'] = '';
    if (!isset($_GET['action'])) $_GET['action'] = '';

    if (cf(($file = 'admin/amsn.' . basename(strtolower($_GET['load'])) . '.php')))
        include_once $file;
    else
        echo "<p>Please, select an option from the menu</p>\n";
}

//echo '<pre>'; print_r($_SESSION); print_r($_POST); print_r($_GET); print_r($_FILES); echo '</pre>';

?>
