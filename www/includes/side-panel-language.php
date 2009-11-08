<div>
<h3><?php echo LANGUAGE_SIDE; ?></h3>
<div class="block_right_top"></div>
<div class="block_right_content block_language">
<?php
$flag=0;
$languages = array();

function cmp_langs($a, $b)
{
    $values = array('en' => 0, 'fr' => 1, 'es' => 2, 'de' => 3, 'tr' => 4);
    if (isset($values[$a])) {
        $av = $values[$a];
    } else {
        $av = 10000;
    }

    if (isset($values[$b])) {
        $bv = $values[$b];
    } else {
        $bv = 10000;
    }
    if ($av == $bv) {
        return 0;
    }
    return ($av < $bv) ? -1 : 1;
}

foreach (glob('includes/languages/*/*.php') as $filename) {
  $keywords = preg_split("/\//", $filename);
  $lang = $keywords[2];

  $languages[] = $lang;
}

usort($languages, "cmp_langs");

foreach ($languages as $lang) {
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
