<?php
@setlocale(LC_ALL, 'de_DE.utf-8');
define('TIME_FORMAT','%e. %B %y @ %H:%M:%S');
//header menu definitions START
define('HOME_MENU', 'Startseite');
define('DOWNLOAD_MENU', 'Downloads');
define('FEATURES_MENU','Funktionen');
define('SKINS_MENU','Skins');
define('PLUGINS_MENU','Plugins');
define('SCREEN_MENU','Screenshots');
define('DOCS_MENU','Dokumentation/Hilfe');
define('DEV_MENU','Entwicklung');
//header menu definitions END

// index.php definitions START
define('AMSN_DESC', '<strong>aMSN</strong> ist ein kostenloser, quelloffener Klon des MSN Messengers, mit folgenden Funktionen: ');
define('DESC_OFF_MSG', 'Offline-Nachrichten');
define('VOICE_CLIP', 'Sprachclips');
define('DISPLAY_PICS', 'Anzeigebilder');
define('CUSTOM_EMOS', 'Eigene Emoticons');
define('MULTI_LANG', 'Mehrsprachige Oberfläche (derzeit werden etwa 40 Sprachen unterstützt)');
define('WEB_CAM_SUPPORT', 'Webcam-Unterstützung');
define('SIGNIN_MORE', 'Mit mehr als einem Konto gleichzeitig anmelden');
define('FSPEED_FTRANS', 'Dateitransfers in voller Geschwindigkeit');
define('GROUP_SUPPORT', 'Kontaktgruppen');
define('EMOS_WITH_SOUND', 'Emoticons mit Sound');
define('CHAT_LOGS', 'Chat-Protokolle');
define('TIMESTAMPING', 'Zeitstempel');
define('EVENT_ALARM', 'Alarm bei Ereignissen');
define('CONFERENCE_SUPPORT', 'Video- und Audio-Konferenz');
define('TABBED_CHAT', 'Chatfenster mit Tabs');
define('FOR_FULL_FEATURES', 'Um eine komplette Funktionsliste zu sehen schauen sie auf die <a href="features.php">Funktionen-Seite</a>. Es können auch weitere Funktionen zu aMSN mit Hilfe von <a href="plugins.php">Plugins</a> hinzugefügt werden, sowie das Aussehen mit Hilfe von <a href="skins.php">Skins</a> komplett verändert werden!');
define('DOWN_IMG','aMSN holen');
define('PLUG_IMG','Plugins holen');
define('SKIN_IMG','Skins holen');
// index.php definitions END

//download.php definitions START
define('LINUX_DOWN', 'Linux');
define('MAEMO_DOWN', 'Nokia N900 (Maemo 5)');
define('WIN_DOWN', 'Windows');
define('WIN95_DOWN', 'Windows 95');
define('MACOSX_DOWN', 'Mac OS X(Universal)');
define('FREEBSD_DOWN', 'FreeBSD');
define('TARBALL_DOWN', 'Tarball Quellcode');
define('LATEST_SVN','Neueste Entwickler-Version (SVN Abbild vom ');
//download.php definitions END

