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
  echo (AMSN_DESC);
echo '</p>';
echo '<ul>';
echo '<li>'.DESC_OFF_MSG.'</li>';
echo '<li>'.VOICE_CLIP.'</li>';
echo '<li>'.DISPLAY_PICS.'</li>';
echo '<li>'.CUSTOM_EMOS.'</li>';
echo '<li>'.MULTI_LANG.'</li>';
echo '<li>'.WEB_CAM_SUPPORT.'</li>';
echo '<li>'.SIGNIN_MORE.'</li>';
echo '<li>'.FSPEED_FTRANS.'</li>';
echo '<li>'.GROUP_SUPPORT.'</li>';
echo '<li>'.EMOS_WITH_SOUND.'</li>';
echo '<li>'.CHAT_LOGS.'</li>';
echo '<li>'.TIMESTAMPING.'</li>';
echo '<li>'.EVENT_ALARM.'</li>';
echo '<li>'.CONFERENCE_SUPPORT.'</li>';
echo '<li>'.TABBED_CHAT.'</li>';
echo '</ul>';
echo '<p>'.FOR_FULL_FEATURES.'</p>';
echo '<br /><br />';

switch(remoteOS()) {
    case 'Windows':
    $url='http://prdownloads.sourceforge.net/amsn/aMSN-0.97.2-tcl85-windows-installer.exe';
    break;
    case 'Linux':
    $url='linux-downloads.php';
    break;
    case 'FreeBSD':
    $url='http://www.freshports.org/net-im/amsn/';
    break;
    default:
    $url="download.php";
    break;
  }
echo '<a href="'.$url.'" id="download">'.DOWN_IMG.'</a>';
echo '<a href="plugins.php" id="plugins">'.PLUG_IMG.'</a>';
echo '<a href="skins.php" id="skins">'.SKIN_IMG.'</a>';
?>
<?php include inc . 'news.php' ?>
<?php include inc . 'footer.php'; ?>
