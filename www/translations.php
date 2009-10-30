<?php
   define('source', 'translations');
   include 'common.php';
   include inc . 'init.php';
   include inc . 'header.php';
?>
<?php echo '
        <p>
        <br/>
          <b>'.TRANSLATION_TITLE.'</b><br/><br/>
'.MAIL_LIST_TRANS.'<br/>
<br/>
'.JOIN_TRANS.'<br/>
<br/>
'.NEW_SENTENCES_TRANS.'<br/><br/><br/>
'.READ_THIS_TRANS.'
'.READ_AGAIN_TRANS.'
'.SEND_UPDATE_TRANS.'
'.CAN_HELP_TRANS.'
'.BE_CAREFUL.'
'.NEW_LANG_TRANS.'';
?>
<?php
include inc . 'langlist.php';
include inc . 'footer.php';
?>
