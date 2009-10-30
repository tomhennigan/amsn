<?php
   define('source', 'developer');
   include 'common.php';
   include inc . 'init.php';
   include inc . 'header.php';
?>

<?php echo '<ul>
<li>
<b>'.AMSN_DEV_TEAM.'</b>
<br /><br />
'.DEV_DESC.'
<br/><br/>
</li>
<li>
<a href="current-developers.php">'.CURRENT_DEVS_DEV.'</a><br />
<br/></li>
</ul>
<ul><li>
<b>'.PLEASE_HELP.'</b><br /><br />
'.HELP_DESC.'<a href="http://www.amsn-project.net/forums/viewforum.php?f=8">http://www.amsn-project.net/forums/viewforum.php?f=8</a>
<br /><br />
'.DONATION_DESC.'<a href="donations.php">'.DONATIONS_DEV.'</a>
<br /></li></ul>

<ul><li>
<b>'.AMSN_BUG_REPORT.'</b><br /><br />
'.BUGS_DESC.'
<br /></li></ul>

<ul>
<li>
<a href="http://sourceforge.net/tracker/?func=add&amp;group_id=54091&amp;atid=472655">'.REPORT_BUG.'</a>
</li>
</ul>

<ul>
<li>
<a href="http://sourceforge.net/tracker/?group_id=54091&amp;atid=472655">'.PREV_BUG_REPORT.' </a><br /><br />
</li>
</ul>


<ul>
<li>
<b>'.AMSN_SVN.'</b><br /><br />
'.SVN_DESC.'
<br />
</li>
</ul>

<ul>
<li>
<a href="http://amsn.svn.sourceforge.net/viewvc/amsn/trunk/amsn/">'.BROWSE_SVN.'</a>
<br />
</li>
</ul>

<ul>
<li>
<a href="http://www.amsn-project.net/wiki/SVN">'.SVN_HOWTO.'</a>
</li>
</ul>



<ul>
<li>
<b>'.AMSN_TRANSLATE.'</b>
<br /><br />
'.TRANSLATE_DESC.'
</li>
</ul>

<ul>
<li>
<a href="translations.php">http://www.amsn-project.net/translations.php</a>
<br /><br />
</li>
</ul>'
?>
<?php include inc . 'footer.php'; ?>
