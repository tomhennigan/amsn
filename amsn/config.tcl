
::Version::setSubversionId {$Id$}

package require des

namespace eval ::config {

	proc configDefaults {} {
		global password auto_path advanced_options custom_emotions osspecific_keys locale_codes

		::config::setKey nossl 0			;#Disable the use of SSL, so it doesn't requite TLS package: 0|1

		::config::setKey login ""			;# These are defaults for users without
		::config::setKey save_password 0		;# a config file: 0|1

		::config::setKey keep_logs 1			;#Save log files: 0|1
		::config::setKey display_event_connect 1	;#Display when someone connect
		::config::setKey display_event_disconnect 1	;#Display when someone disconnect
		::config::setKey display_event_email 1	;#Display when a new E-Mail is received
		::config::setKey display_event_state 0	;#Display changement of status
		::config::setKey display_event_nick 0	;#Display changement of status
		::config::setKey display_event_psm 0	;#Display changement of status
		::config::setKey log_event_connect 0		;#Log when someone connect
		::config::setKey log_event_disconnect 0	;#Log when someone disconnect
		::config::setKey log_event_email 0		;#Log when a new E-Mail is received
		::config::setKey log_event_state 0		;#Log changement of status
		::config::setKey log_event_nick 0		;#Log changement of status
		::config::setKey log_event_psm 0		;#Log changement of status

		::config::setKey connectiontype direct	;# Connection type: direct|http|proxy
		::config::setKey proxy ""			;# If using proxy, proxy host
		::config::setKey proxytype "http"		;# Proxy type: http|ssl|socks5
		::config::setKey proxyauthenticate 0		;# SOCKS5 use username/password
		::config::setKey proxyuser ""		;# user and password for SOCKS5 proxy
		::config::setKey proxypass ""		;#

		::config::setKey sound 1			;#Sound enabled: 0|1
		::config::setKey mailcommand ""		;#Command for checking mail. Blank for hotmail
		::config::setKey notifytyping 1		;#Send typing notifications
		::config::setKey soundactive 0               ;#Typing sound even on active window

		::config::setKey chatstyle	"msn"		;#Chat display style

		::config::setKey reconnect 1			;#Variable for amsn to reconnect on loss

		::config::setKey dock 1				;#Docking type
								;#Changed later for windows to 4
		::config::setKey showmailicon 1
		::config::setKey use_tray 1
		::config::setKey ShowButtonBar 1
		::config::setKey show_contactdps_in_cl 0		

		::config::setKey autoresizedp 0

		::config::setKey lowrescam 0

		::config::setKey playbackspeed 100

		::config::setKey cam_in_cw 0

		#Dir for received files
		if { [OnDarwin] } {
		        ::config::setKey receiveddir "[file join $::env(HOME) Desktop]"
		} elseif { [OnUnix] } {
			::config::setKey receiveddir "[file join $::env(HOME) amsn_received]"
		} elseif { [OnWin] } {
			if {[info exists env(USERPROFILE)]} {
				::config::setKey receiveddir "[file join $::env(USERPROFILE) amsn_received]"
			} else {
				::config::setKey receiveddir "[file join [pwd] amsn_received]"
			}
		} else {
			::config::setKey receiveddir "[file join [pwd] amsn_received]"
		}

		#Some Autodetected options
		if { [OnDarwin] } {
			::config::setKey soundcommand "./utils/macosx/sndplay \$sound";#Soundplayer for Mac OS 10.3-10.4	
			::config::setKey browser "open \$url"
			::config::setKey notifyXoffset 100
			::config::setKey notifyYoffset 75
			::config::setKey filemanager "open \$location"
			::config::setKey openfilecommand "open \$file"
			::config::setKey usesnack 0

			::config::setKey os "mac"
		} elseif { [OnUnix] } {
			::config::setKey soundcommand "play \$sound"
			::config::setKey browser "xdg-open \$url"
			::config::setKey notifyXoffset 0
			::config::setKey notifyYoffset 0
			::config::setKey filemanager "xdg-open \$location"
			::config::setKey openfilecommand "xdg-open \$file"
			::config::setKey usesnack 0

			::config::setKey os "unix"
		} elseif { [OnWin] } {
			::config::setKey soundcommand "utils/windows/plwav.exe \$sound"
			::config::setKey browser "explorer \$url"
			::config::setKey notifyXoffset 0
			::config::setKey notifyYoffset 28
			::config::setKey filemanager "explorer \$location"
			::config::setKey openfilecommand "start \$file"
			::config::setKey usesnack 1
			#::config::setKey dock 4				;#Set docking to type 4 (windows)
			
			::config::setKey os "win"
		} else {
			::config::setKey soundcommand ""			;#Sound player command
			::config::setKey browser ""			;#Browser command
			::config::setKey filemanager ""			;#Filemanager command
			::config::setKey openfilecommand ""
			::config::setKey notifyXoffset 0			;#Notify window offsets
			::config::setKey notifyYoffset 0
			::config::setKey usesnack 0			;#Use the Snack library for sounds
			
			::config::setKey os "other"
		}

		::config::setKey autoidle 1				;#Enable/disable auto-idle feature: 0|1
		::config::setKey idletime 5				;#Minutes before setting status to idle
		::config::setKey autoaway 1				;#Enable/disable auto-away feature: 0|1
		::config::setKey awaytime 10				;#Minutes before setting status to away

		::config::setKey orderusersincreasing 1
		::config::setKey orderusersbystatus 1
		::config::setKey orderusersbylogsize 0

		::config::setKey orderbygroup 2			;#Order contacts by group: 0=No | 1=Groups | 2=Hybrid
		::config::setKey ordergroupsbynormal 1		;#Order groups normal or inverted

		::config::setKey dateformat MDY			;#Change date format (eg Month/Day/Year)

		::config::setKey listsmileys 1			;#Show smileys in contact list
		::config::setKey chatsmileys 1			;#Show smileys in chat window

		::config::setKey startoffline 0			;#Start session as offline (hidden)

		::config::setKey autoftip 1				;#Detect IP for file transfers automatically
		::config::setKey myip "127.0.0.1"			;#Your IP
		::config::setKey manualip "127.0.0.1"		;#Manual IP


		#Specific configs for Mac OS X (Aqua) first, and for others systems after
		if { [OnMac] } {
			::config::setKey wingeometry 300x650+2+25		;#Main window geometry on Mac OS X
			::config::setKey backgroundcolor  #ECECEC		;#AMSN Mac OS X background color
			::config::setKey dockbounce once					;#Dock bouncing on Mac OS X
		} else {
			::config::setKey wingeometry 350x600-0+0			;#Main window geometry
			::config::setKey backgroundcolor  #D8D8E0		;#AMSN background color
		}

		::config::setKey closingdocks 0						;#Close button minimizes (or docks) main window

		::config::setKey encoding auto						;#ANSN encoding

		::config::setKey textsize 2							;#User text size
		::config::setKey mychatfont "{Helvetica} {} 000000"	;#User chat font
		::config::setKey winchatsize "350x320"		;#Default chat window size
		::config::setKey winchatoutheight "200"		;#Default chat window output height
		::config::setKey savechatwinsize 1			;#Save chat window sizes when changed?
		
		::config::setKey notifyonlysound 0			;#Only play sound for notification : no notify window
		::config::setKey notifymsg 1				;#Show notify window when a message arrives
		::config::setKey notifyonline 1			;#Show notify window when a user goes online
		::config::setKey notifyoffline 0			;#Show notify window when a user goes offline
		::config::setKey notifystate 0			;#Show notify window when a user changes status
		::config::setKey notifyemail 1			;#Show notify window when a new mail arrives
		::config::setKey notifyemailother 0			;#Show notify window when a new mail arrives in other folders

		#Specific for Mac OS X, if newchatwinstate=1, new windows of message never appear
		if { [OnMac] } {
			::config::setKey newchatwinstate 0		;#Iconify or restore chat window on new chat
			::config::setKey newmsgwinstate 0		;#Iconify or restore chat window on new message
		} else {
			::config::setKey newchatwinstate 1		;#Iconify or restore chat window on new chat
			::config::setKey newmsgwinstate 1		;#Iconify or restore chat window on new message
		}

		::config::setKey flicker 1				;#Flicker window on new message
		::config::setKey showdisplaypic 1		;#Show display picture as default
		::config::setKey ShowTopPicture 1		;#Show display picture in the top frame
		::config::setKey old_dpframe 0			;# Use the old DP framing system (only one in the bottom)
		::config::setKey lazypicretrieval 0		;#Retrieve display pics in a lazy way, only when chatting to that user

		::config::setKey autochangenick 1		;# automaticly change nick to custom state

		::config::setKey initialftport 6891	;#Initial for to be used when sending file transfers
		::config::setKey ftautoaccept 0		;#Auto-Accept file transfer request (Off by default)
		::config::setKey ftautoclose 0		;#Auto-close file transfer windows when finished

		::config::setKey shownotify 1 			;#Show notify window (in general, see advanced options)
		::config::setKey clientcaps 1			;#Send x-clientcaps information to others 3rd Messenger
		#Remote control options
		::config::setKey enableremote 0
		::config::setKey remotepassword ""

		#Blocking detection options
		::config::setKey checkonfln 0
		::config::setKey checkblocking 0
		::config::setKey blockinter1 60
		::config::setKey blockinter2 300
		::config::setKey blockinter3 5
		::config::setKey blockusers 2
		::config::setKey showblockedgroup 0

		::config::setKey wanttosharecam 0

		::config::setKey emotisounds 1			;#Play sound on certain emoticons
		::config::setKey animatedsmileys 1		;#Show animated smileys
		::config::setKey customsmileys 1                ;#Show other people s custom smileys

		#Custom smileys configuration
		::config::setKey logsbydate 1
		::config::setKey p4c_name ""
		::config::setKey tabbedchat 2
		::config::setKey ContainerCloseAction 0
		::config::setKey showMobileGroup 1
		::config::setKey chatWindowsCloseAfterLogout 0

		::config::setKey noftpreview 0

		# Show/hide menu feature
		::config::setKey showmainmenu -1
		::config::setKey showcwmenus -1

		::config::setKey tooltips 1				;#Enable/disable tooltips
		::config::setKey animatenotify 1		;#Animate notify window
		::config::setKey disableuserfonts 0	;#Disable custom fonts for other users (use always yours).
		::config::setKey autoconnect 0			;#Automatically connect when amsn starts
		::config::setKey libtls_temp ""			;#TLS
		::config::setKey lineflushlog 1			;#Flush log files after each line
		::config::setKey autocheckver 1			;#Automatically check for newer versions on startup
		::config::setKey truncatenames 1		;#Truncate nicknames longer than window width in windows' title
		::config::setKey truncatenicks 0		;#Truncate nicknames longer than window width in chat windows
		::config::setKey keepalive 1				;#Keep alive connection (ping every minute)
		::config::setKey showtimestamps 1		;#Show timestamps on messages ("Yes" by default)
		::config::setKey leftdelimiter \[		;#Left Timestamps' delimiter  '[' by default
		::config::setKey rightdelimiter \]		;#Right Timestamps' delimiter ']' by default
		::config::setKey default_ns_server "messenger.hotmail.com:1863"
		::config::setKey start_ns_server "messenger.hotmail.com:1863"
		::config::setKey default_gateway_server "gateway.messenger.hotmail.com"
		::config::setKey start_gateway_server "gateway.messenger.hotmail.com"		
		::config::setKey activeautoupdate 1		;#Active the auto update
		::config::setKey allowbadwords 1		;#Disable censure on nicks
		::config::setKey enablebanner 1		;#Show or Hide AMSN Banner (By default Show)
		::config::setKey startontray 0		;#Start amsn on tray icon only (hide contact list)
		::config::setKey storename 1			;#Store original nick in a variable when go to custom states to revert it when go back
		::config::setKey strictfonts 0		;#Use strict fonts' size in _ALL_ AMSN's fonts (Disabled by default)
		::config::setKey sngdblclick 0		;#Use single or double click to open a message window (0 double, 1 single)
		::config::setKey nogap 0			;#Remove the empty line between groups
		::config::setKey removeempty 0		;#Remove empty groups from the contact list
		::config::setKey tabtitlenick 1		;#Whether nick or mail is displayed in the tab
		::config::setKey showpicnotify 1		;#Whether we show users pictures (if we have them) on the notify windows
		::config::setKey emailsincontactlist 0	;#Display emails instead of nicks in the contact list
		::config::setKey leavejoinsinchat	1	;#Display leave/join notifications in chat text area
		::config::setKey charscounter	1	;#Display typed characters counter
		::config::setKey checkemail	1	;#Show inbox email notification line
		::config::setKey recentmsg 0		;#Recent message window closing protection
		::config::setKey displayp4context 1	;#Accept P4-Context fieds
		::config::setKey p4contextprefix "" ; #Prefix for P4-Context messages
		::config::setKey notifytimeout 8000 ; #Number of milisecs before the notify will go away
		::config::setKey globalnick ""		;#The global custom nickname (pattern), disabled by default
		::config::setKey contentroaming 1
		
		#The place where must be shown the PSM (0: not shown, 1: At the end, 2: In a new line)
		if {[OnMac]} {
			::config::setKey psmplace 2
		} else {
			::config::setKey psmplace 1
		}
		
		::config::setKey globaloverride 0		;# Sets whether Global nicknames pattern should override custom nicks, disabled by default

		if { [info exists custom_emotions] } {
			::smiley::UnloadEmoticons
		}
		::smiley::cleanup

		#System options, not intended to be edited (unless you know what you're doing)
		set password ""
		::config::setKey withnotebook 0			;#Use notebook tabs in contact list

		::config::setKey adverts 0				;#Enable banner advertisements
		::config::setKey displaypic "amsn.png"                   ;# Display picture
		::config::setKey getdisppic 1
		::config::setKey webcamlogs 0
		#::config::setKey use_dock 1				;#enable/disable docking

		::config::setKey autolisten_voiceclips 1                ;# whether voiceclips should be automatically played once received
		::config::setKey use_new_cl 0                		;# whether we should use the new CL as the default one or not...
		::config::setKey spacesinfo "inline"				;# how to draw MSN Spaces info

		::config::setKey snackInputDevice ""				;# The audio Input Device to use with Snack
		::config::setKey snackOutputDevice ""				;# The audio Output Device to use with Snack
		::config::setKey snackMixerDevice ""				;# The audio Mixer Device to use with Snack

		::config::setKey show_login_screen_links 1			;# Show the links in the login screen

		::config::setKey http_proxy_use_gateway 1			;# Wether the http proxy should use the MSN gateway or do a CONNECT instead on the proxy... 

		::config::setKey big_incoming_smileys 0				;# Whether to resize or not the incoming smileys to the standard 50x50 size.

		::config::setKey escape_close_cw 1				;# Whether the escape key closes the chat windows or not

		::config::setKey dynamic_rate 0 				;# Use a dynamic framerate for webcam depending on the timestamps in the ML20 header

                ::config::setKey no_oim_confirmation 0                          ;# Ask or not confirmation to send/read oim messages
		::config::setKey sound_on_first_message 0			;# Play sound only on the first message received in a chat window
		::config::setKey colored_text_in_cw 0				;# Show colored and styled text in chatwindows, the value can be changed by ColoredNicks Plugin


		::config::setKey epname "aMSN"					;# Endpoint Name.. MSNP16+ name of your current location
		::config::setKey shownonim 1					;# Show non IM contacts in the contact list
		::config::setKey groupnonim 0					;# Group non IM contacts in a separate group in the CL
		::config::setKey showspaces 0					;# Enable/disable showing of the spaces star in the CL
		::config::setKey showOfflineGroup 1
		::config::setKey no_blocked_notif 0				;# No notify windows when a user is blocked
		::config::setKey show_detailed_view 0					;#allow to show detailed contact view in cl

		::config::setKey ABPreferredHost "byrdr.omega.contacts.msn.com"
		
		::config::setKey hide_users_in_cw 1	;#in a multichat don't show users in the topcw


		#Advanced options, not in preferences window
		# Create the entry in the list and then, set
		# the variable at bottom

		#List like:
		#	"" trans_section_name_1
		#  optionname1 type1 trans_name1 trans_desc1(optional)
		#  optionname2 type2 trans_name2 trans_desc2(optional)
		#  ...
		#
		# type can be: bool | int | str | folder
		set advanced_options [list \
			[list title appearance] \
			[list local tooltips bool tooltips] \
			[list local emailsincontactlist bool emailsinlist] \
			[list local leavejoinsinchat bool leavejoinsinchat] \
			[list local animatenotify bool animatenotify] \
			[list local enablebanner bool showbanner] \
			[list local truncatenames bool truncatenames1] \
			[list local truncatenicks bool truncatenames2] \
			[list local showtimestamps bool timestamps] \
			[list local savechatwinsize bool savechatwinsize] \
			[list local winchatsize str defchatwinsize] \
			[list local startontray bool startontray] \
			[list local charscounter bool charscounter] \
			[list local strictfonts bool strictfonts] \
			[list local sngdblclick bool sngdblclick] \
			[list local removeempty bool removeempty] \
			[list local tabtitlenick bool tabtitlenick] \
			[list local showpicnotify bool showpicnotify] \
			[list local showmailicon bool showmailicon] \
			[list local autoresizedp bool autoresizedp] \
			[list local show_login_screen_links bool showlinksinlogin] \
			[list local big_incoming_smileys bool noresizesmileys] \
			[list local old_dpframe bool showonedpframe] \
			[list local contentroaming bool contentroamingsetting] \
			[list title notifyoffset] \
			[list local notifyXoffset int xoffset] \
			[list local notifyYoffset int yoffset] \
			[list title prefalerts] \
			[list local notifyonline bool notify1] \
			[list local notifyoffline bool notify1_5] \
			[list local notifystate bool notify1_75] \
			[list local notifymsg bool notify2] \
			[list local notifyemail bool notify3] \
			[list local notifyemailother bool notify4] \
			[list local notifytimeout int notifytimeout] \
			[list local no_blocked_notif bool no_blocked_notif] \
			[list local soundactive bool soundactive] \
		        [list local autolisten_voiceclips bool autolisten_voiceclips] \
			[list local recentmsg bool recentmsg] \
			[list title connection] \
			[list local getdisppic bool getdisppic] \
			[list local checkemail bool checkemail] \
			[list local default_ns_server str notificationserver]\
			[list local lazypicretrieval bool lazypicretrieval]\
			[list local noftpreview bool noftpreview]\
			[list title MSN] \
			[list local displayp4context bool displayp4context] \
			[list local p4contextprefix str p4contextprefix] \
			[list title others] \
			[list local activeautoupdate bool activeautoupdate] \
			[list local allowbadwords bool allowbadwords] \
			[list local libtls_temp folder TLS tlsexplain] \
			[list local notifytyping bool notifytyping] \
			[list local lineflushlog bool lineflushlog] \
			[list local autocheckver bool autocheckver] \
			[list local storename bool storenickname] \
			[list local globaloverride bool globaloverride ] \
			[list local escape_close_cw bool escapeclosescw ] \
			[list local no_oim_confirmation bool nooimconfirmation ] \
			[list global disableprofiles bool disableprofiles] \
		]

		set osspecific_keys [list receiveddir soundcommand browser notifyXoffset \
					notifyYoffset filemanager openfilecommand usesnack \
					wingeometry backgroundcolor dockbounce newchatwinstate \
					newmsgwinstate psmplace mailcommand \
					webcamDevice snackInputDevice snackMixerDevice snackOutputDevice]

		set locale_codes [list \
			[list af 1078] \
			[list ar-ae 14337] \
			[list ar-bh 15361] \
			[list ar-dz 5121] \
			[list ar-eg 3073] \
			[list ar-iq 2049] \
			[list ar-jo 11265] \
			[list ar-kw 13313] \
			[list ar-lb 12289] \
			[list ar-ly 4097] \
			[list ar-ma 6145] \
			[list ar-om 8193] \
			[list ar-qa 16385] \
			[list ar-sa 1025] \
			[list ar-sy 10241] \
			[list ar-tn 7169] \
			[list ar-ye 9217] \
			[list az-az 1068] \
			[list az-az 2092] \
			[list be 1059] \
			[list bg 1026] \
			[list ca 1027] \
			[list cs 1029] \
			[list da 1030] \
			[list de-de 1031] \
			[list de-at 3079] \
			[list de-li 5127] \
			[list de-lu 4103] \
			[list de-ch 2055] \
			[list el 1032] \
			[list en-au 3081] \
			[list en-bz 10249] \
			[list en-ca 4105] \
			[list en-cb 9225] \
			[list en-ie 6153] \
			[list en-jm 8201] \
			[list en-nz 5129] \
			[list en-ph 13321] \
			[list en-za 7177] \
			[list en-tt 11273] \
			[list en-gb 2057] \
			[list en-us 1033] \
			[list es-es 1034] \
			[list es-ar 11274] \
			[list es-bo 16394] \
			[list es-cl 13322] \
			[list es-co 9226] \
			[list es-cr 5130] \
			[list es-do 7178] \
			[list es-ec 12298] \
			[list es-gt 4106] \
			[list es-hn 18442] \
			[list es-mx 2058] \
			[list es-ni 19466] \
			[list es-pa 6154] \
			[list es-pe 10250] \
			[list es-pr 20490] \
			[list es-py 15370] \
			[list es-sv 17418] \
			[list es-uy 14346] \
			[list es-ve 8202] \
			[list et 1061] \
			[list eu 1069] \
			[list fa 1065] \
			[list fi 1035] \
			[list fo 1080] \
			[list fr-fr 1036] \
			[list fr-be 2060] \
			[list fr-ca 3084] \
			[list fr-lu 5132] \
			[list fr-ch 4108] \
			[list gd-ie 2108] \
			[list gd 1084] \
			[list he 1037] \
			[list hi 1081] \
			[list hr 1050] \
			[list hy 1067] \
			[list is 1039] \
			[list id 1057] \
			[list it-it 1040] \
			[list it-ch 2064] \
			[list ja 1041] \
			[list ko 1042] \
			[list lv 1062] \
			[list lt 1063] \
			[list mk 1071] \
			[list ms-my 1086] \
			[list ms-bn 2110] \
			[list mt 1082] \
			[list mr 1102] \
			[list nl-nl 1043] \
			[list nl-be 2067] \
			[list no-no 1044] \
			[list no-no 2068] \
			[list pl 1045] \
			[list pt-pt 2070] \
			[list pt-br 1046] \
			[list rm 1047] \
			[list ro 1048] \
			[list ro-mo 2072] \
			[list ru 1049] \
			[list ru-mo 2073] \
			[list sa 1103] \
			[list sb 1070] \
			[list sl 1060] \
			[list sk 1051] \
			[list sq 1052] \
			[list sr-sp 3098] \
			[list sr-sp 2074] \
			[list st 1072] \
			[list sv-se 1053] \
			[list sv-fi 2077] \
			[list sw 1089] \
			[list ta 1097] \
			[list th 1054] \
			[list tn 1074] \
			[list tr 1055] \
			[list ts 1073] \
			[list tt 1092] \
			[list uk 1058] \
			[list ur 1056] \
			[list uz-uz 2115] \
			[list uz-uz 1091] \
			[list vi 1066] \
			[list xh 1076] \
			[list yi 1085] \
			[list zu 1077] \
			[list zh-cn 2052] \
			[list zh-hk 3076] \
			[list zh-mo 5124] \
			[list zh-sg 4100] \
			[list zh-tw 1028] \
		]
	}

