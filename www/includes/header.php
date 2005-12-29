
  </head>

  <body>

    <div id="title" class="center">

<?php
    $dir="images/logo/";
    $files=array();
    $dh=opendir($dir);
    while($file=readdir($dh)) {
           $file=$dir.'/'.$file;
           if(is_file($file)) {
                   $files[]=$file;
           }
    }
    $img=rand(0,count($files)-1);
    echo '<img alt="aMSN Logo" src="'.$files[$img].'" />';
?>
    </div>

    <div id="nav" class="center">
<?php

	if (source == 'index') define(nav_index, 'nav_on');
	else define(nav_index, 'nav');
        if (source == 'download') define(nav_download, 'nav_on');
        else define(nav_download, 'nav');
        if (source == 'features') define(nav_features, 'nav_on');
        else define(nav_features, 'nav');
        if (source == 'skins') define(nav_skins, 'nav_on');
        else define(nav_skins, 'nav');
        if (source == 'plugins') define(nav_plugins, 'nav_on');
        else define(nav_plugins, 'nav');
        if (source == 'screenshots') define(nav_screenshots, 'nav_on');
        else define(nav_screenshots, 'nav');
        if (source == 'docs') define(nav_docs, 'nav_on');
        else define(nav_docs, 'nav');
        if (source == 'developer') define(nav_developer, 'nav_on');
        else define(nav_developer, 'nav');

        echo '<a class="'.nav_index.'" href="index.php">Home</a>';
        echo '<a class="'.nav_download.'" href="download.php">Download</a>';
        echo '<a class="'.nav_features.'" href="features.php">Features</a>';
        echo '<a class="'.nav_skins.'" href="skins.php">Skins</a>';
        echo '<a class="'.nav_plugins.'" href="plugins.php">Plugins</a>';
        echo '<a class="'.nav_screenshots.'" href="screenshots.php">Screenshots</a>';
        echo '<a class="'.nav_docs.'" href="docs.php">Docs/Help</a>';
        echo '<a class="'.nav_developer.'" href="developer.php">Developer</a>';
?>
    </div>

<div id="<?php $navigator_user_agent = ( isset( $_SERVER['HTTP_USER_AGENT'] ) ) ? strtolower( $_SERVER['HTTP_USER_AGENT'] ) : '';
print ((stristr($navigator_user_agent, "konqueror")) || (stristr($navigator_user_agent, "safari"))?"container_mac":"container"); ?>" class="center">

      &nbsp;


    <div id="blurb">
       &nbsp;  <!--Spacing fix--> <br />



