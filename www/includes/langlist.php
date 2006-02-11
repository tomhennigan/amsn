<table class="langlist">
<tr><th>Language</th><th>Missing keys</th></tr>
<?php
#Taken from php.net
function utf2html ($utf2html_string)
{
   $f = 0xffff;
   $convmap = array(
/* <!ENTITY % HTMLlat1 PUBLIC "-//W3C//ENTITIES Latin 1//EN//HTML">
   %HTMLlat1; */
     160,  255, 0, $f,
/* <!ENTITY % HTMLsymbol PUBLIC "-//W3C//ENTITIES Symbols//EN//HTML">
   %HTMLsymbol; */
     402,  402, 0, $f,  913,  929, 0, $f,  931,  937, 0, $f,
     945,  969, 0, $f,  977,  978, 0, $f,  982,  982, 0, $f,
   8226, 8226, 0, $f, 8230, 8230, 0, $f, 8242, 8243, 0, $f,
   8254, 8254, 0, $f, 8260, 8260, 0, $f, 8465, 8465, 0, $f,
   8472, 8472, 0, $f, 8476, 8476, 0, $f, 8482, 8482, 0, $f,
   8501, 8501, 0, $f, 8592, 8596, 0, $f, 8629, 8629, 0, $f,
   8656, 8660, 0, $f, 8704, 8704, 0, $f, 8706, 8707, 0, $f,
   8709, 8709, 0, $f, 8711, 8713, 0, $f, 8715, 8715, 0, $f,
   8719, 8719, 0, $f, 8721, 8722, 0, $f, 8727, 8727, 0, $f,
   8730, 8730, 0, $f, 8733, 8734, 0, $f, 8736, 8736, 0, $f,
   8743, 8747, 0, $f, 8756, 8756, 0, $f, 8764, 8764, 0, $f,
   8773, 8773, 0, $f, 8776, 8776, 0, $f, 8800, 8801, 0, $f,
   8804, 8805, 0, $f, 8834, 8836, 0, $f, 8838, 8839, 0, $f,
   8853, 8853, 0, $f, 8855, 8855, 0, $f, 8869, 8869, 0, $f,
   8901, 8901, 0, $f, 8968, 8971, 0, $f, 9001, 9002, 0, $f,
   9674, 9674, 0, $f, 9824, 9824, 0, $f, 9827, 9827, 0, $f,
   9829, 9830, 0, $f,
/* <!ENTITY % HTMLspecial PUBLIC "-//W3C//ENTITIES Special//EN//HTML">
   %HTMLspecial; */
/* These ones are excluded to enable HTML: 34, 38, 60, 62 */
     338,  339, 0, $f,  352,  353, 0, $f,  376,  376, 0, $f,
     710,  710, 0, $f,  732,  732, 0, $f, 8194, 8195, 0, $f,
   8201, 8201, 0, $f, 8204, 8207, 0, $f, 8211, 8212, 0, $f,
   8216, 8218, 0, $f, 8218, 8218, 0, $f, 8220, 8222, 0, $f,
   8224, 8225, 0, $f, 8240, 8240, 0, $f, 8249, 8250, 0, $f,
   8364, 8364, 0, $f);

   return mb_encode_numericentity($utf2html_string, $convmap, "UTF-8");
}


$langlist = $lang_dir . DIRECTORY_SEPARATOR . 'langlist.dat';
$fp = @fopen($langlist, "r");
if (!$fp) die("Unable to open langlist file");
$line = fgets($fp);

while (!feof($fp) && $line != "\n") {
	$line = rtrim($line);
	list($file,$encoding,$missing,$langname) = split(' ',$line,4);
	echo '<tr><td><a href="view_lang.php?lang='.basename($file).'">'. utf2html($langname) .'</a></td><td>'.$missing.'</td></tr>'."\n";
	$line=fgets($fp);
}
fclose($fp);
?>
</table>
<?php
/* function to echo code from a file to client */
function insert_file($filename)
  {
  global $debug;

  if ($debug==206) {
          echo " open " . $filename . " !<br>";
      $fp = fopen ($filename, "r");
  } else {
      $fp = @fopen ($filename, "r");
  }

  if ($fp)
    {
    $contents = fread ($fp, filesize ($filename));
    fclose ($fp);
    echo $contents;
    }

  }

/* function to insert language links */
function insert_lang()
  {
  global $langdat;
  global $module_name;

  $fp = fopen ("/home/groups/a/am/amsn/htdocs/modules/Translation/web/langlist.dat", "r");
    if ($fp) {
          $temp = fgets($fp, 1024);
                $n = 0;

                echo "<table border=\"0\" align=\"center\" width=\"138\" cellpadding=\"0\" cellspacing=\"0\">"
        ."<tr><td background=\"themes/DeepBlue/images/table-title.gif\" width=\"138\" height=\"20\">"
        ."&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<font color=\"#FFFFFF\"><b>Languages</b></font>"
        ."</td></tr><tr><td><img src=\"themes/DeepBlue/images/pixel.gif\" width=\"100%\" height=\"3\"></td></tr></table>\n"
        ."<table border=\"0\" cellpadding=\"0\" cellspacing=\"0\" width=\"138\">\n"
        ."<tr><td width=\"138\" bgcolor=\"#000000\">\n"
        ."<table border=\"0\" cellpadding=\"1\" cellspacing=\"1\" width=\"138\">\n"
        ."<tr><td width=\"138\" bgcolor=\"#ffffff\">\n";

	echo "<table width=130 border=0 class=\"tab1\"><tr><td><b>Language</b></td><td><b>Missing</b></td></tr>\n<tr><td>";
                while ( (!feof($fp)) && ($temp!="\n") ) {
                  $linerm = str_replace( chr(10) ,'',$temp);
                  $linerm = str_replace( chr(13) ,'',$linerm);

                  $data = explode(" ",$linerm);

                  echo "<A HREF=\"modules.php?name=$module_name&page=$data[0]\">";

                  for ($i=3; $i<=(count($data)); $i++)
                          echo $data[$i] . " ";

                  echo "</A></td><td>";

                  echo $data[2] . "</td></tr>\n<tr><td>";

                  $temp = fgets($fp, 1024);
                }
	echo "</td></tr></table>";

        echo "</td></tr></table></td></tr></table><br>";

          fclose ($fp);
        }// fp was opened
  }

