<?php
   define('source', 'donations');
   include 'common.php';
   include inc . 'init.php';
   include inc . 'header.php';
?>
<?php echo '
        
	<p>
        <br />
          <strong>'.AMSN_DONATIONS_TITLE.'</strong> 
        </p>
<p>
            '.DONATION_DESC1.'<br /><br />'.DONATION_DESC2.'<br /><br />';
?>
<?php
foreach($devels as $devel) {
        if($devel[3]) {
                echo '<a href="http://sourceforge.net/donate/index.php?user_id='.$devel[2].'">'.DONATE_TO.''.$devel[0].' ('.$devel[1].')</a><br /><br />';
        }
}
?>
<?php echo '
<a href="developer.php">'.BACK_TO_DEV.'</a>
</p>';
?>
<?php include inc . 'footer.php'; ?>
