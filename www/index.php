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
          <strong>aMSN</strong> is a free open source MSN Messenger clone, with features such as:
        </p>
          <ul>
            <li>Display pictures</li>
            <li>Custom emoticons</li>

            <li>Multi-language support (around 40 languages currently supported)</li>
            <li>Webcam support</li>
            <li>Sign in to more than one account at once</li>
            <li>Full-speed File transfers</li>
            <li>Group support</li>
            <li>Normal, and animated emoticons with sounds</li>
            <li>Chat logs</li>
            <li>Timestamping</li>
            <li>Event alarms</li>
            <li>Conferencing support</li>
            <li>Tabbed chat windows</li>
          </ul>
          For a full list, see the <a href="features.php">features page</a>.
          More features can be added to aMSN with <a href="plugins.php">plugins</a>, or completely change its look with different <a href="skins.php">skins</a>!<br /><br />

  <?php
  switch(remoteOS()) {
    case 'Windows':
    $url='dlfile.php?file=amsn-0.95-windows-installer-2.exe';
    break;
    case 'Linux':
    $url='linux-downloads.php';
    break;
    case 'FreeBSD':
    $url='http://www.freshports.org/net/amsn/';
    case 'Mac':
    $url="dlfile.php?file=amsn-0-95-final.dmg";
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
