<?
require_once '../common.php';

$max = (isset($_GET['max']) && ereg('^[0-9]+$', $_GET['max'])) ? (int)$_GET['max'] : 300;
$val = (isset($_GET['val']) && ereg('^[0-9]+$', $_GET['val'])) ? (int)$_GET['val'] : 0;
$percent = (isset($_GET['percent']) && ereg('^[0-9]+$', $_GET['percent'])) ? (int)$_GET['percent'] : $val;


// Define .PNG image
header("Content-type: image/png");
$imgWidth=$max;
$imgHeight=15;
$numGridLines = 10;
$pad = $imgWidth / $numGridLines;

// Define string to show
$string = $percent . "%";
$font = 3;
$fontx = $imgWidth - (strlen($string) * imagefontwidth($font)) - 2;
$fonty = 2; //(imagefontheight($font) - $imageHeight) / 2;

// Create image and define colors
$image=imagecreate($imgWidth, $imgHeight);
$colorWhite=imagecolorallocate($image, 255, 255, 255);
$colorBlack=imagecolorallocate($image, 0, 0, 0);
$colorGrey=imagecolorallocate($image, 192, 192, 192);
$colorDarkBlue=imagecolorallocate($image, 104, 157, 228);
$colorLightBlue=imagecolorallocate($image, 184, 212, 250);

if (isset($_GET['grid'])) {
  // Create border around image
  imageline($image, 0, 0, 0, $imgHeight, $colorGrey);
  imageline($image, 0, 0, $imgWidth, 0, $colorGrey);
  imageline($image, $imgWidth - 1, 0, $imgWidth - 1, $imgHeight - 1, $colorGrey);
  imageline($image, 0, $imgHeight - 1, $imgWidth - 1, $imgHeight - 1, $colorGrey);

  // Create grid
  for ($i=1; $i<$numGridLines + 1; $i++){
    imageline($image, $i*$pad, 0, $i*$pad, $imgHeight, $colorGrey);
  }
}

// Create bar charts
$percentage = (int) ( $imgWidth * $val / 100);
imagefilledrectangle($image, 0, 0, $percentage, $imgHeight, $colorDarkBlue);
imagefilledrectangle($image, 0, 3, $percentage-3, $imgHeight, $colorLightBlue);
imagestring($image, $font, ($percentage + 5 > $fontx ? $fontx : $percentage + 5) , $fonty, $string, $colorBlack);

// Output graph and clear image from memory
imagepng($image);
imagedestroy($image);

?>

