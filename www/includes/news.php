<?php
date_default_timezone_set('UTC');
$title_news='title'.$lang_set;
$text_news='text'.$lang_set;
$query = @mysql_query("SELECT $title_news, $text_news, time FROM `amsn_news` ORDER BY id DESC LIMIT 3") or print(mysql_error());

if (mysql_num_rows($query)) {
    while ($row = mysql_fetch_assoc($query)) {
      echo '<div class="news">';
      //echo '<h3>'.trans($row['title']).'<br />'.date('F j, Y @ H:i:s', $row['time']).'</h3>';
      echo '<h3>'.$row[$title_news].'<br />'.strftime('%B %e,  %Y @ %H:%M:%S', $row['time']).'</h3>'; 
	  echo '<div class="news_top"></div>';
      echo '<div class="news_content">'.$row[$text_news].'</div>';
      echo '<div class="news_bottom"></div>';
      echo '</div>';
    }
}
?>