	proc globalDefaults {} {
		global gconfig

		setGlobalKey last_client_version ""
		setGlobalKey language [detect_language "en"]	;#Default language
		setGlobalKey skin "default"			;#AMSN skin
		setGlobalKey disableprofiles 0 ;#Disable profiles (useful for cybercafes or similar)

		#Specific configs for Mac OS X (Aqua) first, and for others systems after
		if { [OnMac] } {
			setGlobalKey basefont [list {Lucida Grande} 12 normal]	;#AMSN Mac OS X base font
		} elseif { [OnWin] } {
			setGlobalKey basefont [list Arial 10 normal]
		} else {
			setGlobalKey basefont [list Helvetica 11 normal]	;#AMSN base font
		}
	}

	proc get {key} {
		return [set ::config($key)]
	}

	proc getKey {key {default ""}} {
		if { [info exists ::config($key)] } {
			return [set ::config($key)]
		} else {
			return $default
		}
	}

	proc getVar {key} {
		return "::config($key)"
	}

	proc getKeys {} {
		return [array names ::config]
	}

	proc getAll {} {
		return [array get ::config]
	}


	proc setKey {key value} {
		set ::config($key) $value
	}

    proc searchKeys { search_key } {
        set r [list]
        foreach key [::config::getKeys] {
            # non case-sensitive string matching
            if { [string match -nocase "*${search_key}*" $key] } {
                # They key matches, so append it to the return var.
                lappend r $key
            }
        }
        return $r
    }

