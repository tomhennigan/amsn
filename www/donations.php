<?php
   define('source', 'donations');
   include 'common.php';
   include inc . 'init.php';
   include inc . 'header.php';
?>

        
	<p>
        <br />
          <strong>aMSN Donations:</strong> 
        </p>
<p>
            Sometimes users want to thank the developers for all the time and effort put into the development of a successfull project.  For this reason, we have set up a particular location in which you can donate to specific developers.<br /><br />aMSN as a whole, does not accept donations, but if you want to thank a specific member of the aMSN development team, we provide you these links, so that you may do so:<br /><br />

<?php
foreach($devels as $devel) {
        if($devel[3]) {
                echo '<a href="http://sourceforge.net/donate/index.php?user_id='.$devel[2].'">Donate To : '.$devel[0].' ('.$devel[1].')</a><br /><br />';
        }
}
?>

<a href="developer.php">Back To Developer Page</a>
</p>

<?php include inc . 'footer.php'; ?>
