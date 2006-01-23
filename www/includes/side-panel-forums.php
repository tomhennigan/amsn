<div class="block_right">
<?php echo '<h3 class="forums">'.trans('forums').'</h3>'; ?>

<div class="block_right_top"></div>
<div class="block_right_content block_forums">
<?php
echo '<b><a href="http://amsn.sourceforge.net/forums/">'.trans('amsnforums').'</a></b><br/>';
echo '<b><a href="http://forums.cocoaforge.com/viewforum.php?f=14">'.trans('macforums').'</a></b><br/>';
echo '<br/>';
echo '&#8226; '.trans('recentposts').' &#8226;';
?>
<ul style="text-align: left;padding-left: 20px;margin-bottom: 0px">
<?php
//catch so it works when the forum db is not awailible (ei: when developing offline)
if(@mysql_select_db(DBNAME_FORUM)) {
  $result=mysql_query("SELECT phpbb_posts.topic_id,phpbb_topics.topic_title FROM phpbb_posts,phpbb_topics WHERE phpbb_topics.topic_id=phpbb_posts.topic_id ORDER BY phpbb_posts.post_time DESC LIMIT 7;") or die(mysql_error());
  while($row=mysql_fetch_array($result)) {
    echo '<li><a href="forums/viewtopic.php?t='.$row['topic_id'].'">'.$row['topic_title'].'</a></li>';
  }
  mysql_select_db(DBNAME_WWW);
}
?>
</ul>

</div>
<div class="block_right_bottom"></div>
</div>