//features.php definitions START
define('AMSN_DESC_FEAT', '<strong>aMSN</strong> ist ein kostenloser, quelloffener Klon des MSN Messengers, mit folgenden Funktionen:');
define('OFF_MSG_FEAT', '&#187; Offline-Nachrichten');
define('VOICE_CLIP_FEAT', '&#187; Sprachclips');
define('NLW_FEAT', '&#187; Neues Login-Fenster &amp; Kontaktliste (ab 0.97)');
define('DISPLAY_PICS_FEAT', '&#187; Anzeigebilder');
define('CUSTOM_EMOS_FEAT', '&#187; Eigene Emoticons');
define('MULTI_LANG_FEAT', '&#187; Mehrsprachige Oberfläche (derzeit werden etwa 40 Sprachen unterstützt)');
define('SIGNIN_MORE_FEAT', '&#187; Mit mehr als einem Konto gleichzeitig anmelden');
define('FTRANS_FEAT', '&#187; Dateitransfer');
define('GROUP_SUPPORT_FEAT', '&#187; Kontaktgruppen');
define('EMOS_WITH_SOUND_FEAT', '&#187; Emoticons mit Sound');
define('CHAT_LOGS_FEAT', '&#187; Chat-Protokolle');
define('EVENT_ALARM_FEAT', '&#187; Alarm bei Ereignissen');
define('CONFERENCE_SUPPORT_FEAT', '&#187; Video- und Audio-Konferenz');
define('WEB_CAM_SUPPORT_FEAT', '&#187; Webcam-Unterstützung');
define('HISTORY_FEAT', '&#187; Verlauf in Farbe');
define('AUTOCLOSE_FEAT', '&#187; Möglichkeit das Fenster des Dateitransfers automatisch zu schließen, wenn dieser fertig ist');
define('PLUGIN_WIN_FEAT', ' &#187; Neues Plugins-Protokoll-Fenster (Alt-P)');
define('PLUGIN_COMP_FEAT', '&#187; Plugins können die unterstützten Sprachen verwenden');
define('SKIN_WIN_FEAT', '&#187; Das Fenster zur Skin-Auswahl erscheint schneller');
define('SKINS_CHAT_FEAT', '&#187; Skins für das Chatfenster');
define('WIN_BOTTOM_FEAT', '&#187; Veränderbare Größe des Eingabebereichs im Chatfenster');
define('NEW_USER_GROUP_FEAT', '&#187; Wenn Sie einen neuen Kontakt hinzufügen, können Sie festlegen in welche Gruppe der Kontakt hinzugefügt werden soll');
define('CHAT_WIN_COLOR_FEAT', '&#187; Wenn ein Kontakt seinen Status verändert, passt sich die Farbe im oberen Teil des Chatfensters an (grün für Abwesend, grau für Offline, usw.)');
define('VERSION_ALERT_FEAT', '&#187; Neue grafische Benachrichtigung bei neuen Versionen von aMSN');
define('DOWN_RELEASE_FEAT', '&#187; Möglichkeit neue Versionen von aMSN direkt herunterzuladen');
define('AUTO_UPDATE_FEAT', '&#187; Automatisches Online-Update für Übersetzungen und Plugins');
define('DEL_USER_GUI_FEAT', '&#187; Neue grafische Oberfläche zum Löschen (und ggf. dabei Blocken) von Kontakten');
define('USER_NOTES_FEAT', '&#187; Notizen zu Kontakten machen');
define('MSN_MOBILE_FEAT', '&#187; Unterstützung für MSN Mobile Dienste');
define('TABBED_WIN_FEAT', '&#187; Chatfenster mit Tabs, zum Gruppieren von Konversationen');
define('STATUS_APPEAR_FEAT', '&#187; Status wird in einem Rahmen angezeigt, sodass er beim Scrollen nicht verschwindet');
define('ALERT_PICTURE_FEAT', '&#187; Anzeigebild in Online-Benachrichtigung (wie bei MSN 7)');
define('HISTORY_STATS_FEAT', '&#187; Statistiken für den Verlauf (Chat-Protokoll)');
define('LOGIN_STATUS_FEAT', '&#187; Jetzt ist es möglich den Status vor dem Login zu wählen (vorher war es nur möglich sich unsichtbar oder online anzumelden)');
define('TIMESTAMPING_FEAT', '&#187; Zeitstempel');
define('MORE_FEAT', 'Aber das ist nicht alles!  Es können auch weitere Funktionen zu aMSN mit Hilfe von <a href="plugins.php">Plugins</a> hinzugefügt werden, sowie für Abenteuerlustige, das Aussehen mit Hilfe von <a href="skins.php">Skins</a> komplett verändert werden!');
//features.php definitions END