	proc setAll {values} {
		array set ::config $values
	}

	proc unsetKey {key} {
		if { [::config::isSet $key] } {
			unset ::config($key)
		}
	}
	
	proc isSet {key} {
		return [info exists ::config($key)]
	}

	proc renameKey {srcKey dstKey} {
		if {[info exists ::config($srcKey)]} {
			set ::config($dstKey) $::config($srcKey)
			unset ::config($srcKey)
		}
	}

	proc getGlobalKey {key {default ""}} {
		if { [info exists ::gconfig($key)] } {
			return [set ::gconfig($key)]
		} else {
			return $default
		}
	}

	proc getGlobalVar {key} {
		return "::gconfig($key)"
	}

	proc getGlobalKeys {} {
		return [array names ::gconfig]
	}

	proc getGlobalAll {} {
		return [array get ::gconfig]
	}

	proc setGlobalKey {key value} {
		set ::gconfig($key) $value
	}

	proc setGlobalAll {values} {
		array set ::gconfig $values
	}

	proc NewGConfigEntry  {cstack cdata saved_data cattr saved_attr args} {
		global gconfig
		upvar $saved_data sdata

		set gconfig($sdata(${cstack}:attribute)) $sdata(${cstack}:value)

		return 0

	}


	proc loadGlobal {} {
		global gconfig HOME2 HOME

		globalDefaults

		if { [info exists HOME2] } {
			set config_file [file join ${HOME2} "gconfig.xml"]
		} else {
			set config_file [file join ${HOME} "gconfig.xml"]
		}

		if { [file exists $config_file] } {

			if { [catch {
				set file_id [sxml::init $config_file]

				sxml::register_routine $file_id "config:entry" "::config::NewGConfigEntry"
				set val [sxml::parse $file_id]
				sxml::end $file_id
			} res] } {
				::amsn::errorMsg "[trans corruptconfig ${config_file}.old]"
				file copy "$config_file" "$config_file.old"
			}
		}
	}

