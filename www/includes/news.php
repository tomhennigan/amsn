<?php

$query = @mysql_query("SELECT title, text, time FROM `amsn_news` ORDER BY id DESC LIMIT 3") or print(mysql_error());

if (mysql_num_rows($query)) {
    while ($row = mysql_fetch_assoc($query)) {
      echo '<div class="news">';
      echo '<h3>'.trans($row['title']).'<br />'.date('F j, Y @ H:i:s', $row['time']).'</h3>';
      echo '<div class="news_top"></div>';
      echo '<div class="news_content">'.trans($row['text']).'</div>';
      echo '<div class="news_bottom"></div>';
      echo '</div>';
    }
}
?>
