<?php
/**************************************/
/* Shows and rescales an image        */
/**************************************/
/* Takes the following arguments:     */
/* file=path to the image file        */
/* height=new height/unset if default */
/* width=new width/unset if default   */
/**************************************/

if(!isset($_GET['file'])) {
	die('ERROR! No file specified!');
}
$file=$_GET['file'];
$info=getimagesize($file);

$width=(isset($_GET['width']))?$_GET['width']:0;
$height=(isset($_GET['height']))?$_GET['height']:0;

if($width>$height) {
        $scale=$width/$info[0];
} else {
        $scale=$height/$info[1];
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

#imagedestroy($im);
#imagedestroy($newim);
?>