	proc saveGlobal {} {
		global HOME2 version

		if { [catch {
				if { [OnUnix] } {
					set file_id [open "[file join ${HOME2} gconfig.xml]" w 00600]
				} else {
					set file_id [open "[file join ${HOME2} gconfig.xml]" w]
				}
			} res]} {
			return 0
		}

		puts $file_id  "<?xml version=\"1.0\"?>\n\n<config>"
		::config::setGlobalKey last_client_version $version

		foreach var_attribute [getGlobalKeys] {
			set var_value [::config::getGlobalKey $var_attribute]
			#set var_value ::$gconfig($var_attribute)
			set var_value [::sxml::xmlreplace $var_value]
			puts $file_id "   <entry>\n      <attribute>$var_attribute</attribute>\n      <value>$var_value</value>\n   </entry>"
		}

		puts $file_id "</config>"

		close $file_id

	}

}

proc save_config {} {
	global HOME HOME2 version password custom_emotions osspecific_keys
	
	#saving the plugins
	::plugins::save_config

	status_log "save_config: saving config for user [::config::getKey login] in $HOME]\n" black

	if { [catch {
		if { [OnUnix] } {
			set file_id [open "[file join ${HOME} config.xml.temp]" w 00600]
		} else {
			set file_id [open "[file join ${HOME} config.xml.temp]" w]
		}
	} res]} {
		return 0
	}
	fconfigure $file_id -encoding utf-8

	status_log "save_config: saving config_file. Opening of file returned : $res\n"
	set loginback [::config::getKey login]
	set passback $password

	# using default, make sure to reset config(login)
	if { $HOME == $HOME2 } {
		::config::setKey login ""
		set password ""
	}

	# rename os-specific keys
	foreach srcKey $osspecific_keys {
		set dstKey "${srcKey}_[::config::getKey os]"
		::config::renameKey $srcKey $dstKey
	}

	#Start of config file
	puts $file_id  "<?xml version=\"1.0\"?>\n\n<config>"

	#Save all keys except special ones
	foreach var_attribute [::config::getKeys] {
		set var_value [::config::getKey $var_attribute]
		
		#Convert absolute path to relative path
		if { "$var_attribute" == "displaypic" } {
			set var_value [PathAbsToRel $var_value]
		}

		if { ("$var_attribute" != "remotepassword") && ("$var_attribute" != "os") } {
			set var_value [::sxml::xmlreplace $var_value]
			puts $file_id "   <entry>\n      <attribute>$var_attribute</attribute>\n      <value>$var_value</value>\n   </entry>"
		}
	}

	#Save encripted password
	if { ([::config::getKey save_password]) && ($password != "")} {
		set key [string range "${loginback}dummykey" 0 7]
		binary scan [::DES::des -mode ecb -dir encrypt -key $key "${password}\n"] h* encpass
		puts $file_id "   <entry>\n      <attribute>encpassword</attribute>\n      <value>$encpass</value>\n   </entry>"
	}

	#Save encripted remote password
	set key [string range "${loginback}dummykey" 0 7]
	binary scan [::DES::des -mode ecb -dir encrypt -key $key "[::config::getKey remotepassword]\n"] h* encpass
	puts $file_id "   <entry>\n      <attribute>remotepassword</attribute>\n      <value>$encpass</value>\n   </entry>\n"

	#Save custom emoticons
	foreach name [array names custom_emotions] {
		puts $file_id "   <emoticon>"
		array set emotion $custom_emotions($name)
		foreach attribute [array names emotion] {
			set tmp_value $emotion($attribute)
			#Convert absolute paths to subdirs in the profile-home to relative paths
			if { $attribute == "file" || $attribute == "sound" } {
				set tmp_value [PathAbsToRel $tmp_value]
			}

			set value [::sxml::xmlreplace $tmp_value]
			set attribute [::sxml::xmlreplace $attribute]
			#set var_attribute [::sxml::xmlreplace [string map [list "${custom}_" ""] $attribute ]]
			#set var_value [::sxml::xmlreplace $emotions($attribute)]
			puts $file_id "      <$attribute>$value</$attribute>"
		}
		puts $file_id "   </emoticon>\n"
	}

	#End of config file
	puts $file_id "</config>"

	close $file_id
	
	#writing was successful, so move config.xml.temp to config.xml
	file delete -force [file join ${HOME} config.xml]
	file rename -force [file join ${HOME} config.xml.temp] [file join ${HOME} config.xml]

	# re-rename os-specific keys
	foreach dstKey $osspecific_keys {
		set srcKey "${dstKey}_[::config::getKey os]"
		::config::renameKey $srcKey $dstKey
	}

	::config::setKey login $loginback
	set password $passback

	status_log "save_config: Config saved\n" black


}

proc new_config_entry  {cstack cdata saved_data cattr saved_attr args} {
    upvar $saved_data sdata

    ::config::setKey $sdata(${cstack}:attribute) $sdata(${cstack}:value)

    return 0

}

