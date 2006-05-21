<?php
/* Global Configuration */
define('DBHOST','localhost');
define('DBUSER','root');
define('DBPASS','');
define('EMAIL','nobody@sf.net');

/* Webpage Configuration */
define('DBNAME_WWW','www');
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

#format: 0->name 1->description 2->author 3->ID of image in wiki or 0 for none 4-> filename on the sf.net release system, blank for non
$skins=array(	array("Haudrey",'Haudrey','acabtheshura',0,'haudrey_aMSN_v1.2.zip'),
	array("pmdzskin",'pmdzskin','pmd',0,'pmdzskin-1.0.zip'),
	array("aDarwin",'A well deserved tribute to Darwin','Daniel Buenfil',81,'aDarwinV.4-0.95.zip'),
        array('aMSN for Mac','aMSN for Mac','Antero &amp; Martti Tiainen',65,'amsn-for-mac-0.95.zip'),
        array('Aqua Skin','Aqua Skin','BigBadBen',87,'AQUA-0.95.zip'),
        array('Brushed Metal','Brushed Metal, Final Build','BigBadBen',88,'BrushedMetal-0.95.zip'),
        array('No Name','No Name, Build 2','BigBadBen',0,'TheNoNameBrand-0.95.zip'),
        array('Sheeny-Deluxe','Sheeny-Deluxe','Lee Olson',82,''),
        array('Snow Grey','Snow Grey, Build 1','ThEdOOd',89,'snowgrey-0.95.zip'),
        array('Ubuntu (Human)','Ubuntu','Karel Demeyer',83,'Ubuntu-Human-0.95.zip'),
        array('Unified','Unified','Daniel Buenfil',66,'Unified-0.95.zip'),
        array('Clearlooks','Clearlooks','reggaemanu',95,'Clearlooks-0.95.zip'),
        array('Tux','The original Tux Skin by Steels - Everaldo with a lot of tiny penguins. Updated for aMSN 0.95','Guillaume Lambert',94,'Tux-0.95.zip'),
        array('nilo-skin v0.2','aMSN and MSN Messenger skins fusion!','Jin-Roh',98,'nilo-skin_v0.2-0.95.zip'));

#format: 0->title 1->description 2-> author 3->version 4->Platforms 5->requires 6->ID of screenshot in wiki 7->package on sf.net release system
$plugins=array(array('aMSN Plus!','aMSN Extension similar to MSN Plus! (commands in chat window, multiple-text format, colored nicks)','Mark, Jerome Gagnon-Voyer &amp; Fred','2.6','All','aMSN 0.94',67,'amsnplus-2.6.zip'),
                array('Colorize','Change the color of your text from either a predefined list or randomly.','Karol Krizka','1.0','All','aMSN 0.94',70,'colorize-1.0.zip'),
		array('TeXIM','Renders LaTeX if it\'s prepended by \tex or by using the TeX Advanced Window','Andrei Barbu &amp; Boris FAURE','0.7','All','aMSN 0.95',0,'TeXIM-0.7.zip'),
		array('DBus Viewer','This plugin enables you to monitor dbus messages using the event log of aMSN','Jonne Zutt','0.1','Linux','aMSN 0.95 &amp; dbus',0,'dbusviewer-0.1.zip'),
		array('Desktop Integration','For KDE or GNOME users. It shows desktop-like dialogs instead of tcl/tk ones. It also sets some options to fit better in the desktop.','Isma','0.9','Linux','aMSN 0.95 &amp; KDE or GNOME',61,'desktop_integration-0.9.zip'),
		array('Emotes','Plugin to replace /me ocurrences in chat window','Youness Alaoui','0.1','All','aMSN 0.94',71,'emotes-0.1.zip'),
		array('Gename','Plugin for generating random names','Karol Krizka','1.0','All','aMSN 0.94',42,'gename-1.0.zip'),
		array('GLogs','Send logs of conversations to your email. It was made to take advantage of GMail features, but can be used with any mail account.','Ignacio Larrain','1.0','All','aMSN 0.95',0,'glogs-1.0.zip'),
		array('Growl','Growl notification on Mac OS X','Jerome Gagnon-Voyer','1.1','Mac OS X','aMSN 0.94',40,'growl-1.1.zip'),
		array('Faking It!','Online impersonation and character deviation','JoãF ariaa','1.0b2','All','aMSN 0.94',0,'fakingit-b2.zip'),
		array('Invisibility','This plugin will block contacts going offline and unblock when status changes to online','Anto Cvitic','0.1','All','aMSN 0.94',0,'Invisibility-b1.zip'),
		array('MoveWin','Move chat windows when they are created.','Arieh Schneier','0.1','All','aMSN 0.94',77,'movewin-0.1.zip'),
		array('Music','Music plugin compatible with iTunes, XMMS, Amarok and Winamp. Show current playing song in nickname and show/send current playing song from the chatwindow. Mac OS X, Linux or Windows','Jerome Gagnon-Voyer &amp; Le Philousophe','1.3','All','aMSN 0.94',73,'music-1.3.zip'),
		array('POP3','Plugin to check POP3 accounts in aMSN in the same way as hotmail ones.','Arieh Schneier','2.2','All','aMSN 0.95',76,'pop3-2.2.zip'),
		array('Remind','Shows the last sentences of the previous conversations when opening a new chat window','Fred','1.2','All','aMSN 0.94',74,'remind-1.2.zip'),
		array('Say It','Speaks the messages you receive in the background. It will use the default voice set in the system preferences. If you enter a different voice (Mac), make sure you use a capital first letter.','William Bowling, Arieh Schneier &amp; Karel Demeyer','1.3','All','aMSN 0.94 &amp; <a href="http://www.cstr.ed.ac.uk/projects/festival/">text2speech</a> for Linux',79,'	sayit-1.3.zip'),
		array('What Is','Get information from text/word or translate it to an other language!','Jasper Huzen','1.2','All','aMSN 0.94',50,'whatis-1.2.zip'),
		array('WinSkin','Some options to make the contact list smaller','Arieh Schneier','0.11','All','aMSN 0.94',75,'winskin-0.11.zip'),
                array('BigSmileys','Show an extra smileys button for selecting from customs smileys with a bigger preview.','Pablo Novara','20060116','All','aMSN 0.94',93,'bigsmileys-20060116.zip'),
                array('Drae','Search for the description of the selected word in the Royal Spanish Academy dictionary <br/>--<br/>Busca la definicion del texto seleccionado en el diccionario de la Real Academia Espa�la.','Zaskar','1.0','Linux (requires lynx)','aMSN 0.94',92,'drae-1.0.zip'),
		array('Organize Received','Saves received files by default in a subdirectory of the sender and optionally into another subdirectory of the date','Nilton Volpato','0.4','All','aMSN 0.94',0,'organize_received-0.4.zip'),
		array('SendDraw','Pablo Novara','Allows you to send a image file as a draw to your contacts.','20060213','All','aMSN 0.95',0,'senddraw-20060213.zip'));
?>
