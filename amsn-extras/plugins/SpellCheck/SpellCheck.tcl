##############################################
#   ::SpellCheck => Spell Checker for aMSN   #
#   ======================================   #
# SpellCheck requires aspell to be installed # 
# ------------------------------------------ #
#             By William Bowling             #
#            yadgor02@hotmail.com            #
##############################################


############################################
#I am not a Tcl programmer, so lots of this#
#code has been copied and modified slightly#
# for this plugin. Many methods have been  # 
#taken from the Nudge plugin.              #
# ---------------------------------------- #
#  The spell checker is based on a small   #   
#      script by Richard Suchenwirth       #
#          http://wiki.tcl.tk/88           #
############################################
namespace eval ::SpellCheck {
	variable config
	variable configlist
	

	######################################
	#    ::SpellCheck::InitPlug (dir)    #
	#------------------------------------#
	#Register events and initialize      #
	######################################
	proc InitPlugin { dir } {
		::plugins::RegisterPlugin SpellCheck
		::plugins::RegisterEvent SpellCheck chatwindowbutton checkspellbutton
		::plugins::RegisterEvent SpellCheck chat_msg_send AutoCheck
		::plugins::RegisterEvent SpellCheck Load pluginDidLoad
		
		::SpellCheck::LoadLangFiles $dir
		
		
		
		#set default values
		array set ::SpellCheck::config {
			location {Path to aspell}
			foreground {}
			background {red}
			autocheck {0}
			astyping {0}
			language {en}
			delay {2}
			fontstyle {}
			
		}
		
		set ::SpellCheck::configlist [list \
			[list str "[trans aspell_location]" location] \
			[list bool "[trans auto_check]" autocheck]  \
			[list bool "[trans check_as_typing]" astyping]  \
			[list frame ::SpellCheck::languageFrame ""] \
			[list frame ::SpellCheck::tagFrame ""] \
			[list ext "[trans removecols]" {resetCols}] \
		]
		::SpellCheck::LoadPixmaps $dir
		set ::SpellCheck::sendMsg 0
		
		
	}