proc load_config {} {
	global HOME password protocol osspecific_keys

	#Create custom smileys folder
	create_dir "[file join ${HOME} smileys]"

	set user_login [::config::getKey login]
	status_log "load_config: Started. HOME=$HOME, config(login)=$user_login\n"

	#Set default values
	::config::configDefaults

	if { [file exists [file join ${HOME} "config.xml"]] } {

		status_log "load_config: loading file [file join ${HOME} config.xml]\n" blue

		if { [catch {
			set file_id [sxml::init [file join ${HOME} "config.xml"]]

			sxml::register_routine $file_id "config:entry" "new_config_entry"
			sxml::register_routine $file_id "config:emoticon" "::smiley::newCustomEmoticonXML"
			set val [sxml::parse $file_id]
			sxml::end $file_id

			# rename os-specific keys
			foreach dstKey $osspecific_keys {
				set srcKey "${dstKey}_[::config::getKey os]"
				::config::renameKey $srcKey $dstKey
			}

			status_log "load_config: Config loaded\n" green
			if { [winfo exists .smile_selector]} { destroy .smile_selector }

		} res] } {
			::amsn::errorMsg "[trans corruptconfig [file join ${HOME} "config.xml.old"]]"
			status_log "Error when parsing confog.xml : $res"
			file copy -force [file join ${HOME} "config.xml"] [file join ${HOME} "config.xml.old"]
			::sxml::end $file_id
			::config::configDefaults
			file delete [file join ${HOME} "config.xml"]
		}

		#Force the change of the default background color and other specific Mac things
		if { [OnMac] } {
			set bgcolormac [::config::getKey backgroundcolor]
			if { $bgcolormac=="#D8D8E0" } {
				::config::setKey backgroundcolor #ECECEC
			}
			#Force the change of new window to be raised, not iconified (not supported on TkAqua)
			::config::setKey newmsgwinstate 0
			#Force the change to not start amsn on tray if someone chose that in advanced preferences
			::config::setKey startontray 0
			# Force the change of the default sound command
			# For Mac OS X users who used aMSN 0.95 at the beggining
			if {[::config::getKey soundcommand] == "./sndplay" } {
				::config::setKey soundcommand "./utils/macosx/sndplay \$sound"
			}
		}
	}
	#Force to change the path to the new path of plwav.exe
	if { [OnWin] } {
		if {[::config::getKey soundcommand] == "utils/plwav.exe \$sound"} {
			::config::setKey soundcommand "utils/windows/plwav.exe \$sound"
		}
	}
	#Sometimes, if there is a bugreport when opening a new window, the size of the window saved will be 1x1
	if {[::config::getKey winchatsize]=="1x1"} {
		::config::setKey winchatsize "350x320"
	}
	if {[::config::getKey wincontainersize]=="1x1"} {
		::config::setKey wincontainersize "350x320"
	}

	#Get the encrypted password
	if {[::config::getKey encpassword]!=""} {
		set key [string range "[::config::getKey login]dummykey" 0 7]
		set password [::config::getKey encpassword]
		catch {set encpass [binary format h* [::config::getKey encpassword]]}
		catch {set password [::DES::des -mode ecb -dir decrypt -key $key $encpass]}
		#puts "Password length is: [string first "\n" $password]\n"
		set password [string range $password 0 [expr { [string first "\n" $password] -1 }]]
		#puts "Password is: $password\nHi\n"
		::config::unsetKey encpassword
	}

	#Get the encrypted remote password
	if {[::config::getKey remotepassword]!=""} {
		set key [string range "[::config::getKey login]dummykey" 0 7]
		catch {set encpass [binary format h* [::config::getKey remotepassword]]}
		catch {::config::setKey remotepassword [::DES::des -mode ecb -dir decrypt -key $key $encpass]}
		#puts "Password length is: [string first "\n" [::config::getKey remotepassword]]\n"
		::config::setKey remotepassword [string range [::config::getKey remotepassword] 0 [expr { [string first "\n" [::config::getKey remotepassword]] -1 }]]
		#puts "Password is: [::config::getKey remotepassword]\nHi\n"
	}

	::config::setKey clientid 0
	if {[::config::getKey protocol] < 15 } {
		::config::setKey protocol 15
	}

	if {[config::getKey protocol] >= 16} {
		::MSN::setClientCap msnc10
	} else {
		::MSN::setClientCap msnc7
	}
	::MSN::setClientCap inkgif
	::MSN::setClientCap multip
	::MSN::setClientCap voice

	# Load up the personal states
	LoadStateList
	if { [winfo exists .my_menu] } {CreateStatesMenu .my_menu}
	if { [::config::getKey login] == "" } {
		status_log "load_config: Empty login !!! FIXING\n" red
		::config::setKey login $user_login
	}

	if { [::config::getKey enableremote] } {
		init_remote_DS
	}

	#set the banner for this user when switching users
	global initialize_amsn
	if { $initialize_amsn != 1 } {
		resetBanner
	}

        # Show/hide menus when switching profiles 
    	if { ![OnMac] } {
	    Showhidemenu 0
	    ::ChatWindow::ShowHideChatWindowMenus . 0
	}

	#load Snack
	if {![catch {require_snack} res]} {
		# TODO this is bad because it already gets called by require_snack once... 
		::audio::init
	} else {
		if { [::config::getKey usesnack] } {
			::config::setKey usesnack 0
			save_config
		}
	}

	::plugins::LoadPlugins

	create_dir "[::config::getKey receiveddir]"


	# We now want to force the NAT Keep alive to enabled
	::config::setKey keepalive 1

	# We loaded the config, we will now load the DP pictures.. 
	load_my_pic
	
	#We parse the global nick
	set data [::smiley::parseMessageToList [list [ list "text" [::config::getKey globalnick] ]] 1]
	set evpar(variable) data
	set evpar(login) ""
	::plugins::PostEvent parse_contact evpar
	set ::globalnick $data
}


#///////////////////////////////////////////////////////////////////////////////
# LoadLoginList ()
# Loads the list of logins/profiles from the profiles file in the HOME dir
# sets up the first user in list as config(login)
proc LoadLoginList {{trigger 0}} {
	global HOME HOME2

	#puts stdout "called loadloginlist\n"
	status_log "LoadLoginList: starting\n" blue

	if { $trigger != 0 } {
		status_log "LoadLoginList: getting profiles\n" blue
	} else {
		set HOME2 $HOME
	}


	if {([file readable "[file join ${HOME} profiles]"] != 0) && ([file isfile "[file join ${HOME} profiles]"] != 0)} {
		set HOMEE $HOME
	} elseif {([file readable "[file join ${HOME2} profiles]"] != 0) && ([file isfile "[file join ${HOME2} profiles]"] != 0)} {
		set HOMEE $HOME2
	} else {
		return 1
	}

	status_log "LoadLoginList: HOME=$HOME, HOME2=$HOME2, HOMEE=$HOMEE\n" blue


	set file_id [open "[file join ${HOMEE} profiles]" r]
	gets $file_id tmp_data
	if {$tmp_data != "amsn_profiles_version 1"} {	;# config version not supported!
		#msg_box [trans wrongprofileversion $HOME]
		close $file_id

		set OLDHOME $HOME

		status_log "LoadLoginList: Recreating profiles file\n" blue

		if { [catch {set file_id [open "[file join ${HOMEE} profiles]" w]}]} {
			return -1
		}

		puts $file_id "amsn_profiles_version 1"
		#Recreate profiles file
		if { [catch {set folders [glob -directory ${HOMEE} -tails -types d *]}] } {
			return -1
		}
		foreach folder $folders {
			if {[file readable [file join ${HOMEE} $folder config.xml]]} {
				set HOME [file join $HOMEE $folder]
				load_config
				set login [::config::getKey login]
				if {$login != "" } {
					puts $file_id "$login 0"
				}
			}
		}
		close $file_id

		set HOME $OLDHOME

		return [LoadLoginList $trigger]
	}

	# Clear all list
	set top [LoginList size 0]
	for { set idx 0 } { $idx <= $top } {incr idx 1 } {
		LoginList unset 0 [LoginList get 0]
	}

	# Now add profiles from file to list
	while {[gets $file_id tmp_data] != "-1"} {
		set temp_data [split $tmp_data]

		set user_login [lindex $tmp_data 0]
		set locknum [lindex $tmp_data 1]
		if {[string first "@" $user_login] == -1} {
			status_log "Profile $user_login is wrong!! Fixing\n" red
			#Profile is wrong, fix it from config file
			set oldHOME $HOME
			set dirname [string map {"@" "_" "." "_"} $user_login]
			set HOME [file join $HOMEE $dirname]
			load_config
			set user_login [::config::getKey login]
			set HOME $oldHOME
		}


#	    puts "temp data : $temp_data"
		if { $locknum == "" } {
		   #Profile without lock, give it 0
		   set locknum 0
		}

		LoginList add 0 $user_login $locknum
		status_log "LoadLoginList: adding profile $user_login with lock num $locknum\n" blue
	}
	close $file_id


	# Modify HOME dir to current profile, chose a non locked profile, if none available go to default
	if { $trigger == 0 } {

		#If profiles are disabled, don't load one
		if { [::config::getGlobalKey disableprofiles] == 1 } {
			status_log "LoadLoginList: profiles disabled, ignoring\n" blue
			::config::setKey login ""
			set HOME2 $HOME
			return
		}

		status_log "LoadLoginList: getting an initial profile\n" blue
		set HOME2 $HOME
		set flag 0
		for { set idx 0 } { $idx <= [LoginList size 0] } {incr idx 1} {
			if { [CheckLock [LoginList get $idx]] != -1 } {
				LockProfile [LoginList get $idx]
				status_log "LoadLoginList: profile [LoginList get $idx] is free, locking\n"
				set flag 1
				break
			}
		}

		# if flag is 1 means we found a profile and we use it, if not defaults
		if { $flag == 1 } {
			set temp [LoginList get $idx]
			set dirname [string map {"@" "_" "." "_"} $temp]
			#set dirname [split $temp "@ ."]
			#set dirname [join $dirname "_"]
			set HOME "[file join $HOME2 $dirname]"
			::config::setKey login "$temp"
			status_log "LoadLoginList: we found a free profile: $temp\n" green
		} else {
			status_log "LoadLoginList: using default profile\n" green
			::config::setKey login ""
		}
		SaveLoginList
	}
}


