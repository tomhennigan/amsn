<?php

$men_query = @mysql_query("SELECT men_id, men_url FROM amsn_menu ORDER BY men_pos") or die(mysql_error());

if (mysql_num_rows($men_query)) {
    echo "    <div id=\"nav\">\n";
    while ($men_assoc = mysql_fetch_assoc($men_query))
        echo "        <a href=\"{$men_assoc['men_url']}\" class=\"nav" , ($_GET['section'] == $men_assoc['men_id'] ? '_on' : '') , "\">{$men_assoc['men_id']}</a>\n";
    echo "    </div>\n";
}

?>