	######################################
	# ::SpellCheck::LoadLangFiles (dir)  #
	#------------------------------------#
	#       Load the language files      #
	######################################
 	proc LoadLangFiles { dir } {
 		set langdir [file join $dir "lang"]
		set lang [::config::getGlobalKey language]
		load_lang en $langdir
		load_lang $lang $langdir
	}
 	
 	
 	###########################################
	# ::SpellCheck::pluginDidLoad event evpar #
	#-----------------------------------------#
	# If SpellCheck gets loaded, check for    #
	# aspell                                  #
	###########################################
 	proc pluginDidLoad {event evpar} {
 		upvar 2 $evpar newvar
 		if {$newvar(name)=="SpellCheck"} {
 			::SpellCheck::checkForAspell
 		}
 	
 	}
 	
 	
	######################################
	#    ::SpellCheck::checkForAspell    #
	#------------------------------------#
	#     Check some paths for aspell    #
	######################################
 	proc checkForAspell { } {
		if {![catch {exec $::SpellCheck::config(location)}]} {
			return
	 	} elseif {![catch {exec aspell -v}]} {
 			set ::SpellCheck::config(location) "aspell"
 		} elseif {![catch {exec "c:/program files/aspell/bin/aspell.exe" -v}] && [OnWin]} {
 			set ::SpellCheck::config(location) "c:/program files/aspell/bin/aspell.exe"
 		} elseif {![catch {exec /opt/local/bin/aspell -v}]} {
 			set ::SpellCheck::config(location) "/opt/local/bin/aspell"
 		} elseif {![catch {exec /usr/bin/aspell -v}]} {
 			set ::SpellCheck::config(location) "/usr/bin/aspell"
 		} elseif {![catch {exec /usr/local/bin/aspell -v}]} {
 			set ::SpellCheck::config(location) "/usr/local/bin/aspell"
 		} elseif {![catch {exec /sw/bin/aspell -v}]} {
 			set ::SpellCheck::config(location) "/sw/bin/aspell"
 		} else {
 			::SpellCheck::aspellNotFound
 		}
 	}
 	
 	
	######################################
	#   ::SpellCheck::languageFrame win  #
	#------------------------------------#
	#Drop down menu for choosing language#
	######################################	
 	proc languageFrame { win } {
 		frame $win.lang
 		label $win.lang.label -text "[trans lang_select]"
 		combobox::combobox $win.lang.accounts -editable false -highlightthickness 0 -bg #FFFFFF -font splainf -textvariable ::SpellCheck::config(language)
 		if {![catch {set dicts [exec $::SpellCheck::config(location) dicts]}]} {
			foreach aLang [split $dicts \n] {
				$win.lang.accounts list insert end $aLang
			}
		} else {
			$win.lang.accounts list insert end "[trans not_found]"
		}
		
		pack $win.lang.label -side left -anchor w
		pack $win.lang.accounts -side left -anchor w
		pack $win.lang -anchor w -padx 20
 	}
 	
 	 	
	######################################
	#     ::SpellCheck::tagFrame win     #
	#------------------------------------#
	#set up the frame for configuring the# 
	#incorrect spelling tag              #
	######################################		
  	proc tagFrame { win } {
 		frame $win.tag

 		label $win.tag.label -text "[trans showincorrect]"
 		
 		combobox::combobox $win.tag.options -editable false -highlightthickness 0 -bg #FFFFFF -font splainf -command ::SpellCheck::setTagOption
		
		#set up options
		$win.tag.options list insert end "[trans background]"
		$win.tag.options list insert end "[trans foreground]"
		$win.tag.options list insert end "[trans fontstyle]"
		
		#show what the incorect tag will look like
		label $win.tag.value -text "[trans example]" -highlightthickness 0  -font [regsub -all {\s} "[lindex [::config::getKey mychatfont] 0]" "\\ "] 
		
		#if no background colour has been set, use skin defined one
		if {$::SpellCheck::config(background) != {} } {
			$win.tag.value configure -background $::SpellCheck::config(background)
		} else {
			$win.tag.value configure -background [::skin::getKey chat_input_back_color]
		}
		
		#if no foreground colour has been set, use the users font colour
		if {$::SpellCheck::config(foreground) != {} } {
			$win.tag.value configure -foreground $::SpellCheck::config(foreground)
		} else {
			$win.tag.value configure -foreground "#[lindex [::config::getKey mychatfont] 2]"
		}
		if { $::SpellCheck::config(fontstyle) != {} } {
 			$win.tag.value configure -font $::SpellCheck::config(fontstyle)
 		}
		
		combobox::combobox $win.tag.font -editable false -highlightthickness 0 -bg #FFFFFF -font splainf -command ::SpellCheck::updateFontStyle
		$win.tag.font configure -value ""
		
		pack $win.tag.label -side left -anchor w
		pack $win.tag.options -side left -anchor w
		pack $win.tag.font -side left -anchor w
		pack $win.tag.value -side left -anchor w
	
		pack $win.tag -anchor w -padx 20
	
		
 	}
 	
 	proc updateFontStyle { widget value } {
 		set w [string replace $widget end-4 end ""]
 		
 		if { $value != {} } {
 			set ::SpellCheck::config(fontstyle) $value
 			$w.value configure -font $::SpellCheck::config(fontstyle)
 		}
 		update idletasks
 	}
 	