#///////////////////////////////////////////////////////////////////////////////
# SaveLoginList ()
# Saves the list of logins/profiles to the profiles file in the HOME dir
proc SaveLoginList {} {
	global HOME2 currentlock

	if { [OnUnix] } {
		set file_id [open "[file join ${HOME2} profiles]" w 00600]
	} else {
      		set file_id [open "[file join ${HOME2} profiles]" w]
	}
	puts $file_id "amsn_profiles_version 1"

	set idx [LoginList size 0]
	while { $idx >= 0 } {
		puts $file_id "[LoginList get $idx] [LoginList getlock 0 [LoginList get $idx]]"
		incr idx -1
	}
	close $file_id
}


#///////////////////////////////////////////////////////////////////////////////
# LoginList (action age [email])
# Controls information for list of profiles read from the profiles file
# action can be :
#	add : Adds new user to list, or if exists makes this user the newest
#	      (age is ignored), lock must be given if new profile
#	get : Returns the email by age, returns 0 if no email for age exists
#	exists : Checks the email if exists returns 1, 0 if dosent (age is ignored)
#	getlock : Returns lock code for given email, if non existant returns -1.
#	changelock : changes lock for user given by email to lock port given by lock
#	lockexists : checks if lock exists for some profile, returns 1 if true, 0 if false
#	unset : Removes profile given by email from the list and moves
#		all elements up by 1 (age is ignored)
#       size : Returns [array size ProfileList] - 1
#	show : Dumps list to status_log, for debugging purposes only
proc LoginList { action age {email ""} {lock ""} } {
	variable ProfileList
	#global ProfileList
	variable LockList
	global currentlock

	switch $action {
		add {
			set tmp_list [array get ProfileList]
			set idx [lsearch $tmp_list "$email"]
			if { $idx == -1 } {
				# User dosen't exist, proceed normally
				for {set idx [expr {[array size ProfileList] - 1}]} {$idx >= 0} {incr idx -1} {
					set ProfileList([expr {$idx + 1}]) $ProfileList($idx)
					set LockList([expr {$idx + 1}]) $LockList($idx)
				}
				set ProfileList(0) $email
				set LockList(0) $lock
			} else {
				# This means user exists, and we make him newest
				#set emaillock $LockList([expr {[expr {$idx-1}] / 2}])
				set emaillock $LockList([expr {($idx-1) / 2}])
				for {set idx [lindex $tmp_list [expr {$idx - 1}]]} {$idx > 0} {incr idx -1} {
					set ProfileList($idx) $ProfileList([expr {$idx - 1}])
					set LockList($idx) $LockList([expr {$idx - 1}])
				}
				set ProfileList(0) $email
				set LockList(0) $emaillock
			}
		}

		unset {
			set tmp_list [array get ProfileList]
			set idx [lsearch $tmp_list "$email"]
			if { $idx != -1 } {
				for {set idx [lindex $tmp_list [expr {$idx - 1}]]} {$idx < [expr {[array size ProfileList] - 1}]} {incr idx} {
					set ProfileList($idx) $ProfileList([expr {$idx + 1}])
					set LockList($idx) $LockList([expr {$idx + 1}])
				}
			unset LockList([expr {[array size ProfileList] - 1}])
			unset ProfileList([expr {[array size ProfileList] - 1}])
			}
		}

		get {
			if { [info exists ProfileList($age)] } {
				return $ProfileList($age)
			} else {
				return 0
			}
		}

		exists {
			set tmp_list [array get ProfileList]
			set idx [lsearch $tmp_list "$email"]
			if { $idx == -1 } {
				return 0
			} else {
				return 1
			}
		}

		getlock {
			set tmp_list [array get ProfileList]
			set idx [lsearch $tmp_list "$email"]
#		    puts "$tmp_list donne --> $idx --- $email --- [expr [expr $idx-1] /2] --- $ProfileList([expr [expr $idx-1] /2])"
			if { $idx == -1 } {
				return -1
			} else {
			    	return $LockList([lindex $tmp_list [expr {$idx-1}]])
			}
		}

		changelock {
			set tmp_list [array get ProfileList]
			set idx [lsearch $tmp_list "$email"]
			if { $idx == -1 } {
				status_log "changelock called on unexisting email : $email, shouldn't happen!\n" red
				return -1
			} else {
			    	set LockList([lindex $tmp_list [expr {$idx-1}]]) $lock
			}
		}

		lockexists {
			set tmp_list [array get LockList]
			return [lsearch $tmp_list [LoginList getlock "" "$email"]]
		}

		size {
			return [expr {[array size ProfileList] - 1}]
		}

		show {
			for {set idx 0} {$idx < [array size ProfileList]} {incr idx} {
				status_log "$idx : $ProfileList($idx)\n"
#				puts stdout "$idx : $ProfileList($idx) loclist is : $LockList($idx)\n"
			}
		}
	}
}


#///////////////////////////////////////////////////////////////////////////////
# ConfigChange ( window email)
# Called when the user selects a combobox item or enters new signin
# email : email of the new profile/login
proc ConfigChange { window email } {
	status_log "ConfigChange: $email\n" blue
	global HOME HOME2 password log_dir webcam_dir lockSock

	if { $email != "" } {
		status_log "ConfigChange: Valid email\n" green

		if { $email != [::config::getKey login] } {
			status_log "ConfigChange: Email changed\n" blue

			if { [LoginList exists 0 [::config::getKey login]] == 1 } {
				save_config
			}

			if { [LoginList exists 0 $email] == 1 } {

				status_log "ConfigChange: Login exists\n" blue

				# Profile exists, make the switch
				set OLDHOME $HOME

				set dirname [string map {"@" "_" "." "_"} $email]
				#set dirname [split $email "@ ."]
				#set dirname [join $dirname "_"]
				set HOME "[file join $HOME2 $dirname]"

				if { [CheckLock $email] == -1 } {
					status_log "ConfigChange: Profile is locked\n" blue

					::amsn::messageBox [trans profileinuse] ok info "aMSN"
					set HOME $OLDHOME

					# Reselect previous element in combobox
					set cb [$window list get 0 [LoginList size 0]]
					set index [lsearch $cb [::config::getKey login]]
					$window select $index
				} else {
					status_log "ConfigChange: Profile is free\n" green

					if { [info exists password] } {
						set password ""
					}

					# Make sure we delete old lock
					if { [info exists lockSock] } {
						if { $lockSock != 0 } {
							close $lockSock
							unset lockSock
						}
					}

					if { [LoginList exists 0 [::config::getKey login]] } {
						LoginList changelock 0 [::config::getKey login] 0
					}

					config::setKey login $email
					load_config

					LoginList add 0 $email
					set log_dir "[file join ${HOME} logs]"
					set webcam_dir "[file join ${HOME} webcam]"
					create_dir $webcam_dir

					# port isn't taken or port taken by other program, meaning profile ain't locked
					# let's setup the new lock
					LockProfile $email
					SaveLoginList
					cmsn_draw_offline

				}
			}
		}

		if { [winfo exists .login] } {
			.login.main.passentry2 delete 0 end
			if { [info exists password] } {
				.login.main.passentry2 insert 0 $password
			}
			.login.main.statelist select [get_state_list_idx [::config::getKey connectas]]
		
		}
	}
}

