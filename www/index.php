<?php 
define('source', 'index');
include 'common.php';
include 'libs/func.lib.php';
include inc . 'init.php';
include inc . 'header.php'; 
?>

  <img class="preload" src="images/download_hover.png" alt="" />
  <img class="preload" src="images/plugins_hover.png" alt="" />
  <img class="preload" src="images/skins_hover.png" alt="" />



<!--box with bow-->
<br />
<div style="text-align: center">
<img src="images/box2.png" alt=" aMSN box " />
</div>

        <p>
  <?php
  echo AMSN_DESC.'
</p>
<ul>
<li>'.DESC_OFF_MSG.'</li>
<li>'.VOICE_CLIP.'</li>
<li>'.DISPLAY_PICS.'</li>
<li>'.CUSTOM_EMOS.'</li>
<li>'.MULTI_LANG.'</li>
<li>'.WEB_CAM_SUPPORT.'</li>
<li>'.SIGNIN_MORE.'</li>
<li>'.FSPEED_FTRANS.'</li>
<li>'.GROUP_SUPPORT.'</li>
<li>'.EMOS_WITH_SOUND.'</li>
<li>'.CHAT_LOGS.'</li>
<li>'.TIMESTAMPING.'</li>
<li>'.EVENT_ALARM.'</li>
<li>'.CONFERENCE_SUPPORT.'</li>
<li>'.TABBED_CHAT.'</li>
</ul>
<p>'.FOR_FULL_FEATURES.'</p>';

switch(remoteOS()) {
    case 'Windows':
    $url='http://sourceforge.net/projects/amsn/files/amsn/0.98.1/aMSN-0.98.1-1-tcl85-windows-installer.exe/download';
    break;
    case 'Linux':
    $url='linux-downloads.php';
    break;
    case 'Mac':
    $url='http://sourceforge.net/projects/amsn/files/amsn/0.98.1/aMSN-0.98.1-1.dmg/download';
    break;
    case 'FreeBSD':
    $url='http://www.freshports.org/net-im/amsn/';
    break;
    default:
    $url="download.php";
    break;
  }
echo '<a href="'.$url.'" id="download"><span>'.DOWN_IMG.'</span></a>
<a href="plugins.php" id="plugins"><span>'.PLUG_IMG.'</span></a>
<a href="skins.php" id="skins"><span>'.SKIN_IMG.'</span></a>';
?>
<?php include inc . 'news.php' ?>
<?php include inc . 'footer.php'; ?>