	###########################################
	# ::SpellCheck::setTagOption widget value #
	#-----------------------------------------#
	# if the user selects background or       #
	# foreground, show the colour picker. Show#
	# a list of they select fontstyle         #
	###########################################	
 	proc setTagOption { widget value } {
 		set w [string replace $widget end-7 end ""]
 		
 		switch -- $value {
			background {
				
				#hide other list if it is shown
				$w.font list delete 0 end
				$w.font configure -value ""
				#if a colour is already set, use it as the initial colour
				if {$::SpellCheck::config(background) != {} } {
					set theCol [tk_chooseColor -initialcolor $::SpellCheck::config(background)]
				} else {
					set theCol [tk_chooseColor]
				}
				
				#if a new colour is chosen, set the config.
				if { $theCol != "" } {
					set ::SpellCheck::config(background) $theCol
					$w.value configure -bg $::SpellCheck::config(background)
				}
			}
			foreground {
				#same as above
				$w.font list delete 0 end
				$w.font configure -value ""
				if {$::SpellCheck::config(foreground) != {} } {
					set theCol [tk_chooseColor -initialcolor $::SpellCheck::config(foreground)]
				} else {
					set theCol [tk_chooseColor]
				}
				if { $theCol != "" } {
					set ::SpellCheck::config(foreground) $theCol
					$w.value configure -fg $::SpellCheck::config(foreground)
				}
				#pack $w.value -side left -anchor w
			}
			fontstyle {
				if { [$w.font list get 0] == {} } {
					foreach aFont [split [font names] " "] {
						$w.font list insert end $aFont
					}
				}
				if { $::SpellCheck::config(fontstyle) != {} } {
					$w.font configure -value $::SpellCheck::config(fontstyle)
				}
				pack $w.font
			}
			
		}
		update idletasks
 	}
 	
 	
	######################################
	#      ::SpellCheck::resetCols       #
	#------------------------------------#
	# Removes all the set colours so that#
	# the incorrect tags will use the    #
	# skin background and users font.    #
	######################################
 	proc resetCols { } {
 		set ::SpellCheck::config(background) {}
 		set ::SpellCheck::config(foreground) {}
 		set ::SpellCheck::config(fontstyle) {}
 		
 		#not sure how to get this value yet...
 		set widget ".plugin_selector.winconf_SpellCheck.area.5.tag.value"
 		
		$widget configure -background [::skin::getKey chat_input_back_color]
		$widget configure -foreground "#[lindex [::config::getKey mychatfont] 2]"
		$widget configure -font [regsub -all {\s} "[lindex [::config::getKey mychatfont] 0]" "\\ "]
		tk_messageBox -message "[trans tagwarning]" -type ok -icon warning
 	}
 
 
 	###########################################
	# ::SpellCheck::languageFrame event evpar #
	#-----------------------------------------#
	#Stop the message being sent if there are #
	#errors in the text. If you send it again #
	#before the delay is up, it will send with#
	#the errors                               #
	###########################################
	proc AutoCheck {event evpar} {
		upvar 2 msg msg
		upvar 2 win_name win_name
    	if { $::SpellCheck::config(autocheck) } {
    		if {$::SpellCheck::sendMsg==1} {
    			set ::SpellCheck::sendMsg 0
    			[::ChatWindow::GetInputText $win_name] delete 0.0 end
    			return $msg
    		} else {
				set theInput [::ChatWindow::GetInputText $win_name]
				catch {menu $win_name.aMenu}
    			::SpellCheck::parseText $theInput $win_name.aMenu $win_name $msg
    			if {$::SpellCheck::numOfErrors==0} {
    				[::ChatWindow::GetInputText $win_name] delete 0.0 end
    				return $msg
    			} else {
    				set ::SpellCheck::sendMsg 1
    				set theTime [expr {int($::SpellCheck::config(delay)*1000)}]
    				after $theTime set ::SpellCheck::sendMsg 0
    				set msg ""
    				return $msg
    			}
    		}
    	}
	}
	
	
	
 	######################################
	#  ::SpellCheck::LoadPixmaps (dir)   #
	#------------------------------------#
	#Load the button images				 #
	######################################
	proc LoadPixmaps {dir} {
		::skin::setPixmap spellCheck checkSpelling.png pixmaps [file join $dir pixmaps]
		::skin::setPixmap spellCheck_Hover checkSpelling_hover.png pixmaps [file join $dir pixmaps]
	}
 
 
 
 	########################################
	# ::SpellCheck::changeLang x y winName #
	#--------------------------------------#
	#Allow the user to select a custom     #
	#language for certain users. If none   #
	#has been set for the user, the config #
	#one is used                           #
 	########################################
 	proc changeLang { x y winName} {
		set theUser [::ChatWindow::Name $winName] 		
 		catch {menu .changLangPopup}
 		.changLangPopup delete 0 end
 		
 		if {![catch {set dicts [exec $::SpellCheck::config(location) dicts]}]} {
			foreach aLang [split $dicts \n] {
				.changLangPopup add command -label $aLang -command "set ::SpellCheck::config($theUser) $aLang"
			}
		} else {
			.changLangPopup add command -label [trans not_found]
		}
 		tk_popup .changLangPopup $x $y
 	}
 
 
 
