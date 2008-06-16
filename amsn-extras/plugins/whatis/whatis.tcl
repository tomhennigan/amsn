##
# License: GNU General Public License
#
# Plugin written by: Jasper Huzen
# Comments: feaster@xs4all.nl
# Version: 1.0 
##	

namespace eval ::whatis {
	
	#
   # The initial procedure called when the plugin is started by AMSN
	#	
	proc init { dir }	{
		::plugins::RegisterPlugin "whatis"
      
		# Register event when change status
		::plugins::RegisterEvent "whatis" new_chatwindow addButtons
			
		plugins_log "whatis" "plugin registered"
	}
	
	#
	# Get the selected text from the chatWindow
	# 
	proc getSelectedText { w } {
	   if { $::version == "0.94" } {
			set window $w.f.bottom.in.input
		
			if { [ catch {$window tag ranges sel}]} {
				set window $w
			}
		
			set index [$window tag ranges sel]
		
			if { $index == "" } {
				set window $w.f.out.text
				catch {set index [$window tag ranges sel]}
				if { $index == "" } {  return }
			}
		} else { 
			if { [ catch {set window [::ChatWindow::GetInputText $w]} ]} {
				set window $w
			}
			
			set index [$window tag ranges sel]
		
			if { $index == "" } {
				set window [::ChatWindow::GetOutText $w]
				catch {set index [$window tag ranges sel]}
				if { $index == "" } {  return }
			}
		}
			
		set dump [$window dump -text [lindex $index 0] [lindex $index 1]]
		
		if { $dump == "" } return
		
		foreach { text output index } $dump {
			append tpmVar $output
		}
		
		return $tpmVar  
			
	}
	
	#
	# Add menu items to the rightbutton menu
	#
	proc addButtons { event evpar } {
		upvar 2 $evpar args
		
		plugins_log "whatis" "Add buttons to window"
			
		#Define variables
		set w $args(win)
		set copymenu $w.copy
		addEntriesToMenu $copymenu $w
		set copypastemenu $w.copypaste
		addEntriesToMenu $copypastemenu $w
	}

	proc addEntriesToMenu { copymenu w } {

		$copymenu add cascade -label "What is" -menu $copymenu.whatis
		menu $copymenu.whatis -tearoff 0 -type normal
		
		$copymenu.whatis add cascade -label "Wikipedia" -menu $copymenu.whatis.wikipedia
		menu $copymenu.whatis.wikipedia -tearoff 0 -type normal
		$copymenu.whatis.wikipedia add command -label "English encyclopedia" -command "whatis::getFromWikipida $w en"	
		$copymenu.whatis.wikipedia add command -label "Dutch encyclopedia" -command "whatis::getFromWikipida $w nl"	
		$copymenu.whatis.wikipedia add command -label "Spanish encyclopedia" -command "whatis::getFromWikipida $w es"	
		$copymenu.whatis.wikipedia add command -label "German encyclopedia" -command "whatis::getFromWikipida $w de"	
		$copymenu.whatis.wikipedia add command -label "French encyclopedia" -command "whatis::getFromWikipida $w fr"	
		$copymenu.whatis.wikipedia add command -label "Italian encyclopedia" -command "whatis::getFromWikipida $w it"	
		$copymenu.whatis.wikipedia add command -label "Portuguese encyclopedia" -command "whatis::getFromWikipida $w pt"	
		$copymenu.whatis.wikipedia add command -label "Polish encyclopedia" -command "whatis::getFromWikipida $w pl"	
		$copymenu.whatis.wikipedia add command -label "Sweden encyclopedia" -command "whatis::getFromWikipida $w sv"	
		
		$copymenu.whatis add cascade -label "Translate" -menu $copymenu.whatis.translate
		menu $copymenu.whatis.translate -tearoff 0 -type normal
		$copymenu.whatis.translate add command -label "English to Spanish" -command "whatis::translateText $w en es"	
		$copymenu.whatis.translate add command -label "English to French" -command "whatis::translateText $w en fr"
		$copymenu.whatis.translate add command -label "English to German" -command "whatis::translateText $w en de"	
		$copymenu.whatis.translate add command -label "English to Italian" -command "whatis::translateText $w en it"
		$copymenu.whatis.translate add command -label "English to Dutch" -command "whatis::translateText $w en nl"	
		$copymenu.whatis.translate add command -label "English to Portuguese" -command "whatis::translateText $w en pt"
		$copymenu.whatis.translate add command -label "English to Russian" -command "whatis::translateText $w en ru"	
		$copymenu.whatis.translate add command -label "English to Greek" -command "whatis::translateText $w en el"
		$copymenu.whatis.translate add command -label "English to Japanese"  -command "whatis::translateText $w en ja"
		$copymenu.whatis.translate add command -label "Dutch to English" -command "whatis::translateText $w nl en"
		$copymenu.whatis.translate add command -label "Spanish to English" -command "whatis::translateText $w es en"	
		$copymenu.whatis.translate add command -label "German to English" -command "whatis::translateText $w de en"	
		$copymenu.whatis.translate add command -label "Italian to English" -command "whatis::translateText $w it en"	
		$copymenu.whatis.translate add command -label "Portuguese to English" -command "whatis::translateText $w pt en"	
		$copymenu.whatis.translate add command -label "French to English" -command "whatis::translateText $w fr en"		
		$copymenu.whatis.translate add command -label "Russian to English" -command "whatis::translateText $w ru en"	
		$copymenu.whatis.translate add command -label "Greek to English" -command "whatis::translateText $w el en"
		$copymenu.whatis.translate add command -label "Japanese to English" -command "whatis::translateText $w ja en"
	}
	