//skins.php definitions START
define('LOVES_CUSTOM', '<strong>aMSN liebt Anpassungen!</strong>');
define('SKIN_DESC', ', und ein Weg es anzupassen ist ein "Skin". Ein Skin ändert das Aussehen von aMSN. Hier können Sie Skins herunterladen, die von aMSN und Mitwirkenden erstellt wurden.');
define('INSTALL_SKIN', 'Sie finden eine Anleitung, wie Sie einen Skin installieren können, im <a href="http://www.amsn-project.net/wiki/Plugins_und_Skins_installieren">Skin- und Plugin-Installationsführer</a>.');
define('SUBMIT_SKIN', 'Wenn Sie gerne einen Skin auf dieser Seite zur Verfügung stellen würden, lesen Sie bitte die <a href="http://www.amsn-project.net/wiki/Dev:Plugins_und_Skins_vorschlagen">Anleitung zur Übermittlung eines Skins</a>.');
define('NO_SKIN', 'Es sind keine Skins verfügbar.');
define('CREATEDBY_SKIN', 'Erstellt von:');
define('VERSION_SKIN', 'Version:');
define('SCREENSHOTS_SKIN', 'Screenshot');
define('NOSCREEN_SKIN', 'Kein Screenshot');
define('DOWN_SKIN', 'Skin herunterladen');
define('DOWN_SOON_SKIN', 'Download bald verfügbar!');
define('BACK_TOP_SKIN', 'Zurück nach oben');
//skins.php definitions END

//plugins.php definitions START
define('FULL_FEATURES', 'aMSN hat viele Funktionen');
define('PLUGIN_DESC', ', aber Sie können die Funktionalität jetzt noch stärker erweitern, indem Sie neue Funktionen mit Hilfe von Plugins hinzufügen. Plugins sind einfache Erweiterungen, die an aMSN "andocken" und somit neue Funktionen zur Verfügung stellen können. Hier können Sie Plugins herunterladen, die von uns oder Mitwirkenden entwickelt wurden. Stellen Sie unbedingt sicher, dass Sie die richtige Version von aMSN, sowie das richtige Betriebssystem für das Plugin besitzen');
define('INSTALL_PLUGIN', 'Sie finden eine Anleitung, wie Sie ein Plugin installieren können, im <a href="http://www.amsn-project.net/wiki/Plugins_und_Skins_installieren">Skin- und Plugin-Installationsführer</a>.');
define('SUBMIT_PLUGIN', 'Wenn Sie gerne ein Plugin auf dieser Seite zur Verfügung stellen würden, lesen Sie bitte die <a href="http://www.amsn-project.net/wiki/Dev:Plugins_und_Skins_vorschlagen">Anleitung zur Übermittlung eines Plugins</a>.');
define('NO_PLUGINS', 'Es sind keine Plugins verfügbar.');
define('CREATEDBY_PLUGIN', 'Erstellt von:');
define('VERSION_PLUGIN', 'Version:');
define('PLATFORM_PLUGIN', 'Plattform/Betriebssystem:');
define('REQUIRES_PLUGIN', 'Voraussetzung(en): ');
define('SCREENSHOTS_PLUGIN', 'Screenshot');
define('NOSCREEN_PLUGIN', 'Kein Screenshot');
define('DOWN_PLUGIN', 'Plugin herunterladen');
define('DOWN_SOON_PLUGIN', 'Download bald verfügbar!');
define('BACK_TOP_PLUGIN', 'Zurück nach oben');
//plugins.php definitions END

//screenshots.php definitions START
define('NOSCREEN_SCREEN', 'Es sind keine Screenshots verfügbar.');
define('NOEXIST_SCREEN', 'Der ausgewählte Screenshot existiert nicht. Er könnte entfernt worden sein.');
//screeenshots.php definitions END

//docs.php definitions START
define('AMSN_DOCS', 'aMSN Dokumentation');
define('LINKS_DOCS', 'Links zur aMSN Dokumentation');
define('LINK_FAQ', 'FAQ');
define('LINK_USER_WIKI', 'Benutzer-Wiki');
//docs.php definitions END

