<?php
/* Global Configuration */
define('DBHOST','localhost');
define('DBUSER','root');
define('DBPASS','');
define('EMAIL','nobody@sf.net');

/* Webpage Configuration */
define('DBNAME_WWW','amsn');
define('DBNAME_FORUM','phpbb');

/* Bugs Configuration */
define('DBNAME_BUGS','bugs');
define('TBUGS','bugs');
define('TBUGREPORTS','bugreports');
define('TBLOCK','blocked');

#langlist directory
$lang_dir='/home/groups/a/am/amsn/htdocs/langsdat';

#format: 0->name 1->username 3->ID 4->accept donations
$devels=array(array('Alvaro J. Iradier Muro','airadier',551303,true),
                array('Philippe Khalaf','burgerman',0,false),
                array('Pavel V&aacute;vra (Plamen)','cz-plamen',1180248,true),
                array('Jerome Gagnon-Voyer','germinator2000',826909,true),
                array('Alaoui Youness','kakaroto',686750,true),
                array('A S','lio_lion',971615,true),
                array('Karol Krizka','roadkillbunny',737777,true),
                array('Thomas Geirhovd','tg90nor',797224,true),
                array('Sander Hoentjen','tjikkun',491386,true));
?>