  	##############################################
	# ::SpellCheck::checkspellbutton event evpar #
	#--------------------------------------------#
	#Taken straight from the Nudge plugin.       #
	#Adds a button to the ChatWindow	         #
	##############################################
	proc checkspellbutton { event evpar } {
		upvar 2 $evpar newvar
		set winName $newvar(window_name)
		set spellCheckButton $newvar(bottom).checkSpelling
		set theInput [::ChatWindow::GetInputText $newvar(window_name)]
		menu $newvar(window_name).aMenu
		

		label $spellCheckButton -image [::skin::loadPixmap spellCheck] -relief flat -padx 0 \
		-background [::skin::getKey buttonbarbg] -highlightthickness 0 -borderwidth 0 \
		-highlightbackground [::skin::getKey buttonbarbg] -activebackground [::skin::getKey buttonbarbg] \
		
		bind $spellCheckButton <<Button1>> "::SpellCheck::parseText $theInput $newvar(window_name).aMenu $newvar(window_name) zzButtonWasPressed"
		bind $spellCheckButton <<Button3>> "::SpellCheck::changeLang %X %Y $winName"
		bind $spellCheckButton <Enter> "$spellCheckButton configure -image [::skin::loadPixmap spellCheck_Hover]"
		bind $spellCheckButton <Leave> "$spellCheckButton configure -image [::skin::loadPixmap spellCheck]"

		set_balloon $spellCheckButton "[trans ballon_text]"

		pack $spellCheckButton -side right
		
		#add the binds to check as the user is typing
		#after 0 so that the pressed key will be entered before the check happens
		if {$::SpellCheck::config(astyping)} {
			bind $theInput <Key-space> "after 0 ::SpellCheck::parseText $theInput $newvar(window_name).aMenu $newvar(window_name) zzButtonWasPressed"
			bind $theInput <.> "after 0 ::SpellCheck::parseText $theInput $newvar(window_name).aMenu $newvar(window_name) zzButtonWasPressed"
			bind $theInput <?> "after 0 ::SpellCheck::parseText $theInput $newvar(window_name).aMenu $newvar(window_name) zzButtonWasPressed"
			bind $theInput <!> "after 0 ::SpellCheck::parseText $theInput $newvar(window_name).aMenu $newvar(window_name) zzButtonWasPressed"
			bind $theInput <(> "after 0 ::SpellCheck::parseText $theInput $newvar(window_name).aMenu $newvar(window_name) zzButtonWasPressed"
			bind $theInput <)> "after 0 ::SpellCheck::parseText $theInput $newvar(window_name).aMenu $newvar(window_name) zzButtonWasPressed"
		}
	}

 
 
 	###################################################
	# ::SpellCheck::parseText textField aMenu win msg #
	#-------------------------------------------------#
	#       Based on Suchenwirth's spell checker.     #
	#-------------------------------------------------#
	#  Takes the text from the input, splits it into  #
	#  lines and then runs is through aspell. Then    #
	#  spiltsthe input into words and highlights any  #
	#  that aspell finds to be incorrect              #           
	###################################################
	proc parseText { textField aMenu win msg } {
		#if autochecking, put the text back in the textfield
		if {$msg!="zzButtonWasPressed"} {
			$textField insert 0.0 $msg
		}
		set ::SpellCheck::numOfErrors 0
		set lineno 1
		
		#remove any existing tags
		foreach aTag [$textField tag name] {$textField tag delete $aTag}
		
		#make sure invalid tag is not invisible
		if { $::SpellCheck::config(foreground)=={} && \
			 $::SpellCheck::config(background)=={} && \
			 $::SpellCheck::config(fontstyle)=={} } {
			 
			 	tk_messageBox -message "[trans tagwarning]" -type ok -icon warning
		}
		
		
		#set up the highlight tag
		if { $::SpellCheck::config(background) != {} } {
			$textField tag configure spelling -background $::SpellCheck::config(background)
		} else {
			$textField tag configure spelling -background [::skin::getKey chat_input_back_color]
		}
		
		if { $::SpellCheck::config(foreground) != {} } {
			$textField tag configure spelling -foreground $::SpellCheck::config(foreground)
		} else {
			$textField tag configure spelling -foreground "#[lindex [::config::getKey mychatfont] 2]"
		}
		if { $::SpellCheck::config(fontstyle) != {} } {
			$textField tag configure spelling -font $::SpellCheck::config(fontstyle)
		} else {
			$textField tag configure spelling -font {}
		}
		

		foreach line [split [$textField get 1.0 end-1c] \n] {
			set theCheck [runAspell $line $win]
			
			#start the counter at 1 to ignore first aspell output
			set counter 1
			
			foreach {from to} [getWordIndexes $line] {
				set word [string range $line $from [expr $to-1]]
					
					if { [lindex $theCheck $counter]=="#" || [lindex $theCheck $counter]=="?" || [lindex $theCheck $counter]=="&"} {
						incr ::SpellCheck::numOfErrors
						
						#when you click on a word, set up and show the suggestions
						$textField tag bind $word <<Button1>> "::SpellCheck::setUpMenu $textField $word $aMenu %X %Y $win"
						#add highlight tag
						$textField tag add spelling $lineno.$from $lineno.$to
						
						#add menu tag
						$textField tag add $word $lineno.$from $lineno.$to
						update idletasks
						
					}
					incr counter
				}
			incr lineno
		}
 	}
 
 
 