//developer.php definitions START
define('AMSN_DEV_TEAM', 'aMSN Entwickler-Team');
define('DEV_DESC', 'Hier ist eine Liste an Leuten, die derzeit an aMSN arbeiten, oder dies in der Vergangenheit getan haben.');
define('CURRENT_DEVS_DEV', 'Derzeitige Entwickler');
define('PLEASE_HELP', 'Bitte helfen Sie');
define('HELP_DESC', 'Wenn Sie gerne an diesem Projekt mitwirken würden, hinterlassen Sie uns bitte eine Nachricht in unserem Forum unter:');
define('DONATION_DESC', 'Wenn Sie dem aMSN-Projekt eine Spende zukommen lassen wollen, finden Sie mehr Informationen darüber hier: ');
define('DONATIONS_DEV','Spenden');
define('AMSN_BUG_REPORT', 'aMSN Fehlerberichte');
define('BUGS_DESC', 'Wenn Sie bei der Benutzung von aMSN auf einen Fehler gestoßen sind, übermitteln Sie diesen bitte möglichst mit einer Beschreibung, wie dieser Fehler reproduziert werden kann, und einem Stack Trace im folgenden Forum. Bitte rechnen Sie mit weiteren Fragen zu dem Fehler und den Bedingungen, unter denen der Fehler aufgetreten ist.');
define('REPORT_BUG', 'Einen Fehler berichten');
define('PREV_BUG_REPORT', 'Vorherige Fehlerberichte');
define('AMSN_SVN', 'aMSN SVN');
define('SVN_DESC', 'Wenn Sie die immer auf dem neuesten Stand der aMSN-Entwicklung bleiben möchten, können Sie die neueste Entwickler-Version direkt aus unserem SVN-Verzeichnis bei Sourceforge herunterladen. SVN enthält neue Fehlerkorrekturen der letzten Version. Allerdings könnte diese Version nicht so stabil sein wie die neueste stabile Version.');
define('BROWSE_SVN', 'SVN-Verzeichnis durchsuchen');
define('SVN_HOWTO', 'Anleitung zur Installation der SVN-Version');
define('AMSN_TRANSLATE', 'aMSN Übersetzungen');
define('TRANSLATE_DESC', 'Wenn Sie eine Übersetzung für aMSN übermitteln wollen, schauen Sie auf: ');
//developer.php definitions END

//current-developer.php definitions START
define('CURRENT_DEVS', 'Derzeitige Entwickler :');
define('ROLE_DEV', 'Aufgabe: ');
define('ADMIN_DEV', 'Admin');
define('DEVELOPER_DEV', 'Programmierer');
define('MANAGER_DEV', 'Projektmanager');
define('INTER_DEV', 'Übersetzer');
define('LOCATION_DEV', 'Ort: ');
define('IRC_DEV', 'IRC Nick: ');
define('WEB_SITE', 'Homepage');
define('BLOG_DEV', 'Blog');
define('GAMES_PLUG_DEV', 'Games-Pluginpfleger');
define('RETIRED_WEB_DEV', 'Homepage-Entwickler im Ruhestand ');
define('FARSIGHT_DEV', ' Farsight Projektmanager');
define('GRAPHICS_DEV', 'Grafiken ');
define('SKIN_DEV', ' Skin Entwickler ');
define('WEB_DEV', ' Webdesigner');
define('UID_DEV', ' UI Entwickler ');
define('GRAPHART_DEV', ' Grafiker');
define('TESTER_DEV', ' Tester');
define('CONTRIBUTORS_DEV', 'Tester und Mitwirkende : ');
define('CODER_DEV', 'Coder');
define('PACKAGER_DEV', 'Paketbauer');
define('AMSN_STARTED_DEV', 'aMSN wurde angefangen von : ');
define('CCMSN_DEV', 'Erster Author von CCMSN (aMSN wurde von CCMSN abgeleitet)');
define('RETIRED_DEV', 'Entwickler im Ruhestand');
define('PEOPLE_HELPED_DEV', 'Leute, die auf dem Weg geholfen haben :');
define('PHP_CODER_DEV', 'PHP-Programmierer');
define('DATABASER_DEV', ' Datenbank-Entwickler');
define('RETIRED_PHP_DEV', 'PHP-Programmierer der alten Webseite ');
define('PLUGIN_MANAGER_DEV', 'Plugin-Verwalter ');
define('AMSN_PLUS_DEV', ' aMSN Plus Entwickler');
define('WIN_MAIN_DEV', ' Win Paketbauer ');
define('MAC_PORTER_DEV', 'Mac Portierer ');
define('MAINTAINER_DEV', ' Paketpfleger ');
//current-developer.php definitions end

