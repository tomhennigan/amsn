<?php
$question_vote='question'.$lang_set;
$answer_vote='answer'.$lang_set;
$query = mysql_query("SELECT id, $question_vote FROM `amsn_poll` ORDER BY time DESC LIMIT 1");
if (mysql_num_rows($query) === 1) {
  $poll = mysql_fetch_assoc($query);
  $answers = mysql_query("SELECT id, $answer_vote FROM `amsn_poll_answers` WHERE id_father = '" . (int)$poll['id'] . "' ORDER BY id") or die(mysql_error()); 
  if (mysql_num_rows($answers) > 1) {
    echo '<div>';
    echo '<h3 class="polls">'.POOLS_SIDE.'</h3>';
    echo '<div class="block_right_top"></div>';
    echo '<div class="block_right_content">';
    echo '<form action="'.inc.'poll_vote.php" method="post">';
    echo '<ul class="poll">';
    echo '<li><h4 class="poll_Q">'.$poll[$question_vote].'</h4></li>';
    for ($i = 0; $row = mysql_fetch_row($answers); $i++) {
      echo '<li style="text-align: left">';
      echo '<input type="radio" value="'.$row[0].'" name="poll_answer" id="answer'.$i.'" /><label for="answer'.$i.'">'.$row[1].'</label>';
      echo '</li>';
    }
    echo '</ul>';
    echo '<div style="text-align: center; margin-top: 5px">';
    echo '<input type="submit" value="'.POOL_SIDE_VOTE.'" />';
    echo '<input type="hidden" name="idf" value="'.$poll['id'].'" /><br/>';
    echo '<a href="poll_results.php">'.POOL_SIDE_RESULTS.'</a>';
    echo '</div>';
    echo '</form>';
    echo '</div>';
    echo '<div class="block_right_bottom"></div>';
    echo '</div>';
  }
}
?>
