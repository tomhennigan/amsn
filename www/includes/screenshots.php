<?php

if (!mysql_num_rows(($q = mysql_query("SELECT `id`, `name`, `desc`, `screen` FROM `amsn_screenshots` ORDER BY `name`")))) {
    echo "<p>There are no screenshots available.</p>\n";
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
	echo '   <li><a href="screenshots.php?screen=' . $row['id'] . '">' . $row['name']  . "</a></li>\n";
}
echo "</ul>\n";

if (!isset($actual)) {
    echo "<p>The selected screenshot does not exist. It may have been removed.</p>\n";
} else {
    echo '<p id="desc">' . $actual['desc'] . '</p>';
    echo '<a href="'.$actual['screen'].'"><img src="'.$actual['screen'] .'&amp;thumb=1" alt="' . htmlentities(stripslashes($actual['name'])) . '" class="screenshot" /></a>';
#	echo '<img src="screenshots/screen_' . basename($actual['screen']) . '" id="screenshot_img" alt="' . htmlentities(stripslashes($actual['name'])) . '" class="screenshot"/>';
}

?>
