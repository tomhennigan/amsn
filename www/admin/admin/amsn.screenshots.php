<?php

if (!defined('CPanel') || !isset($_SESSION['user'], $_SESSION['level'], $_GET['load'])) {
    require_once 'lib.misc.php';
    noperms();
    exit;
}

if (!user_level(3)) {
    noperms();
    return;
}

if (isset($_POST['name'], $_POST['desc'], $_FILES['image']['name']) && is_uploaded_file($_FILES['image']['tmp_name'])) {
    $_POST = clean4sql($_POST);
    if (move_uploaded_file($_FILES['image']['tmp_name'], '/tmp/persistent/amsn/www/screenshots/screen_' . $_FILES['image']['name']) && mysql_query("INSERT INTO `amsn_screenshots` (name, `desc`, screen) VALUES ('{$_POST['name']}', '{$_POST['desc']}', '" . mysql_escape_string('screenshots/screen_' . $_FILES['image']['name']) . "')")) {
        echo "<p>Screenshot successfully added</p>\n";
        return;
    } else {
        echo "<p>An error ocurred</p>\n" . mysql_error();
        return;
    }
}

?>

<form action="<?php echo htmlentities($_SERVER['REQUEST_URI']) ?>" method="post" enctype="multipart/form-data">
    <label for="name">Name:</label><input type="text" maxlength="100" name="name" id="name" /><br />
    <label for="desc">Description:</label><input type="text" maxlength="255" name="desc" id="desc" /><br />
    <label for="screen">Image:</label><input type="file" id="image" name="image" /><br />
    <input type="submit" />
</form>
<?php

?>