	#
	# This proc will call a Wikipedia page
	#
	proc getFromWikipida { w dict} {
		set searchText [getSelectedText $w]
		status_log "whatis" "Check Wikipedia: $searchText"
	
		launch_browser "http://$dict.wikipedia.org/wiki/[string tolower [ urlencode $searchText]]" 
		
		# Write a seperated line to the chat window
		# Versions above 0.94 can use a graphical build-in line so I use this call
		::amsn::WinWrite [::ChatWindow::Name $w] "\n" green
			
		# Write a seperated line to the chat window
		# Versions above 0.94 can use a graphical build-in line so I use this call
		if { $::version == "0.94" } {
				::amsn::WinWrite [::ChatWindow::Name $w] "--------------------------------------------------" gray_italic	 
		} else {
				::amsn::WinWriteIcon [::ChatWindow::Name $w] greyline 3 
		} 
		::amsn::WinWrite [::ChatWindow::Name $w] "\n" green
		::amsn::WinWriteIcon [::ChatWindow::Name $w] miniinfo 
		::amsn::WinWrite [::ChatWindow::Name $w] " Encyclopedia started at internet browser!\n" green
		
		# Write a seperated line to the chat window
		# Versions above 0.94 can use a graphical build-in line so I use this call
		if { $::version == "0.94" } {
				::amsn::WinWrite [::ChatWindow::Name $w] "--------------------------------------------------\n" gray_italic	 
		} else {
				::amsn::WinWriteIcon [::ChatWindow::Name $w] greyline 3 
		} 
	}
	
	#
	# This proc will translate a text 
	#
	proc translateText { w fromLang toLang } {
		set searchText [getSelectedText $w]
		if { $searchText == "" } {
			::amsn::messageBox "No text selected for translation!" ok error 
		} else { 

			set url "http://translate.google.com/translate_t?sl=$fromLang&tl=$toLang"
			set query [::http::formatQuery hl "en" ie "UTF8" text $searchText sl $fromLang tl $toLang]
		set http  [::http::geturl $url -query $query -timeout 72500]
		set html  [::http::data $http]
		
		# Set a language title
		switch $toLang {
				"nl" { set langTitle "Dutch" } 
				"es" { set langTitle "Spanish" }		
				"de" { set langTitle "German" }		
				"fr" { set langTitle "French"}		
				"it" { set langTitle "Italian"}		
				"pt" { set langTitle "Portuguese" }		
				"ru" { set langTitle "Russian" }		
				"el" { set langTitle "Greek" }
				"ja" { set langTitle "Japanese" }
				default { set langTitle "English" }
		}
		
		# Strip HTML before translated text 
		set substring "<div id=result_box dir=\"ltr\">"
		set start [string first $substring $html]
		set start [string first ">" $html $start]
		set start [expr { $start + 1 }]
		
		# Stript HTML after translated text
		puts $html
		set htmlPart [string range $html $start end]
		set end [expr { [string first "</" $htmlPart] - 1}]
		set translation [string range $htmlPart 0 $end]
		set translation [encoding convertfrom utf-8 $translation]
				
		# Write translated text to the chatwindow
		
		::amsn::WinWrite [::ChatWindow::Name $w] "\n" green
		
		# Write a seperated line to the chat window
		# Versions above 0.94 can use a graphical build-in line so I use this call
		if { $::version == "0.94" } {
				::amsn::WinWrite [::ChatWindow::Name $w] "--------------------------------------------------" gray_italic	 
		} else {
				::amsn::WinWriteIcon [::ChatWindow::Name $w] greyline 3 
		} 
		::amsn::WinWrite [::ChatWindow::Name $w] "\n" green
		::amsn::WinWriteIcon [::ChatWindow::Name $w] miniinfo 
		::amsn::WinWrite [::ChatWindow::Name $w] " Translated text to $langTitle:" green
		::amsn::WinWrite [::ChatWindow::Name $w] "\n$translation\n" gray
		
		# Write a seperated line to the chat window
		# Versions above 0.94 can use a graphical build-in line so I use this call
		if { $::version == "0.94" } {
				::amsn::WinWrite [::ChatWindow::Name $w] "--------------------------------------------------\n" gray_italic	 
		} else {
				::amsn::WinWriteIcon [::ChatWindow::Name $w] greyline 3 
		} 
		
		
		
		}
	}

	#
   # The deinitial procedure called when the plugin is unload by AMSN
	#
	proc deInit { } {
		
		# Unregister the events from the plugin
		::plugins::UnRegisterEvents "whatis"
		plugins_log "whatis" "plugin unregistered"
		
	}
	
} 
