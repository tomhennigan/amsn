<?php

$query = @mysql_query("SELECT title, text, time FROM `amsn_news` ORDER BY id DESC LIMIT 3") or print(mysql_error());

if (mysql_num_rows($query)) {
    while ($row = mysql_fetch_assoc($query)) {
        //echo '<pre>'; print_r($row); echo '</pre>';
?>
          <div class="news">
            <h3><?php echo $row['title'] ?><br /><?php echo date('F j, Y @ H:i:s', $row['time']) ?></h3>
            <div class="news_top"></div>

            <div class="news_content"><?php echo $row['text'] ?></div>
            <div class="news_bottom"></div>
          </div>
<?php    
    }
}

?>