 	#####################################################
	# ::SpellCheck::addWord textField theWord win aMenu #
	#---------------------------------------------------#
	# adds the clicked word to the personal dictionary  #
	# for aspell. Language specific, so words will be   #
	# added to a custom en dictionary for english, fr   #
	# for french etc                                    #
	#####################################################
 	proc addWord { textField theWord win aMenu} {
		
 
 		
 		set theUser [::ChatWindow::Name $win]
 		if {[catch {list $::SpellCheck::config($theUser)}]} {
			set theLang $::SpellCheck::config(language)
		} else {
			set theLang $::SpellCheck::config($theUser)
		}
		
 		if { [OnWin] } {
			set loc $::SpellCheck::config(location)
			set loc [regsub -all {\s} $loc "\\\\ "]
 			if {[catch {set pipe [open "| $loc  -a" WRONLY]}]} {
 				::SpellCheck::aspellNotFound
 				return
			}	
 			fconfigure $pipe -buffering line -blocking 0
			puts $pipe *$theWord
			puts $pipe #
			close $pipe
		} else {
			set theWord "*$theWord\n#"
			if {[catch {exec echo $theWord | $::SpellCheck::config(location) -a --lang=$theLang}]} {
				::SpellCheck::aspellNotFound
				return
			}
		}
		$textField tag remove $theWord 1.0 end
		after 200 ::SpellCheck::parseText $textField $aMenu $win zzButtonWasPressed
 	}
 
 
 
	####################################
	#    ::SpellCheck::aspellNotFound  #
	#----------------------------------#
	#   Alert if aspell is not found   #
	#################################### 
 	proc aspellNotFound { } {
		set answer [tk_messageBox -type yesno -default yes -icon question -message [trans aspell_not_found]]
		switch -- $answer { 
			yes { 
				::plugins::PluginGui
				
				#catch for amsn v0.95
				if {![catch {set ::plugins::selection SpellCheck}]} {
					::plugins::GUI_Config
				}
			}
		}
	}
	
	
	
