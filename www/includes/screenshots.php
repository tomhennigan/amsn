<?php
if (!mysql_num_rows(($q = mysql_query("SELECT `id`, `name`, `desc`, `screen_id` FROM `amsn_screenshots` ORDER BY `order` DESC, `name` ASC")))) {
    echo '<p>'.NOSCREEN_SCREEN."</p>\n";
    return;
}

$actual = null;
echo '<ul id="screenshot_list">';
while ($row = mysql_fetch_assoc($q)) {
    if (!isset($_GET['screen'])) {
        if (!isset($actual))
            $actual = $row;
    } else if (($_GET['screen'] = (int)$_GET['screen']) == $row['id']) {
        $actual = $row;
    }

#    echo '   <li><a href="screenshots.php?screen=' . $row['id'] . '" onclick="changeScreenshot(\'' . $row['screen'] . '\', \'' . $row['desc'] . '\'); return false;">' . $row['name']  . "</a></li>\n";
    echo '   <li><a href="screenshots.php?screen=' . $row['id'] . '">' . trans($row['id'], 'screen_name', $row['name'])  . "</a></li>\n";
}
echo "</ul>\n";

if (!isset($actual)) {
    echo '<p>'.NOEXIST_SCREEN."</p>\n";
} else {
    echo '<p id="desc">' .trans($actual['id'], 'screen_desc', $actual['desc']). '</p>';
    echo '<a href="getURL.php?id='.$actual['screen_id'].'"><img src="thumb.php?id='.$actual['screen_id'] .'" alt="' . htmlentities(stripslashes($actual['name'])) . '" class="screenshot" /></a>';
#	echo '<img src="screenshots/screen_' . basename($actual['screen']) . '" id="screenshot_img" alt="' . htmlentities(stripslashes($actual['name'])) . '" class="screenshot"/>';
}

?>