//donatios.php definitions START
define('AMSN_DONATIONS_TITLE', 'aMSN Spenden:');
define('DONATION_DESC1', 'Manchmal wollen Benutzer den Entwicklern für die ganze Zeit und ihre Bemühungen zur Entwicklung eines erfolgreichen Projekts danken. Aus diesem Grund haben wir eine Möglichkeit eingerichtet, wo Sie den Entwicklern Ihrer Wahl etwas spenden können.');
define('DONATION_DESC2', 'aMSN selbst nimmt keine Spenden entgegen, aber falls Sie einem bestimmten Mitglied des aMSN Entwickler-Teams etwas spenden möchten, bieten wir Ihnen hier einige Links, über die Sie eben dies tun können:');
define('DONATE_TO', 'Spenden an : ');
define('BACK_TO_DEV', 'Zurück zur Entwickler-Seite');
//donations.php definitions END

//translations.php definitions START
define('TRANSLATION_TITLE', 'Registrieren Sie sich bei unserer Mailingliste!!');
define('MAIL_LIST_TRANS', 'Wir haben eine <a href="http://lists.sourceforge.net/lists/listinfo/amsn-lang">amsn-
lang Mailingliste</a> für Leute, die uns gerne helfen möchten.');
define('JOIN_TRANS', 'Um sich zu registrieren, gehen Sie einfach auf <a href="http://lists.sourceforge.net/lists/listinfo/amsn-lang">diese Seite</a>.');
define('NEW_SENTENCES_TRANS', 'Übersetzungsanfragen für neue Sätze werden auf diese Mailingliste geschickt, sodass jeder
sofort darauf antworten kann, und uns die Übersetzung senden kann.');
define('READ_THIS_TRANS', '<b>Wie Sie fehlende Übersetzungsschlüssel übersetzen, LESEN SIE DIES bevor Sie anfangen!</b><br/><br/>
FOLGENDE REGELN MÜSSEN BEFOLGT WERDEN:<br/></p>
<ul><li>Bitte lesen Sie die Datei <a href="https://amsn.svn.sourceforge.net/svnroot/amsn/trunk/amsn/lang/LANG-HOWTO"><b>LANG-HOWTO</b></a>.</li>');
define('READ_AGAIN_TRANS', '<li>Lesen Sie das LANG-HOWTO nochmal!</li>
<li>Klicken Sie auf den Link zu der Sprache, die Sie aktualisieren möchten (unten auf dieser Seite)
<br/><br/>Dann, auf der Seite, die sich öffnet :<br/><br/></li>
<li>Laden Sie die alte Übersetzungsdatei herunter ( der Link ist auf der Seite zu finden )</li>
<li>Fügen Sie die Übersetzungsschlüssel von der Liste am Ende der Seite
der Übersetzungsdatei hinzu.</li>
<li>Übersetzen Sie die englischen Sätze</li>');
define('SEND_UPDATE_TRANS', '<li>Senden Sie die aktualisierte Datei an <a href="mailto:amsn-translations@lists.sourceforge.net
">amsn-translations@lists.sourceforge.net</a></li>
<li>Wir akzeptieren NUR Übersetzungsdateien (lang-Dateien). Wir akzeptieren KEINE einfachen Übersetzungsschlüssel, die im
Fließtext der Email versendet werden, egal in welcher Form! Sie MÜSSEN die VOLLSTÄNDIGE Übersetzungsdatei 
(zum Beispiel langde für die deutsche Übersetzungsdatei) als ANHANG der Email schicken.</li>
<li>Wie bereits gesagt, Übersetzungsschlüssel, die im Fließtext einer Email gesendet werden, werden IGNORIERT und NICHT BEARBEITET.</li>
<li>Übersetzungsdateien, die an andere Email-Adressen außer 
amsn-translations@lists.sourceforge.net gesendet werden, werden ebenfalls IGNORIERT
und NICHT BEARBEITET.</li></ul>');
define('CAN_HELP_TRANS', '<br/>Sie können uns helfen, indem Sie einige Sätze in Ihre Sprache übersetzen, oder falsche Übersetzungen
korrigieren.<br/><br/>');
define('BE_CAREFUL', 'Seien Sie vorsichtig mit den Parametern $1, $2..., die in einigen Nachrichten vorkommen.
Sie können Ihre Position ändern, aber sie <b>müssen</b> im Satz vorkommen, da sie
bei der Ausführung mit anderen Werten ersetzt werden.<br/><br/><br/>');
define('NEW_LANG_TRANS', '
<b>Wie sie eine neue Sprache hinzufügen können</b><br/><br/>
<ul><li>Wählen Sie eine Abkürzung für Ihre Sprache (zum Beispiel Deutsch - de).</li>
<li>Laden Sie die englische Übersetzungsdatei <a href="https://amsn.svn.sourceforge.net/svnroot/amsn/trunk/amsn/lang/langen">hier</a> herunter.</li>
<li>Benennen Sie die Datei in langXX um, und ersetzen XX durch die von Ihnen gewählte Abkürzung.</li>
<li>Übersetzen Sie die Datei, ausgenommen das jeweils erste Wort in jeder Zeile (denn das ist der Übersetzungsschlüssel!).</li>
<li>Senden Sie die neue Datei an <a href="mailto:amsn-translations@lists.sourceforge.net">amsn-translations@lists.sourceforge.net</a></li>
</ul>');
//translations.php definitions END

//footer definition START
define('TRADEMARK_FOOT', 'Alle Logos und eingetragenen Warenzeichen auf dieser Seite sind Eigentum des jeweiligen Eigentümers.
      Kommentare und Newsbeiträge sind Eigentum des jeweiligen Autors, der ganze Rest 2002-2006 vom aMSN-Team.');
//footer definition END
//side_panels START
define('HOSTED_BY','Hosting von Oxilion');
define('LANGUAGE_SIDE','Sprache');
define('POLLS_SIDE','Umfrage');
define('POLL_SIDE_VOTE','Abstimmen');
define('POLL_SIDE_RESULTS','Ergebnis anzeigen');
define('FORUMS_SIDE','Forum');
define('AMSN_FORUMS','aMSN Forum');
define('RECENT_POSTS','Neueste Beiträge');
define('HELP_SIDE','Unterstützung');
define('HELP_BY_SIDE','Helfen Sie aMSN Entwicklern, indem Sie uns eine Spende zukommen lassen:');
define('DONATION_PAGE_SIDE','aMSN Spenden-Seite');
define('ADS_SIDE','Werbung');
define('LINKS_SIDE','Links');
define('INSTALLER_LINKS','Die Installationsprogramme wurden mit <a href="http://www.autopackage.org/">Autopackage</a> und <a href="http://nsis.sourceforge.net/">NSIS</a> erstellt');
define('SF_LINK','Sourceforge Projektseite');
//END

//linux-downloads page START
define('GENERIC_INSTALLER','Universelle Installationen');
define('AMSN_INSTALLER_TCL84','aMSN Installation für Tcl/Tk&nbsp;8.4');
define('INDEPENDENT_INSTALLER84','Distributionsunabhängige Installation für die, die <strong>bereits Tcl/Tk&nbsp;8.4 haben</strong>');
define('AMSN_INSTALLER_TCL85','aMSN Installation für Tcl/Tk&nbsp;8.5');
define('INDEPENDENT_INSTALLER85','Distributionsunabhängige Installation für die, die <strong>bereits Tcl/Tk&nbsp;8.5 haben</strong>');
define('CREATED_WITH_AUTO','Diese universellen Installationen wurden mit <a href="http://www.autopackage.org/">Autopackage</a> erstellt.
      Das ist eine neue Linux-Technologie um distributionsunabhängige Pakete mit einem Installationsprogramm
      <a href="http://www.autopackage.org/gallery.html">mit benutzerfreundlichem Aussehen</a> zu erstellen. Probieren Sie es selber aus !');
define('PLEASE_FOLLOW','Bitte folgen Sie den Anweisungen, um das Paket zu installieren.');
define('DISTRO_INC_AMSN','Distributionen, die aMSN ausliefern');
define('DISTRO_DESC_1','Die folgenden Distributionen haben aMSN bereits in ihrer Paketsammlung.
      Sie können aMSN also direkt mit Ihrem Paketmanager installieren, ohne es hier herunterladen zu müssen.');
define('DISTRO_DESC_2','Einige Distributionen liefern allerdings noch nicht die neueste Version aus.
      In diesem Fall empfehlen wir Ihnen, die <a href="#AP">aMSN Installationen</a> zu verwenden.');
define('OTHERWAY_TARBALL','Ein anderen Weg, aMSN zu installieren, falls alle anderen Wege fehlschlagen sollten, wäre den <a href="#tarball">Quellcode Tarball</a> zu installieren.');
define('SOURCE_DOWNLOADS','Quellcode Downloads');
define('AMSN_SOURCE','aMSN Quellcode');
define('BUILD_OWN_DISTRO','Quellcode-Paket, um eine Binärdatei für Ihre eigene Distribution zu erstellen.');
define('SOURCE_DESC_1','Sie können das Quellcode-Paket nutzen, um eine Binärdatei für Ihre eigene Distribution zu erstellen.
      Es ist auch möglich, RPM- oder DEB-Pakete, mit Hilfe des <span class="command">make rpm</span> oder <span class="command">make deb</span>
	  Befehls, abhängig von Ihrer Distribution, aus dem Quellcode-Paket zu erstellen.');
define('SOURCE_DESC_2','Bitte folgen Sie der <a href="http://amsn-project.net/wiki/Quellcode-Paket_installieren">Anleitung zur Installation</a> des Paketes.');
define('LATEST_DEV_TITLE','Neueste Entwickler-Version (SVN-Abbild)');
define('SVN_SNAPSHOT','SVN Abbild');
define('LATEST_DEV_SVN','Neueste Entwickler-Version (SVN-Abbild');
define('LATEST_DEV_DESC','Sie möchten unsere Entwickler-Version ausprobieren? Aber da es eine Entwickler-Version ist, könnte es mehr Fehler als die offiziellen Versionen enthalten, und könnte auch manchmal komplett unbrauchbar sein. Sie finden mehr Informationen, wie Sie diese Entwickler-Version installieren <a href="http://www.amsn-project.net/wiki/SVN_installieren">in unserem Wiki</a>');
//linux-downloads page END
//pool_results
define('POLL_NOT_EXIST','Die ausgewählte Umfrage existiert nicht. Vielleicht wurde sie gelöscht');
define('POLLS_VOTES','Stimmen');
define('TOTAL_NUMBER_VOTES','Gesamte Anzahl an Stimmen');
define('POLL_TO_MAIN','Zurück zur Hauptseite');
//pool_result END

?>