proc SwitchToDefaultProfile { } {
	global lockSock HOME HOME2 log_dir webcam_dir loginmode
	# Make sure we delete old lock
	if { [info exists lockSock] } {
		if { $lockSock != 0 } {
			close $lockSock
			unset lockSock
		}
	}
	if { [::config::getKey login] != "" } {
		LoginList changelock 0 [::config::getKey login] 0
		SaveLoginList
	}

	# Load default config
	set HOME $HOME2

	config::setKey login ""
	#that key is lost when changing profile
	set connectas [::config::getKey connectas]
	load_config
	set log_dir ""
	set webcam_dir ""

	# Set variables for default profile
	::config::setKey save_password 0
	::config::setKey connectas $connectas
	::config::setKey keep_logs 0
	::config::setKey webcamlogs 0
	::config::setKey log_event_connect 0
	::config::setKey log_event_disconnect 0
	::config::setKey log_event_email 0
	::config::setKey log_event_state 0
	::config::setKey log_event_nick 0
	::config::setKey log_event_psm 0
	::config::setKey displaypic "amsn.png"
}

#///////////////////////////////////////////////////////////////////////////////
# SwitchProfileMode ( value )
# Switches between default and profiled mode, called from radiobuttons
# value : If 1 use profiles, if 0 use default profile
proc SwitchProfileMode { value } {
	global lockSock HOME HOME2 log_dir webcam_dir loginmode

	if { $value == 1 } {
		if { $HOME == $HOME2 } {
			for { set idx 0 } { $idx <= [LoginList size 0] } { incr idx } {
				if { [CheckLock [LoginList get $idx]] != -1 } {
					set window .login.main.box
					set cb [$window list get 0 [LoginList size 0]]
					set index [lsearch $cb [LoginList get $idx]]
					$window select $index
					break
				}
			}

			if { [LoginList size 0] == -1 } {
				msg_box [trans noprofileexists]
				set loginmode 0
				# Going back to default profile
				set loginmode 0
				#RefreshLogin .login.main 1
			} elseif { $idx > [LoginList size 0] } {
				msg_box [trans allprofilesinuse]
				# Going back to default profile
				set loginmode 0
				#RefreshLogin .login.main 1
			}
		# Else we are already in a profile, select that profile in combobox
		} else {
			set window .login.main.box
			set cb [$window list get 0 [LoginList size 0]]
			set index [lsearch $cb [::config::getKey login]]
			$window select $index
			unset window
		}
	} else {
		# Switching to default profile, remove lock on previous profiles if needed
		SwitchToDefaultProfile
	}
}


#///////////////////////////////////////////////////////////////////////////////
# CreateProfile ( email )
# Creates a new profile
# email : email of new profile
proc CreateProfile { email } {
	global HOME HOME2 log_dir webcam_dir password lockSock loginmode

	if { [LoginList exists 0 $email] == 1 } {
		msg_box [trans profileexists]
		return -1
	}

	# If first time loading from default profile, make sure .amsn/config exists
	if { ($HOME == $HOME2) && ([file exists [file join $HOME2 config.xml]] == 0) } {
		save_config
	}

	set oldlogin [::config::getKey login]

	status_log "Creating new profile for $email\n" blue
	# Create a new profile with $email
	# Set HOME dir and create it
	set dirname [string map {"@" "_" "." "_"} $email]

	#set dirname [split $email "@ ."]
	#set dirname [join $dirname "_"]
	set HOME "[file join $HOME2 $dirname]"
	create_dir $HOME
	set log_dir "[file join ${HOME} logs]"
	create_dir $log_dir
	set webcam_dir "[file join ${HOME} webcam]"
	create_dir $webcam_dir

	# Load default config initially
	# file copy -force [file join $HOME2 config.xml] $newHOMEdir

	set oldpassword $password
	set oldsavepwd [::config::getKey save_password]
	set oldautoconnect [::config::getKey autoconnect 0]

	# set all config keys to default
	::config::configDefaults

	# re-set login, password an remember password value before saving
	::config::setKey login $email
	set password $oldpassword
	::config::setKey save_password $oldsavepwd
	::config::setKey autoconnect $oldautoconnect
	save_config

	unset oldpassword
	unset oldsavepwd
	unset oldautoconnect

	# Add to login list
	LoginList add 0 $email 0
	SaveLoginList

	# Fire event
	::Event::fireEvent profileCreated {} $email

	# Redraw combobox with new profile
	if { [winfo exists .login] } {
		set loginmode 1
		#RefreshLogin .login.main 1
		.login.main.box list delete 0 end
		set idx 0
		set tmp_list ""
		while { [LoginList get $idx] != 0 } {
			lappend tmp_list [LoginList get $idx]
			incr idx
		}
		eval .login.main.box list insert end $tmp_list
		unset idx
		unset tmp_list

		# Select the new profile in combobox
		set window .login.main.box
		set cb [$window list get 0 [LoginList size 0]]
		set index [lsearch $cb $email]
		$window select $index
	}
	return 0
}

proc gethomes {} {
	global HOME HOME2 log_dir
	status_log "HOME = $HOME \nHOME2 = $HOME2\nlogin = [::config::getKey login]\nlog_dir = $log_dir\n"
}

#///////////////////////////////////////////////////////////////////////////////
# DeleteProfile ( email )
# Delete profile given by email, has to be different than the current profile
# entrypath : Path to the combobox containing the profiles list in preferences
proc DeleteProfile { email entrypath } {
	global HOME2
	if { $email == "" } {
		return
	}
	#Reload profiles file
	LoadLoginList 1
	# Make sure profile isn't locked
	if { $email == [::config::getKey login] } {
		msg_box [trans cannotdeleteprofile]
		return
	}
	if { [CheckLock $email] == -1 } {
		msg_box [trans cannotdeleteprofile]
		return
	}

	set answer [::amsn::messageBox "[trans confirmdelete ${email}]" yesno question]

	if {$answer == "no"} {
	return
	}

	set dir [string map {"@" "_" "." "_"} $email]

	#set dir [split $email "@ ."]
	#set dir [join $dir "_"]


	set entryidx [$entrypath curselection]
	if {$entryidx == "" } {
		set entryidx 0
	}

	catch { file delete -force [file join $HOME2 $dir] }
	$entrypath list delete $entryidx
	$entrypath select 0
	LoginList unset 0 $email

	# Lets save it into the file
	SaveLoginList

	# Fire event
	::Event::fireEvent profileDeleted {} $email

}

