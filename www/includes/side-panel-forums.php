<div>
<?php echo '<h3 class="forums">'.FORUMS_SIDE.'</h3>'; ?>

<div class="block_right_top"></div>
<div class="block_right_content block_forums">
<?php
echo '<b><a href="/forums/">'.AMSN_FORUMS.'</a></b><br/>';
echo '<br/>';
/*echo '&#8226; '.RECENT_POSTS.' &#8226;'; */
?>
<?php
//catch so it works when the forum db is not awailible (ei: when developing offline)
if(@mysql_select_db(DBNAME_FORUM)) {
  // For PhpBB
  /*$search = "SELECT phpbb_posts.topic_id,phpbb_topics.topic_title FROM phpbb_posts,phpbb_topics WHERE phpbb_topics.topic_id=phpbb_posts.topic_id ORDER BY phpbb_posts.post_time DESC LIMIT 7;";
  $result=mysql_query($search) or die(mysql_error());
  while($row=mysql_fetch_array($result)) {
    echo '<li><a href="forums/viewtopic.php?t='.$row['topic_id'].'">'.htmlentities($row['topic_title']).'</a></li>';
  }*/

  // For SMF
  /*$search = "SELECT `subject`, `ID_TOPIC`, `ID_MSG` FROM `smf_messages` GROUP BY `ID_TOPIC` ORDER BY MAX(`ID_MSG`) DESC LIMIT 7;";
  $result=mysql_query($search) or die(mysql_error());
  while($row=mysql_fetch_array($result)) {
    echo '<li><a href="forums/index.php/topic,'.$row['ID_TOPIC'].'.msg'.$row['ID_MSG'].'.html#msg'.$row['ID_MSG'].'">'.$row['subject'].'</a></li>';
  }*/

  mysql_select_db(DBNAME_WWW);
}
?>

</div>
<div class="block_right_bottom"></div>
</div>
