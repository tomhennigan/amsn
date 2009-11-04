<div>
<h3><?php echo LANGUAGE_SIDE; ?></h3>
<div class="block_right_top"></div>
<div class="block_right_content block_language">
<?php
$flag=0;
foreach (glob('includes/languages/*/*.php') as $filename) {
  $keywords = preg_split("/\//", $filename);
  $lang = $keywords[2];

  /* Does flag for language exist? Hide if not as there is no pic */
  if(is_readable('images/flags/'.$lang.'.png')) {
    echo '<a href="?lang='.$lang.'"><img src="images/flags/'.$lang.'.png" alt="'.$lang.'" /></a> ';
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