 	############################################
	#   ::SpellCheck::runAspell theWords win   #
	#------------------------------------------#
	#Send the line of text to aspell and return#
	#     a single character for each word     #
	#------------------------------------------#
	#       *    means word correct            #
	#    ? or #  means word incorrect          #
	############################################
	proc runAspell { theWords win } {
		
		set formattedResults {}

		set theUser [::ChatWindow::Name $win]
				#does the user have a custom language set?
		if {[catch {list $::SpellCheck::config($theUser)}]} {
			set theLang $::SpellCheck::config(language)
		} else {
			set theLang $::SpellCheck::config($theUser)
		}
		
		#aspell removes all numbers from the input
		#replace with "a" so they always return correct
		set theWords [regsub -all {[0-9_]+} $theWords " "]
		
		set theWords [regsub -all {[(\<\>\@\|\*\#\&)]} $theWords "\\\\&"]
		
		#get aspell results
		if { [OnWin]} {
			if {[catch {set aspellResult [exec cmd /c echo $theWords | $::SpellCheck::config(location) -a --lang=$theLang]}]} {
				::SpellCheck::aspellNotFound
				return
			}
		} else {
			if {[catch {set aspellResult [exec echo $theWords | $::SpellCheck::config(location) -a --lang=$theLang]}]} {
				::SpellCheck::aspellNotFound
				return
			}
		}
		#fix a bug that displays 2 results on the same line occasionally
		set aspellResult [regsub -all {(\w)([\*\?\#])(\n)} $aspellResult {\1\3\2\3}]
		foreach line [split $aspellResult \n] {
			lappend formattedResults [string range $line 0 0]
		}
		
		return $formattedResults
	}



 	##########################################
	#     ::SpellCheck::getWordIndexes s     #
	#----------------------------------------#
	#  Based on Suchenwirth's spell checker  #
	#----------------------------------------#
	# Returns the start and end index of the #
	#  words, doesn't count non-alphanumeric #
	# characters to be consistent with aspell#
	##########################################
	proc getWordIndexes s {
		set i 0
		set res {}
		set s [string tolower $s]
		
		#replace all ' so the right words get highlighted
		set s [regsub -all {'} $s "a"]
		set s [regsub -all {[0-9_]} $s " "]
		foreach c [split $s ""] {
			if {$c ne " " && $i eq [string wordstart $s $i] } {
			
				#tcl counts punctuation as words and aspell doesnt,
				#so only count alphanumeric characters as words
				if {![regexp {[^a-z\s]} $c]} {
					lappend res $i [string wordend $s $i]
					
				}
			}
			incr i
		}
		set res
	}



 	#################################################
	# ::SpellCheck::setUpMenu w aWord aMenu x y win #
	#-----------------------------------------------#
	#Called when a user clicks on a highlighted	word#
	#It gets a list of suggestions from   aspell,   #
	#create a popup menu with the items. When the   #
	#user selects a word, delete the incorrect word #
	#and replace it with the new one.               #                       
	#################################################
	proc setUpMenu {input aWord aMenu x y win} {
		
		#delete old popup menu items
		$aMenu delete 0 end
		
		set tempListOfWords {}
		set theList {}
		set theUser [::ChatWindow::Name $win]
		
		#use the user's language if set
		if {[catch {list $::SpellCheck::config($theUser)}]} {
			set theLang $::SpellCheck::config(language)
		} else {
			set theLang $::SpellCheck::config($theUser)
		}
		
		if { [OnWin] } {
			if {[catch {set suggestions [exec cmd /c echo $aWord | $::SpellCheck::config(location) --lang=$theLang -a]}]} {
				::SpellCheck::aspellNotFound
				return
			}
		} else {
			if {[catch {set suggestions [exec echo $aWord | $::SpellCheck::config(location) --lang=$theLang -a]}]} {
				::SpellCheck::aspellNotFound
				return
			}
		}
 		foreach line [split $suggestions \n] {
 			lappend tempListOfWords $line
 		}
 		
 		#discard first information line
 		foreach word [split [lindex $tempListOfWords 1] ", "] {
 			if {$word != "" } {
 				lappend theList $word
			}
		}
		
		#remove the incorrect word and unneeded values
 		set theList [lreplace $theList 0 3]
 		
 		foreach changeWord $theList {
 			$aMenu add command -label $changeWord -command "::SpellCheck::replaceWord $input $changeWord $aWord"
 		}
 		$aMenu add command -label "[trans addword]" -command "::SpellCheck::addWord $input $aWord $win $aMenu"
 		tk_popup $aMenu $x $y
	}



 	#########################################################
	# ::SpellCheck::replaceWord w replaceWith wordToReplace #
	#-------------------------------------------------------#
	#When the user chooses a word from the menu, replace the#
	#incorrect word with the new one                        #
	#########################################################
	proc replaceWord { w replaceWith wordToReplace } {
		foreach {start end} [$w tag ranges $wordToReplace] {
			$w delete $start $end
			
			#amsn was doing some weird random selecting so:
			$w tag remove sel 0.0 end
			
			#reposition the insert marker
			$w mark set insert $start
			$w insert insert $replaceWith
			
			#decrease the number of incorrect words
			incr ::SpellCheck::numOfErrors -1
			
			#only do one occurrence of the word because it wont replace the
			#right spot if the chosen word is a different length
			break
		}
	}
}

