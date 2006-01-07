<?php
$query = mysql_query("SELECT id, question FROM `amsn_poll` ORDER BY time DESC LIMIT 1");
if (mysql_num_rows($query) === 1) {
  $poll = mysql_fetch_assoc($query);
  $answers = mysql_query("SELECT id, answer FROM `amsn_poll_answers` WHERE id_father = '" . (int)$poll['id'] . "' ORDER BY id") or die(mysql_error()); 
  if (mysql_num_rows($answers) > 1) {
    echo '<div class="block_right">';
    echo '<h3 class="polls">'.trans('poll').'</h3>';
    echo '<div class="block_right_top"></div>';
    echo '<div class="block_right_content">';
    echo '<form action="'.inc.'poll_vote.php" method="post">';
    echo '<ul class="poll">';
    echo '<li><h4 class="poll_Q">'.trans($poll['question']).'</h4></li>';
    for ($i = 0; $row = mysql_fetch_row($answers); $i++) {
      echo '<li style="text-align: left">';
      echo '<input type="radio" value="'.$row[0].'" name="poll_answer" id="answer'.$i.'" /><label for="answer'.$i.'">'.trans($row[1]).'</label>';
      echo '</li>';
    }
    echo '</ul>';
    echo '<div style="text-align: center; margin-top: 5px">';
    echo '<input type="submit" value="'.trans('vote').'" />';
    echo '<input type="hidden" name="idf" value="'.$poll['id'].'" /><br/>';
    echo '<a href="poll_results.php">'.trans('viewresults').'</a>';
    echo '</div>';
    echo '</form>';
    echo '</div>';
    echo '<div class="block_right_bottom"></div>';
    echo '</div>';
  }
}
?>