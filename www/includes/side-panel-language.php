<div class="block_right">
<h3><?php echo trans('language') ?></h3>
<div class="block_right_top"></div>
<div class="block_right_content block_language">
<?php
$query="SELECT DISTINCT lang_code FROM amsn_langs;";
$result=mysql_query($query) or die(mysql_error());
$flag=0;
while($row=mysql_fetch_array($result)) {
  /* Does flag for language exist? Hide if not as there is no pic */
  if(is_readable('images/flags/'.$row['lang_code'].'.png')) {
    echo '<a href="?lang='.$row['lang_code'].'"><img src="images/flags/'.$row['lang_code'].'.png" alt="'.$row['lang_code'].'" /></a> ';
    $flag++;
    if($flag>5) {
      echo '<br/>';
    }
  }
}
?>
</div>
<div class="block_right_bottom"></div>
</div>