function customthemefooter() {
    global $index;
    echo "<br>";
    if ($index == 1) {
        echo "</td><td><img src=\"themes/DeepBlue/images/pixel.gif\" width=\"10\" height=\"1\" border=\"0\" alt=\"\"></td><td valign=\"top\" width=\"138\" body background=\"themes/DeepBlue/images/bg.png\" >\n";
        insert_lang();
        echo "<td><img src=\"themes/DeepBlue/images/pixel.gif\" width=\"6\" height=\"1\" border=\"0\" alt=\"\">";
    }
 else {
        echo "</td><td colspan=\"2\"><img src=\"themes/DeepBlue/images/pixel.gif\" width=\"10\" height=\"1\" border=\"0\" alt=\"\">";
    }
    echo "</table>\n"
        ."<table border=0 width=100% cellpadding=0 cellspacing=0 body background=\"themes/DeepBlue/images/bg-middle.png\"><tr><td align=\"left\"><img border=\"0\" src=\"themes/DeepBlue/images/left-bottom.gif\" alt=\"Amsn Messenger\" hspace=\"0\"></a></td><td align=\"right\"><img border=\"0\" src=\"themes/DeepBlue/images/logo-graphic-bottom.png\" width=\"\"></td></tr></table><center>";

//  footmsg();
    echo "</center>";
}


function AddonSample($page) {
    global $module_name;
	include("header.php");
    if($page=="") {
	OpenTable();
	echo ""._DESC1."";
	CloseTable();
	echo "<br>";
	OpenTable();
	echo ""._DESC2."";
	CloseTable();
	echo "<br>";
	OpenTable();
	echo ""._DESC3."";
	CloseTable();
	
    } else {
	 // security enhancement by spantie_pet
	 $page = basename($page);

	 $fp = fopen ("/home/groups/a/am/amsn/htdocs/modules/Translation/web/" . $page, "r");
         if ($fp) {
               $temp = fgets($fp, 1024);
               $n = 0;

               $linerm = str_replace( chr(10) ,'',$temp);
               $temp = str_replace( chr(13) ,'',$linerm);
               $data = explode(" ",$linerm);
		OpenTable();
		echo '<table border="0" width="100%"><tr><td align="left" valign="bottom"><font class="contenth">' . "\n";

                  for ($i=3; $i<=(count($data)); $i++)
                          echo $data[$i] . " ";
                  echo '</font><font class="content">&nbsp;&nbsp;<b>' . $data[2] . '</b></font></td><td align="right" valign="bottom"><font class="lang"><i>encoding</i> <b>';
                  echo $data[0] . '</b> <i>missing keys</i> : <b>';
                  echo $data[1] . '</b></font></td></tr></table>';

                  echo '<br><div class="contentb">Instructions :</div>';
                  echo '<div class="inst">1. : Read the <A HREF="http://cvs.sourceforge.net/cgi-bin/viewcvs.cgi/*checkout*/amsn/msn/lang/LANG-HOWTO?rev=HEAD&content-type=text/plain"><b>LANG-HOWTO</b></A> file with instructions for translators<br></div>';
                  echo '<div class="inst">2. : Download the old language file here : <A HREF="http://cvs.sourceforge.net/cgi-bin/viewcvs.cgi/*checkout*/amsn/msn/lang/lang' . $data[2] . '?rev=HEAD&content-type=text/plain"><b>';
                  echo 'lang' . $data[2] . '.</b></A><br></div>';
                  echo '<div class="inst">3. : Copy the keywords from the list below and add them to the language file.</div>';
                  echo '<div class="inst">4. : Translate the english explanations</div>';
		echo '<div class="inst">4. : Send the updated file to <A HREF=\"mailto:amsn-translations@lists.sourceforge.net\">amsn-translations@lists.sourceforge.net</A></div>';
		CloseTable();
		echo "<br>";
		$temp = fgets($fp, 1024);

                if ($temp=="") {
                    	OpenTable();
			echo "No missing keys to translate!<br>";
			CloseTable();
                } else {
			OpenTable();
			echo "<table cellpadding=\"2\" border=\"0\"><tr><td valign=\"top\">" . "\n";

                 while ( (!feof($fp)) && ($temp!="\n") ) {
                  $linerm = str_replace( chr(10) ,'',$temp);
                  $temp = str_replace( chr(13) ,'',$linerm);

	          $pos = strpos ( $temp, " ");
                  $rest = substr($temp, 0, $pos);
                  echo "<b>" . $rest . "</b></td><td>";
                  $rest = substr($temp, $pos);
                  echo $rest . "</td></tr><tr><td valign=\"top\">" . "\n";

                  $temp = fgets($fp, 1024);
                 }

                 echo "</td></tr></table>" . "\n";
			CloseTable();
		}
	} else {
		OpenTable();
		echo "ERROR! File not found!<br>";
		CloseTable();
	}

    }
//   include("footer.php");
	customthemefooter();
//	themefooter();
}
/*
switch($func) {
    default:
	AddonSample($page);
    break;

}*/

?>
