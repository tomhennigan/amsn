<?php
   define('source', 'poll-results');
   include 'common.php';
   include inc . 'init.php';
   include inc . 'header.php';
?>

<?php

$id = (isset($_GET['poll']) && ereg('^[0-9]+$', $_GET['poll'])) ? (int)$_GET['poll'] : 0;

$trans_qu='poll_question';
$trans_ans='poll_answer';
$query_poll = mysql_query("SELECT `id`, question FROM `amsn_poll` " . ($id === 0 ? 'ORDER BY id DESC' : "WHERE `id` = '{$id}'"));

if (!mysql_num_rows($query_poll)) {
    echo '<p>'.POLL_NOT_EXIST.'</p>';
    return;
}

while ($poll = mysql_fetch_row($query_poll)) {
$idq=$poll[0];
	$total_query = mysql_query("SELECT SUM(`votes`) AS total, MAX(`votes`) AS max FROM `amsn_poll_answers` WHERE `id_father` = '" . (int)$poll[0] . "'");
	
	if (mysql_num_rows($total_query) ) {
		$total_row = mysql_fetch_row($total_query);
		$total = $total_row[0];
		if ($total == 0)
			continue;
		$max = (int) (100 * $total_row[1] / $total);
	} else {
		$total = 0;
		$max = 0;
	}
	
	$query_answers = mysql_query("SELECT id, answer, `votes` FROM `amsn_poll_answers` WHERE `id_father` = '" . (int)$poll[0] . "' ORDER BY id");
	
	if (mysql_num_rows($query_answers) > 1) {
	echo '<h3>'.trans($idq, $trans_qu)."</h3>\n<ul>\n";
	while ($row = mysql_fetch_row($query_answers)) {
		$ida=$row[0];
		$percentage =  (int) (100 * $row[2] / $total);
		echo '<li>'.trans($ida, $trans_ans).' ('.POLLS_VOTES.': '.$row[2].' '.(($total === 0) ? "" : " - <b>".$percentage.'%</b>)');
		echo '<br/><img alt="bar chart" src="images/poll_graph.php?percent='.$percentage.'&amp;val='.(int)($percentage * 100 / $max).'"/></li>';
	}
	echo "</ul>\n";
	}
	
	if (isset($total)) 
		echo ''.TOTAL_NUMBER_VOTES.' : <b>'.$total.'</b><br/><br/>';
	
	?>
	
<br/>

<?php
}
?>
<?php echo '<a href="index.php">'.POLL_TO_MAIN.'</a>'; ?>

<?php include inc . 'footer.php'; ?>