#///////////////////////////////////////////////////////////////////////////////
# CheckLock ( email )
# Check Lock of profile given by email
# Return -1 if profile is already locked, returns 0 otherwise
proc CheckLock { email } {
	global response LockList
	set response ""
	set Port [LoginList getlock 0 $email]
	status_log "CheckLock: LoginList getlock called. Lock=$Port\n" blue
	if { $Port != 0 } {
		if { [OnWinVista] || [catch {socket -server phony $Port} newlockSock] != 0 } {
			#status_log "CheckLock Port is already in use: $newlockSock\n" red
			# port is taken, let's make sure it's a profile lock
			foreach {local_host} { localhost "[info hostname]" 127.0.0.1 } {
				if {[catch {socket $local_host $Port} clientSock] == 0 } {
					status_log "CheckLock: Can connect to port. Sending PING\n" blue
					fileevent $clientSock readable "lockcltHdl $clientSock"
					fconfigure $clientSock -buffering line
					puts $clientSock "AMSN_LOCK_PING"
					after 5000 [list set response failed]
					vwait response

					if { $response == "AMSN_LOCK_PONG" } {
						status_log "CheckLock: Got PONG response\n" green
						# profile is locked
						close $clientSock
						return -1
					} elseif { $response == "failed" } {
						status_log "CheckLock: failed to get response from port $Port. Reseting to 0\n" blue
						LoginList changelock 0 $email 0
					} else {
						status_log "CheckLock: another program using port $Port. Reseting to 0\n" blue
						# other non amsn program is using the lock port, we better reset the lock to 0
						LoginList changelock 0 $email 0
					}
				break
				}
			}
		} else {
			status_log "CheckLock: Port $Port is free!!\n" green
			close $newlockSock
		}
	} else {
		status_log "CheckLock: Port is zero\n" blue

	}
	return 0
}

proc lockcltHdl { sock } {
	global response
	set response [gets $sock]
}

#///////////////////////////////////////////////////////////////////////////////
# GetRandomProfilePort ()
# Returns a random port in range 60535-65335
proc GetRandomProfilePort { } {

	set trigger 0

	while { $trigger == 0 } {
		# Generate random port between 60535 and 65535
		set Port [expr rand()]
		set Port [expr {$Port * 5000}]
		set Port [expr {int($Port)}]
		set Port [expr {$Port + 60535}]
		# Check if port isn't on another profile already
		if { [LoginList lockexists 0 $Port] != 1 } {
			set trigger 1
		}
	}

	return $Port
}
#///////////////////////////////////////////////////////////////////////////////
# LockProfile ( email )
# Creates a new lock for given profile, tries random ports until one works
proc LockProfile { email } {
	status_log "LockProfile: Locking $email\n" blue
	global lockSock
	set tries 0
	while { $tries < 6 } {
		set Port [GetRandomProfilePort]
		status_log "LockProfile: Got random port $Port\n" blue
		if { [::config::getKey enableremote] == 1 } {
			set cmd "socket -server lockSvrNew $Port"
		} else {
			set cmd "socket -myaddr 127.0.0.1 -server lockSvrNew $Port"
		}
		if { [catch {eval $cmd} newlockSock] == 0  } {
			LoginList changelock 0 $email $Port
			set lockSock $newlockSock
			break
		} elseif {$tries >= 5} {
			::amsn::errorMsg "Unable to get a socket from localhost.\n Check your /etc/hosts file, please. Be sure to have net loopback up."
			break
		} else {
			catch {status_log "unable to create socket on port $Port - $newlockSock"}
			incr tries
		}
	}
#	if { $trigger == 1 } {
		#vwait events
#	}
}


proc lockSvrNew { sock addr port} {
	status_log "lockSvrNew: Accepting connection on port $port\n" blue

#	if { $addr == "127.0.0.1" } {
		fileevent $sock readable "lockSvrHdl $addr $sock"
		fconfigure $sock -buffering line
#	}
}

proc lockSvrHdl { addr sock } {
	status_log "lockSvrHdl: handling connection\n" blue

	set command [gets $sock]

	if {[eof $sock]} {
	    catch {close $sock}
	    close_remote $sock
	} else {
		if { $command == "AMSN_LOCK_PING" } {
			# don't allow anyone to ping and know we are an amsn port unless it's coming from the localhost
			if { $addr == "127.0.0.1" } {
				status_log "lockSvrHdl: PING - PONG\n" blue
				catch {puts $sock "AMSN_LOCK_PONG"}
			}
		} else {
		    read_remote $command $sock
		}

	}
}

proc WinDetectBoot { } {
	if { [OnWin] } {
		if {[catch {package require registry}] } {
			return 0
		}
		set path "HKEY_CURRENT_USER\\Software\\Microsoft\\Windows\\CurrentVersion\\Run"
		if {[catch { registry get $path amsn} ] } {
			return 0
		} else {
			return 1
		}
	}
	return 0
}
#///////////////////////////////////////////////////////////////////////
# WinRegKey ( [addrem] )
# Adds or removes the registry key to start amsn on startup (windows only)
# Arguments:
#  - addrem => choice of adding or removing the registry key: (add/remove)
# Result: Returns 0/1 for failure/success (note failure could include failure to remove the temporary
#         file after completion, but the registry key may have still been created/removed
proc WinRegKey { addrem } {
	if { [OnWin] } {
		if {[catch {package require registry}] } {
			return 0
		}
		set path "HKEY_CURRENT_USER\\Software\\Microsoft\\Windows\\CurrentVersion\\Run"
		set amsn_path [file nativename [file normalize [file join [file dirname [info nameofexecutable]] .. amsn.exe]]]
		if {![file exists $amsn_path] } {
			set amsn_path "[file nativename [file normalize [info nameofexecutable]]] [file nativename [file normalize [info script]]]"
		}
	
		if { $addrem } {
			catch {registry set $path amsn $amsn_path}
		} else {
			catch {registry delete $path amsn}
		}
		
		return 1
	}
	return 0
} 

#///////////////////////////////////////////////////////////////////////


#///////////////////////////////////////////////////////////////////////
# create_dir(path)
# Creates a directory
proc create_dir {path} {
   if {[file isdirectory $path] == 0} {
      if { [catch {file mkdir $path} res]} {
         return -1
      }
      if { [OnUnix] } {
         file attributes $path -permissions 00700
      }
      return 0
   } else {
      return 1
   }
}
#///////////////////////////////////////////////////////////////////////

proc PathAbsToRel { path } {
	global HOME
	
	if { [string index $path 0] == "~" && $path != [PathRelToAbs $path] } {
		set path [PathRelToAbs $path]
	}

	#Convert absolute path to a relative path
	if { [string length $path] > [string length $HOME] && [string equal -length [string length $HOME] $HOME $path] && [string index $path [string length $HOME]] == "/"} {
		set path "[string range $path [expr [string length $HOME] + 1] end]"
	}

	return $path
}

proc PathRelToAbs { path } {
	global HOME
	
	#Expand relative path to an absolute path again
	if { [string index $path 0] == "~" } {
		set path2 "$HOME[string range $path 1 end]"
		if {[file exists $path2]} {
			return $path2
		}
	}
	
	if {[file exists [file join $HOME $path]]} {
		return [file join $HOME $path]
	}
	return $path
}

if { $initialize_amsn == 1 } {
	###############################################################
	create_dir $HOME
	create_dir $HOME/plugins
	create_dir $HOME/skins
	#create_dir $log_dir
	#create_dir [::config::getKey receiveddir]
	scan_languages
	::config::configDefaults
	::config::loadGlobal


	load_lang ;#Load default english language
	load_lang [::config::getGlobalKey language]

	;# Load of logins/profiles in combobox
	;# Also sets the newest login as config(login)
	;# and modifies HOME with the newest user
	if { [LoadLoginList]==-1 } {
		exit
	}

	global gui_language
	set gui_language [::config::getGlobalKey language]

	load_config		;# So this loads the config of this newest dude

	# Init skin and smileys
	::skin::reloadSkin [::config::getGlobalKey skin]

	set machineguid [::config::getGlobalKey machineguid ""]
	if {$machineguid == "" } {
		set machineguid "{"
		for {set i 0} {$i < 8} {incr i} {
			append machineguid [format %x [expr {int(rand() * 16)}]]
		}
		append machineguid "-"
		for {set i 0} {$i < 4} {incr i} {
			append machineguid [format %x [expr {int(rand() * 16)}]]
		}
		append machineguid "-"
		for {set i 0} {$i < 4} {incr i} {
			append machineguid [format %x [expr {int(rand() * 16)}]]
		}
		append machineguid "-"
		for {set i 0} {$i < 4} {incr i} {
			append machineguid [format %x [expr {int(rand() * 16)}]]
		}
		append machineguid "-"
		for {set i 0} {$i < 12} {incr i} {
			append machineguid [format %x [expr {int(rand() * 16)}]]
		}
		append machineguid "}"

		::config::setGlobalKey machineguid $machineguid
	}
}
