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
  echo trans('amsndescription');
echo '</p>';
echo '<ul>';
echo '<li>'.trans('displaypics').'</li>';
echo '<li>'.trans('customemoticons').'</li>';
echo '<li>'.trans('multilangsupport').'</li>';
echo '<li>'.trans('webcamsupport').'</li>';
echo '<li>'.trans('signinwithmore').'</li>';
echo '<li>'.trans('fastfiletransfers').'</li>';
echo '<li>'.trans('groupsupport').'</li>';
echo '<li>'.trans('animemoticons').'</li>';
echo '<li>'.trans('chatlogs').'</li>';
echo '<li>'.trans('timestamping').'</li>';
echo '<li>'.trans('eventalarms').'</li>';
echo '<li>'.trans('conferencingsupport').'</li>';
echo '<li>'.trans('tabbedwindows').'</li>';
echo '</ul>';
echo trans('forfullfeatures','<a href="features.php">','</a>','<a href="plugins.php">','</a>','<a href="skins.php">','</a>');
echo '<br /><br />';

switch(remoteOS()) {
    case 'Windows':
    $url='http://prdownloads.sourceforge.net/amsn/aMSN-0.96-3-windows-installer.exe';
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
echo '<a href="'.$url.'" id="download"></a>';
?>
<a href="plugins.php" id="plugins"></a>
<a href="skins.php" id="skins"></a>

<?php include inc . 'news.php' ?>
<?php include inc . 'footer.php'; ?>
