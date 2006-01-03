<!-- Poll -->

<?php

/* uncomment next line to enable language block in the sidebar */
/* include inc . 'side-panel-language.php'; */


$query = mysql_query("SELECT id, question FROM `amsn_poll` ORDER BY time DESC LIMIT 1");



if (mysql_num_rows($query) === 1) {
    $poll = mysql_fetch_assoc($query);

    $answers = mysql_query("SELECT id, answer FROM `amsn_poll_answers` WHERE id_father = '" . (int)$poll['id'] . "' ORDER BY id"); 

// var_dump(mysql_num_rows($answers)); 

$answers = mysql_query("SELECT id, answer FROM `amsn_poll_answers` WHERE id_father = '" . (int)$poll['id'] . "' ORDER BY id") or print('Error: ' . mysql_error()); 

    if (mysql_num_rows($answers) > 1) {
?>



 <div class="block_right">
    <h3 class="polls">Poll</h3>
    <div class="block_right_top"></div>
    <div class="block_right_content">

    <form action="<?php echo inc . 'poll_vote.php' ?>" method="post">
    <ul class="poll">
    <li><h4 class="poll_Q"><?php echo $poll['question'] ?></h4></li>

<?php
          for ($i = 0; $row = mysql_fetch_row($answers); $i++) {
?>	
	<li style="text-align: left">
          <input type="radio" value="<?php echo $row[0] ?>" name="poll_answer" id="answer<?php echo $i ?>" /><label for="answer<?php echo $i ?>"><?php echo $row[1] ?></label>
	</li>

<?php
}
?>
</ul>
<div>
        <input type="submit" value="Vote" />
    <input type="hidden" name="idf" value="<?php echo $poll['id'] ?>" />
         <a href="poll_results.php">View results</a>
</div>
</form>
          </div>
        <div class="block_right_bottom"></div>

<?php
    }
 }
?>
</div>


<!-- Please Help -->

      <div class="block_right">
        <h3>Please Help</h3>
        <div class="block_right_top"></div>
        <div class="block_right_content">
        <ul class="help">

        <li>Help aMSN developers by submitting a donation: 
	<a href="donations.php"><br /><br />aMSN donations page</a></li>
        </ul>
<br />
        </div>
        <div class="block_right_bottom"></div>
      </div>

<!-- Forums -->

      <div class="block_right">
        <h3 class="forums">Forums</h3>

        <div class="block_right_top">&nbsp;</div>
        <div class="block_right_content">
        <ul class="forums">

          <li><b><a href="http://forums.cocoaforge.com/viewforum.php?f=14">Mac aMSN Forums</a></b></li>
          <li><br /></li>

          <li><b><a href="http://amsnforums.net">aMSN Forums</a></b></li><li><br />
</li>
<li style="text-align: center">&#8226; Recent Posts &#8226;<br /></li>
<li>
	      <script type="text/javascript" src="http://amsnforums.net/syndicate-lastpost.php">
	</script></li>
        </ul>
        </div>
        <div class="block_right_bottom"></div>
      </div>

<!-- Links -->

	<div class="block_right">
        <h3 class="links">Links</h3>
        <div class="block_right_top"></div>
        <div class="block_right_content">
          <ul class="forums" style="text-align:center">
            <li>
              Linux installer created by <a href="http://www.bitrock.com/">Bitrock</a>, thanks very much!
            </li>

            <li><br /></li>
            <li><a href="http://sourceforge.net/projects/amsn/">SourceForge project page</a> </li>

            <li><br /> </li>
            <li><a href="http://sourceforge.net/"><img src="images/sflogo.png" alt="SourceForge.net Logo" /></a></li>

            <li><br /></li>
            <li><a href="http://validator.w3.org/check?uri=referer"><img src="images/vxhtml.png" alt="Valid XHTML 1.0!" /></a></li>

            <li><br /></li>
            <li><a href="http://jigsaw.w3.org/css-validator/validator?uri=http://amsn.sourceforge.net/stylesheet.css"><img src="images/vcss.png" alt="Valid CSS!" /></a></li>          
         </ul>
        </div>
        <div class="block_right_bottom"></div>
      </div>
