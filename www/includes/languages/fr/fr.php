<?php
setlocale(LC_TIME, 'fr_FR.UTF8', 'fr.UTF8', 'fr_FR.UTF-8', 'fr.UTF-8');
define('TIME_FORMAT', 'Le %e %B %Y @ %H:%M:%S');
//header menu definitions START
define('HOME_MENU', 'Accueil');
define('DOWNLOAD_MENU', 'Téléchargements');
define('FEATURES_MENU','Fonctionnalités');
define('SKINS_MENU','Skins');
define('PLUGINS_MENU','Plugins');
define('SCREEN_MENU','Captures d\'écran');
define('DOCS_MENU','Docs/Aide');
define('DEV_MENU','Développement');
//header menu definitions END

// index.php definitions START
define('AMSN_DESC', '<strong>aMSN</strong> est un clone libre de MSN Messenger, avec des fonctionnalités telles que:
');
define('DESC_OFF_MSG', 'Messages différés');
define('VOICE_CLIP', 'Messages vocaux');
define('DISPLAY_PICS', 'Avatars');
define('CUSTOM_EMOS', 'Émoticônes personnalisées');
define('MULTI_LANG', 'Multilingue (environ 40 langues supportées actuellement)');
define('WEB_CAM_SUPPORT', 'Support de la Webcam');
define('SIGNIN_MORE', 'Peut se connecter à plus d\'un compte à la fois');
define('FSPEED_FTRANS', 'Transferts de fichier à pleine vitesse');
define('GROUP_SUPPORT', 'Support des groupes');
define('EMOS_WITH_SOUND', 'Émoticônes normales et animées avec sons');
define('CHAT_LOGS', 'Historiques de conversation');
define('TIMESTAMPING', 'Horodateur (Heure d\'envoi des messages)');
define('EVENT_ALARM', 'Alarmes d\'évènements');
define('CONFERENCE_SUPPORT', 'Support des conférences (chats à plusieurs)');
define('TABBED_CHAT', 'Fenêtres de conversation à onglets');
define('FOR_FULL_FEATURES', 'Pour une liste complète, regardez la <a href="features.php">page des fonctionnalités</a>. Des fonctionnalités supplémentaires peuvent être ajoutées à aMSN avec des <a href="plugins.php">plugins</a>, et son look peut être complétement changé avec des <a href="skins.php">skins</a> différents !');
define('DOWN_IMG','Télécharge aMSN');
define('PLUG_IMG','Get Plugins');
define('SKIN_IMG','Get Skins');
// index.php definitions END

//download.php definitions START
define('LINUX_DOWN', 'Linux');
define('WIN_DOWN', 'Windows');
define('WIN95_DOWN', 'Windows 95');
define('MACOSX_DOWN', 'Mac OS X(Universal)');
define('FREEBSD_DOWN', 'FreeBSD');
define('TARBALL_DOWN', 'Tarball Source');
define('LATEST_SVN','Dernière version de développement (Capture SVN du ');
//download.php definitions END

//features.php definitions START
define('AMSN_DESC_FEAT', '<strong>aMSN</strong> est un clone libre de MSN Messenger, avec des fonctionnalités telles que:');
define('OFF_MSG_FEAT', '&#187; Messages différés');
define('VOICE_CLIP_FEAT', '&#187; Messages vocaux');
define('NLW_FEAT', '&#187; Nouvelle fenêtre de connexion et liste de contacts (Depuis la version 0.97)');
define('DISPLAY_PICS_FEAT', '&#187; Avatars');
define('CUSTOM_EMOS_FEAT', '&#187; Émoticônes personnalisées');
define('MULTI_LANG_FEAT', '&#187; Multilingue (environ 40 langues supportées actuellement)');
define('SIGNIN_MORE_FEAT', '&#187; Peut se connecter à plus d\'un compte à la fois');
define('FTRANS_FEAT', '&#187; Transferts de fichier');
define('GROUP_SUPPORT_FEAT', '&#187; Support des groupes');
define('EMOS_WITH_SOUND_FEAT', '&#187; Émoticônes normales et animées avec sons');
define('CHAT_LOGS_FEAT', '&#187; Historiques de conversation');
define('EVENT_ALARM_FEAT', '&#187; Alarmes d\'évènements');
define('CONFERENCE_SUPPORT_FEAT', '&#187; Support des conférences (chats à plusieurs)');
define('WEB_CAM_SUPPORT_FEAT', '&#187; Support de la Webcam');
define('HISTORY_FEAT', '&#187; Historique coloré');
define('AUTOCLOSE_FEAT', '&#187; Possibilité de fermer automatiquement la fenêtre de transfert de fichier lorsque le transfert est terminé');
define('PLUGIN_WIN_FEAT', ' &#187; Nouveau : Fenêtre de log des plugins (Alt-P)');
define('PLUGIN_COMP_FEAT', '&#187; Plugins compatibles avec les langues supportées');
define('SKIN_WIN_FEAT', '&#187; Chargement de la fenêtre des skins plus rapide');
define('SKINS_CHAT_FEAT', '&#187; Skins dans la fenêtre de conversation');
define('WIN_BOTTOM_FEAT', '&#187; Bas de la fenêtre de conversation redimensionnable');
define('NEW_USER_GROUP_FEAT', '&#187; Lorsque vous ajouter un nouveau contact, vous pouvez définir dans quel groupe l\'ajouter');
define('CHAT_WIN_COLOR_FEAT', '&#187; Lorsqu\'un contact change de statut, le haut de la fenêtre de conversation change de couleur (vert pour absent, gris pour hors ligne ...)');
define('VERSION_ALERT_FEAT', '&#187; Notification des nouvelles versions de aMSN');
define('DOWN_RELEASE_FEAT', '&#187; Possibilitée de télécharger la nouvelle version directement par aMSN');
define('AUTO_UPDATE_FEAT', '&#187; Mise à jour automatique des langues et plugins par le Web');
define('DEL_USER_GUI_FEAT', '&#187; Nouvelle fenêtre de suppression de contacts (possiblité de bloquer à la suppression)');
define('USER_NOTES_FEAT', '&#187; Possiblité d\'ajouter des notes pour chaque contact (XML)');
define('MSN_MOBILE_FEAT', '&#187; Support du service MSN Mobile');
define('TABBED_WIN_FEAT', '&#187; Fenêtres à onglets pour que vous puissiez grouper les conversations en utilisant des onglets');
define('STATUS_APPEAR_FEAT', '&#187; Le statut est affiché dans un cadre pour qu\'il ne disparaisse pas lorsque vous défilez');
define('ALERT_PICTURE_FEAT', '&#187; Avatar dans les fenêtres de notification (comme MSN 7)');
define('HISTORY_STATS_FEAT', '&#187; Statistiques des historiques');
define('LOGIN_STATUS_FEAT', '&#187; Maintenant possible de choisir n\'importe quel statut à la connexion (avant il n\'était possible de se connecter qu\'en invisible ou en ligne)');
define('TIMESTAMPING_FEAT', '&#187; Horodateur (Heure d\'envoi des messages)');
define('MORE_FEAT', 'Mais ce n\'est pas tout ! Des fonctionnalités supplémentaires peuvent être ajoutées à aMSN avec des <a href="plugins.php">plugins</a>, et, pour les aventuriers, son look peut être complétement changé avec des <a href="skins.php">skins</a> différents !');
//features.php definitions END

//skins.php definitions START
define('LOVES_CUSTOM', '<strong>aMSN adore la personnalisation !</strong>');
define('SKIN_DESC', ', et une des manières de le personnaliser est de changer son "skin". Un skin change le look de aMSN. Vous pouvez télécharger ici des skins développés par aMSN et par des contributeurs.');
define('INSTALL_SKIN', 'Vous pouvez trouver des indications sur comment installer des skins dans notre <a href="http://www.amsn-project.net/wiki/Installing_Plugins_and_Skins">guide d\'installation de skins et plugins</a> (en anglais).');
define('SUBMIT_SKIN', 'Si vous désirez proposer votre skin pour cette page, veuillez lire le <a href="http://www.amsn-project.net/wiki/Dev:Sumbitting_Plugins_and_Skins">guide d\'envoi de skins</a> (en anglais).');
define('NO_SKIN', 'Aucun skin n\'est disponible.');
define('CREATEDBY_SKIN', 'Créé par :');
define('VERSION_SKIN', 'Version :');
define('SCREENSHOTS_SKIN', 'Capture d\'écran');
define('NOSCREEN_SKIN', 'Aucune capture d\'écran');
define('DOWN_SKIN', 'Télécharger ce skin');
define('DOWN_SOON_SKIN', 'Téléchargement bientôt disponible !');
define('BACK_TOP_SKIN', 'Retour en haut');
//skins.php definitions END

//plugins.php definitions START
define('FULL_FEATURES', 'aMSN est plein de fonctionnalités');
define('PLUGIN_DESC', ', mais vous pouvez les augmenter encore plus maintenant, obtenant des fonctionnalités supplémentaires en installant des plugins. Les plugins se "greffent" à aMSN et lui donnent des fonctionnalités supplémentaires. Vous pouvez télécharger ici des plugins développés par nous et par des contributeurs. Assurez vous d\'avoir la bonne version d\'aMSN pour le plugin (vérifiez la case "requiert") et le bon système d\'exploitation (vérifiez la "platforme")');
define('INSTALL_PLUGIN', 'Vous pouvez trouver des indications sur comment installer des plugins dans notre <a href="http://www.amsn-project.net/wiki/Installing_Plugins_and_Skins">guide d\'installation de skins et plugins</a> (en anglais).');
define('SUBMIT_PLUGIN', 'Si vous désirez proposer votre skin pour cette page, veuillez lire le <a href="http://www.amsn-project.net/wiki/Dev:Sumbitting_Plugins_and_Skins">guide d\'envoi de skins</a> (en anglais).');
define('NO_PLUGINS', 'Aucun plugin n\'est disponible');
define('CREATEDBY_PLUGIN', 'Créé par :');
define('VERSION_PLUGIN', 'Version :');
define('PLATFORM_PLUGIN', 'Platforme/Système d\'exploitation :');
define('REQUIRES_PLUGIN', 'Requiert : ');
define('SCREENSHOTS_PLUGIN', 'Capture d\'écran');
define('NOSCREEN_PLUGIN', 'Aucune capture d\'écran');
define('DOWN_PLUGIN', 'Télécharger ce plugin');
define('DOWN_SOON_PLUGIN', 'Téléchargement bientôt disponible !');
define('BACK_TOP_PLUGIN', 'Retour en haut');
//plugins.php definitions END

//screenshots.php definitions START
define('NOSCREEN_SCREEN', 'Aucune capture d\'écran n\'est disponible.');
define('NOEXIST_SCREEN', 'La capture d\'écran sélectionnée n\'existe pas. Elle a peut-être été supprimée.');
//screeenshots.php definitions END

//docs.php definitions START
define('AMSN_DOCS', 'Documents aMSN');
define('LINKS_DOCS', 'Liens vers les documents aMSN');
define('LINK_FAQ', 'FAQ');
define('LINK_USER_WIKI', 'Wiki Utilisateurs');
//docs.php definitions END

//developer.php definitions START
define('AMSN_DEV_TEAM', 'Équipe de développement de aMSN ');
define('DEV_DESC', 'Voici une liste de personnes qui travaillent actuellement ou ont travaillé par le passé sur aMSN.');
define('CURRENT_DEVS_DEV', 'Développeurs actuels');
define('PLEASE_HELP', 'Aidez s\'il vous plait');
define('HELP_DESC', 'Si vous voulez contribuer à ce projet, veuillez laisser un message sur notre forum ici :');
define('DONATION_DESC', 'Si vous voulez faire un don au projet aMSN, vous pouvez trouver plus d\'informations à ce sujet ici : ');
define('DONATIONS_DEV','Page des dons à aMSN');
define('AMSN_BUG_REPORT', 'Reports de bug de aMSN');
define('BUGS_DESC', 'Si vous rencontez un bug en utilisant aMSN, veuillez s\'il vous plait le reporter avec les détails sur comment le reproduire et éventuellement les messages de logs sur le forum suivant. Attendez vous aussi à des questions supplémentaires à propos du bug et de l\'environnement dans lequel il s\'est produit.');
define('REPORT_BUG', 'Reporter un Bug');
define('PREV_BUG_REPORT', 'Reports de bug précédents');
define('AMSN_SVN', 'aMSN SVN');
define('SVN_DESC', 'SI vous voulez être à la pointe, vous pouvez télécharger notre version de développement la plus récente directement de notre SVN sourceforge. Le SVN contient de nouvelles corrections de bugs depuis les dernières versions. D\'un autre coté, il pourrait ne pas etre aussi stable que la dernière version stable.');
define('BROWSE_SVN', 'Parcourir le répertoire SVN');
define('SVN_HOWTO', 'Instructions pour installer la version SVN');
define('AMSN_TRANSLATE', 'Traductions de aMSN');
define('TRANSLATE_DESC', 'Si vous avez une traduction à envoyer pour aMSN, veuillez visiter : ');
//developer.php definitions END

//current-developer.php definitions START
define('CURRENT_DEVS', 'Développeurs actuels :');
define('ROLE_DEV', 'Rôle: ');
define('ADMIN_DEV', 'Admin');
define('DEVELOPER_DEV', 'Développeur');
define('MANAGER_DEV', 'Project Manager');
define('INTER_DEV', 'Internationalisation');
define('LOCATION_DEV', 'Emplacement: ');
define('IRC_DEV', 'Pseudo IRC: ');
define('WEB_SITE', 'Site Web');
define('BLOG_DEV', 'Blog');
define('GAMES_PLUG_DEV', 'Mainteneur du plugin Games (Jeux)');
define('RETIRED_WEB_DEV', 'Ancien Développeur Web ');
define('FARSIGHT_DEV', ' Manager du projet Farsight');
define('GRAPHICS_DEV', 'Graphismes ');
define('SKIN_DEV', ' Designer de Skin ');
define('WEB_DEV', ' Web Designer');
define('UID_DEV', ' Designer de l\'Interface Utilisateur ');
define('GRAPHART_DEV', ' Artiste graphique');
define('TESTER_DEV', ' Testeur');
define('CONTRIBUTORS_DEV', 'Testeurs et contributeurs : ');
define('CODER_DEV', 'Codeur');
define('PACKAGER_DEV', 'Packageur');
define('AMSN_STARTED_DEV', 'aMSN a été commencé par : ');
define('CCMSN_DEV', 'auteur original de CCMSN (aMSN est dérivé de CCMSN)');
define('RETIRED_DEV', 'Ancien Développeur');
define('PEOPLE_HELPED_DEV', 'Personnes ayant aidé au cours du chemin :');
define('PHP_CODER_DEV', 'Codeur PHP');
define('DATABASER_DEV', ' Développeur de la Base de Données');
define('RETIRED_PHP_DEV', 'Codeur PHP pour l\'ancien site Web ');
define('PLUGIN_MANAGER_DEV', 'Plugin Manager ');
define('AMSN_PLUS_DEV', ' Développeur de aMSN Plus');
define('WIN_MAIN_DEV', ' Mainteneur Windows ');
define('MAC_PORTER_DEV', 'Créateur du port Mac ');
define('MAINTAINER_DEV', ' Mainteneur ');
//current-developer.php definitions end

//donatios.php definitions START
define('AMSN_DONATIONS_TITLE', 'Dons à aMSN:');
define('DONATION_DESC1', 'Des fois, des utilisateurs veulent remercier les développeurs pour tout le temps et les efforts consacrés au développement d\'un projet réussi. Pour cette raison, nous avons mis en place un endroit où vous pouvez donner à des développeurs en particulier.');
define('DONATION_DESC2', 'aMSN en tant qu\'ensemble n\'accepte pas les dons, mais si vous voulez remercier un membre en particulier de l\'équipe de développement de aMSN, nous vous fournissons ces liens pour que vous puissiez le faire :');
define('DONATE_TO', 'Donner à : ');
define('BACK_TO_DEV', 'Retour à la page des développeurs');
//donations.php definitions END

//translations.php definitions START
define('TRANSLATION_TITLE', 'Rejoigner notre liste de diffusion mail !');
define('MAIL_LIST_TRANS', 'Nous avons une <a href="http://lists.sourceforge.net/lists/listinfo/amsn-lang"> liste de diffusion mail amsn-lang</a> disponible pour les personnes souhaitant nous aider.');
define('JOIN_TRANS', 'Vous pouvez la rejoindre en visitant <a href="http://lists.sourceforge.net/lists/listinfo/amsn-lang">cette page</a>.');
define('NEW_SENTENCES_TRANS', 'Les demandes de traductions de nouvelles phrases seront envoyées à cette liste, pour que n\'importe qui puisse répondre instantanément et nous envoyer la traduction.');
define('READ_THIS_TRANS', '<b>Comment traduire les phrases manquantes, veuillez LIRE ÇA avant de traduire !</b><br/><br/>
RÈGLES DEVANT ÊTRE SUIVIES :<br/></p>
<ul><li>Veuillez lire le fichier <a href="https://amsn.svn.sourceforge.net/svnroot/amsn/trunk/amsn/lang/LANG-HOWTO"><b>LANG-HOWTO</b></a>.</li>');
define('READ_AGAIN_TRANS', '<li>Lisez LANG-HOWTO encore!</li>
<li>Cliquer simplement sur le lien du langage que vous voulez mettre à jour (en bas de cette page)
<br/><br/>Puis, dans la page qui s\'ouvre :<br/><br/></li>
<li>Téléchargez l\'ancien fichier de langue (vous trouverez le lien dans la page)</li>
<li>Ajoutez les mots clés depuis la liste au bas de la page
au fichier de langue.</li>
<li>Traduisez les explications anglaises</li>');
define('SEND_UPDATE_TRANS', '<li>Envoyez le fichier mis à jour à <a href="mailto:amsn-translations@lists.sourceforge.net
">amsn-translations@lists.sourceforge.net</a></li>
<li>Nous n\'accepterons QUE les fichiers de langue langfiles. Nous n\'accepterons PAS
les mots clés seuls reçus dans le corps de l\'e-mail. Vous DEVEZ envoyer
le ficher de langue langfile COMPLET (par exemple, langit si vous êtes italien, ou langfr pour le français)
JOINT à l\'e-mail.</li>
<li>Comme indiqué ci-dessus, les clés envoyés dans le corps de l\'e-mail seront IGNORÉES et ABANDONNÉES.</li>
<li>Les Langfiles envoyées à des adresses e-mail autres que
amsn-translations@lists.sourceforge.net seront aussi IGNORÉES
et ABANDONNÉES.</li></ul>');
define('CAN_HELP_TRANS', '<br/>Vous pouvez nous aider en traduisant certaines phrases vers votre langue, ou en modifiant
les phrases mal traduites.<br/><br/>');
define('BE_CAREFUL', 'Faites attention avec les paramètres $1, $2... qui apparaissent dans certaines expressions.
Vous pouvez changer leur position, mais ils <b>doivent</b> apparaître dans la phrase, ils
seront
substitués durant l\'exécution par des valeurs.<br/><br/><br/>');
define('NEW_LANG_TRANS', '
<b>Comment ajouter une nouvelle langue</b><br/><br/>
<ul><li>Choisissez un identifiant court pour votre langue (par exemple français - fr).</li>
<li>Téléchargez le fichier de langue anglais <a href="https://amsn.svn.sourceforge.net/svnroot/amsn/trunk/amsn/lang/langen">ici</a>.</li>
<li>Renommez le fichier langXX avec XX étant l\'identifiant que vous avez choisi</li>
<li>Traduisez le fichier, à l\'exception du premier mot de chaque ligne (c\'est la clé).</li>
<li>Envoyez le nouveau fichier à l\'adresse <a href="mailto:amsn-translations@lists.sourceforge.net">amsn-translations@lists.sourceforge.net</a></li>
</ul>');
//translations.php definitions END

//footer definition START
define('TRADEMARK_FOOT', 'Tous les logos et marques dans ce site sont propriétés de leur propriétaires
      respectifs. Les commentaires et informations sont propriétés de ceux les ayant postés, tout
      le reste 2002-2006 par l\'équipe aMSN.');
//footer definition END
//side_panels START
define('HOSTED_BY','Hébergé par Oxilion');
define('LANGUAGE_SIDE','Langue');
define('POLLS_SIDE','Sondages');
define('POLL_SIDE_VOTE','Vote');
define('POLL_SIDE_RESULTS','Voir les résultats');
define('FORUMS_SIDE','Forums');
define('AMSN_FORUMS','Forums aMSN');
define('RECENT_POSTS','Messages récents');
define('HELP_SIDE','Aidez SVP');
define('HELP_BY_SIDE','Aidez les développeurs de aMSN en envoyant un don :');
define('DONATION_PAGE_SIDE','Page des dons à aMSN');
define('ADS_SIDE','Publicité');
define('LINKS_SIDE','Liens');
define('INSTALLER_LINKS','Installateurs créés avec <a href="http://www.autopackage.org/">Autopackage</a> et <a href="http://nsis.sourceforge.net/">NSIS</a>');
define('SF_LINK','Page SourceForge du projet');
//END

//linux-downloads page START
define('GENERIC_INSTALLER','Installateurs génériques');
define('AMSN_INSTALLER_TCL84','Installateur aMSN pour Tcl/Tk&nbsp;8.4');
define('INDEPENDENT_INSTALLER84','Installateur indépendant de la distribution Linux pour ceux qui ont <strong>déjà</strong> Tcl/Tk&nbsp;8.4');
define('AMSN_INSTALLER_TCL85','Installateur aMSN pour Tcl/Tk&nbsp;8.5');
define('INDEPENDENT_INSTALLER85','Installateur indépendant de la distribution Linux pour ceux qui ont <strong>déjà</strong> Tcl/Tk&nbsp;8.5 <strong>en version finale</strong>');
define('CREATED_WITH_AUTO','Ces installateurs génériques ont été créés avec <a href="http://www.autopackage.org/">Autopackage</a>.
      C\'est une nouvelle technologie Linux pour créer des packages indépendants de la distribution,
      avec un installateur <a href="http://www.autopackage.org/gallery.html">ayant un look attirant. Vérifiez vous même !</a>.');
define('PLEASE_FOLLOW','Veuillez suivre les instructions pour installer le package.');
define('DISTRO_INC_AMSN','Distributions incluant aMSN');
define('DISTRO_DESC_1','Les distributions suivantent incluent déjà aMSN dans leur collections de packages.
      Vous pouvez installer directement aMSN avec votre gestionnaire de Packages, sans avoir à le télécharger ici.');
define('DISTRO_DESC_2','Néanmoins, certaines distributions peuvent ne pas encore fournir la dernière version.
      Dans ce cas, il est recommandé d\'utiliser <a href="#AP">l\'installateur d\'aMSN.</a>');
define('OTHERWAY_TARBALL','Une autre façon d\'installer amsn si toutes les autres échouent est d\'installer la <a href="#tarball">source tarball</a>.');
define('SOURCE_DOWNLOADS','Code Source Téléchargements');
define('AMSN_SOURCE','Code source d\'aMSN');
define('BUILD_OWN_DISTRO','Package source pour compiler un binaire pour votre propre distribution.');
define('SOURCE_DESC_1','Vous pouvez utiliser le package source pour compiler un binaire pour votre distribition Linux.
      Il est aussi possible de créer des packages RPM ou DEB depuis le package source,
      en utilisant la commande <span class="command">make rpm</span> ou <span class="command">make deb</span> appropriée selon votre distribution.');
define('SOURCE_DESC_2','Veuillez suivre <a href="http://amsn-project.net/wiki/Installing_Tarball">ces instructions</a> (en anglais) pour installer le package.');
define('LATEST_DEV_TITLE','Latest development version (SVN Snapshot)');
define('SVN_SNAPSHOT','Capture SVN');
define('LATEST_DEV_SVN','Dernière version de développement (Capture SVN');
define('LATEST_DEV_DESC','Vous pourriez vouloir tester notre version de développement. Mais, comme c\'est une version de développement, elle peut contenir plus de bugs que les versions officielles, et peut même être des fois complétement non fonctionnelle. Vous trouverez plus d\'informations sur comment installer cette version de développement <a href="http://amsn-project.net/wiki/Installation_de_la_version_SVN">sur notre wiki</a>');
//linux-downloads page END
//pool_results
define('POLL_NOT_EXIST','Le sondage sélectionnés ne existe pas. Peut-être ils ont été enlevés');
define('POLLS_VOTES','Votes');
define('TOTAL_NUMBER_VOTES','Nombre total de votes');
define('POLL_TO_MAIN','Retour à la page d\'Accueil');
//pool_result END
?>