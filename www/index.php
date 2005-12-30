<?php 
   define('source', 'index');
   include 'common.php';
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
          More features can be added to aMSN with <a href="plugins.php">plugins</a>, or completely change it's look with different <a href="skins.php">skins</a>!<br /><br />

           	<script type="text/javascript">
		   		function platformDirect()
		   			{

		   				<!-- Test is positive if the platform is Windows -->
		   				if(navigator.userAgent.indexOf("Win") > -1)
		   					{
		   						location = "http://prdownloads.sourceforge.net/amsn/amsn-0.95-windows-installer-2.exe";
		   					}
		  				<!-- Test is positive if the platform is Linux -->
		   				else if(navigator.userAgent.indexOf("Linux") > -1)
		   					{
		   					    location = "linux-downloads.php";
		   					}
		   				<!-- Test is positive if the platform is FreeBSD -->
		   				else if(navigator.userAgent.indexOf("FreeBSD") > -1)
		   					{
		   						location = "http://www.freshports.org/net/amsn/";
		   					}
		   				<!-- Test is positive if the platform is Mac OS X (Safari) -->
		   				else if(navigator.userAgent.indexOf("Mac OS X") > -1)
		   					{
		   						location = "http://prdownloads.sourceforge.net/amsn/amsn-0-95-final.dmg";
		   					}
		   				<!-- Test is positive if the platform is Mac OS X (Explorer)-->
		   				else if(navigator.userAgent.indexOf("Mac") > -1)
		   					{
		   						location = "http://www.cmq.qc.ca/4w/amsn/";
		   					}
		   				<!-- Fallback -->
		   				else
		   					{
		   						location = "download.php";
		   					}

		   			  }
			</script>

           <a href="download.php" onclick="platformDirect(); return false;" id="download"></a>
           <a href="plugins.php" id="plugins"></a>
           <a href="skins.php" id="skins"></a>

<?php include inc . 'news.php' ?>
<?php include inc . 'footer.php'; ?>
