<?php
include 'common.php';
/**************************************/
/* Shows and rescales an image        */
/**************************************/
/* Takes the following arguments:     */
/* file=path to the image file        */
/* height=new height/unset if default */
/* width=new width/unset if default   */
/**************************************/

if(!isset($_GET['id'])) {
	die('ERROR! No file specified!');
}
$file=getFileSysName($_GET['id']);

if($file == '') {
	die('ERROR! Bad file specified!');
}

$info=getimagesize($file);


if($info[0] > $info[1]) {
        $scale=320/$info[0];
} else {
        $scale=240/$info[1];
}

$width=$info[0]*$scale;
$height=$info[1]*$scale;

$new=imagecreatetruecolor($width,$height);

switch($info[2]) {
	case 1:
	$im=imagecreatefromgif($file);
	break;
	case 2:
	$im=imagecreatefromjpeg($file);
	break;
	case 3:
	$im=imagecreatefrompng($file);
	break;
	default:
	die("Invalid image type!");
	break;
}

imagecopyresampled($new,$im,0,0,0,0,$width,$height,$info[0],$info[1]);

header("Content-type: image/png");
imagepng($new);

imagedestroy($im);
imagedestroy($newim);
?>
