#######################################################
#                  REMIND PLUGIN                      #
#######################################################
# Maintainer: Frederic Diaz (gadget_boy@users.sf.net) #
#  updated and speeded up by Karel "scapor" Demeyer   #
#######################################################


namespace eval ::remind {

##############################
# ::remind::InitPlugin dir   #
# ---------------------------#
# Load proc of Remind Plugin #
##############################

proc InitPlugin { dir } {
	::plugins::RegisterPlugin remind
	::plugins::RegisterEvent remind new_conversation Remind



	# Loads langsset langdir [file join $dir "lang"]

	set lang [::config::getGlobalKey language]
	set langdir [file join $dir "lang"]
	load_lang en $langdir
	load_lang $lang $langdir

	array set ::remind::config [list beginend {1} daysnumber {7} filetransfert {1} nbline {10} checknote {1} when {1}]
	set ::remind::configlist [list \
		[list str "[trans nbdisplay]" nbline] \
		[list rbt "[trans always]" "[trans talklast]" "[trans talkwithin]" when] \
		[list str "[trans daysnumber]" daysnumber] \
		[list bool "[trans beginendconversation]" beginend] \
		[list bool "[trans filetransfert]" filetransfert] \
		[list bool "[trans checknote]" checknote] \
	]
	

}


################################################################
# ::remind::Remind event epvar                                 #
# ------------------------------------------------------------ #
# Tell the other procs what to do according to the preferences #
################################################################

proc Remind { event evpar } {

	plugins_log remind "New conversation window.  Let's check if we need to digg up messages for you, sir."

	upvar 2 $evpar parameters

	set chatid $parameters(chatid)
	set email $parameters(usr_name)

	set lastmessage [clock scan [string range [::abook::getContactData $email last_msgedme] 0 7] ]

	set date [clock scan [clock format [clock seconds] -format "%D"]]

	set timeline [expr { $::remind::config(daysnumber) * 86400 }]

	if { $::remind::config(when) == 1
		|| ( $::remind::config(when) == 2 && [expr { $date - $lastmessage }] <= $timeline )
		|| ( $::remind::config(when) == 3 && [expr { $date - $lastmessage }] >= $timeline )
	} {
		plugins_log remind "You wanted mle to show some messages, so that's what I'm about to do..."
		::remind::ShowLastSentences $chatid $email
	}

	if { $::remind::config(checknote) == 1 } {
		::remind::CheckNote $chatid $email
	}	
}
	

################################################
# ::remind::ShowLastSentences chatid email     #
# -------------------------------------------- #
# Display the last sentences in the chatwindow #
################################################

proc ShowLastSentences { chatid email } {

	plugins_log remind "So, here we go, get ready to rumble!"

	# Get the last sentences of the contact
	set loglines [::remind::GetLastSentences $email]
	set tagname "black"
	set font [lindex [::config::getGlobalKey basefont] 0]
	if { $font == "" } { set font "Helvetica" }		
	set fontformat [list "" "" ""]

	set win_name [::ChatWindow::For $chatid]

	# Allow something to be written into the chat window
	set textw [::ChatWindow::GetOutText ${win_name}]
	$textw configure -state normal -font bplainf -foreground black

	# Set up formatting tags
	$textw tag configure red -foreground red
	$textw tag configure RED -foreground red
	$textw tag configure gray -foreground gray
	$textw tag configure GRA -foreground gray
	$textw tag configure normal -foreground black
	$textw tag configure NOR -foreground black
	$textw tag configure italic -foreground blue
	$textw tag configure ITA -foreground blue
	$textw tag configure GRE -foreground darkgreen

	::remind::WinWrite "$chatid" "[trans lastsentence] :\n" blue

	set nbline 0
	foreach line $loglines {
		incr nbline
		set aidx 0
		while {$aidx != -1} {
			# Checks if the line begins by |"L (it happens when we go to the line in the chat window).
			# If not, use the tags of the previous line
			if { $aidx == 0 & [string range $line 0 2] != "\|\"L" } {
				set bidx -1
			} else {
				# If the portion of the line begins by |"LC, there is a color information.
				# The color is indicated by the 6 fingers after it
				if {[string index $line [expr {$aidx + 3}]] == "C"} {
					set color [string range $line [expr {$aidx + 4}] [expr {$aidx + 9}]]
					$textw tag configure C_$nbline -foreground "#$color"
					set color "C_$nbline"
					incr aidx 10
					# Else, it is the system with LNOR, LGRA...
				} else {
					if {[string range $line $aidx [expr {$aidx + 6}]] == "\|\"LTIME"  } {
						#it is a time in [clock seconds]
						incr aidx 7
						#add formated date/time stamp to the log output
						#search a non digit character since on older version, there wasn't always a space after the timestamp
						regexp -start $aidx -indices {\D} $line sidx
						set sidx [lindex $sidx 0]
						incr sidx -1
						::remind::WinWrite $chatid [::log::LogDateConvert [string range $line $aidx $sidx]] $color
						set aidx $sidx
						incr aidx 1
					} else {
						set color [string range $line [expr {$aidx + 3}] [expr {$aidx + 5}]]
						incr aidx 6
					}
				}
				set bidx [string first "\|\"L" $line $aidx]
			}
			if { [string first "\|\"L" $line] == -1 } {
				set string [string range $line 0 end]
			} elseif { $bidx != -1 } {
				set string [string range $line $aidx [expr {$bidx - 1}]]
			} else {
				set string [string range $line $aidx end]
			}
			if {$string != ""} {
				::remind::WinWrite $chatid "$string" $color
			}
			set aidx $bidx
		}
		if {$string != ""} {
			::remind::WinWrite $chatid "\n" black
		}
	}

	plugins_log remind "There's your text sir.  You want any smileys with it ? \nYes I know you want.  Here they are ..."

	#substitute the smileys
	::smiley::substSmileys [::ChatWindow::GetOutText ${win_name}] 0.0 end 0 1]

	::amsn::WinWriteIcon $chatid greyline 3	

	[::ChatWindow::GetOutText $win_name] yview end
	[::ChatWindow::GetOutText ${win_name}] configure -state normal -font bplainf -foreground black


}


#############################################
# ::remind::GetLastSentence email           #
# ----------------------------------------- #
# It gets the last sentences of the contact #
#############################################

proc GetLastSentences { email } {
	plugins_log remind "Getting you messages for $email ..."
	global log_dir

	# Select the last logging file, and cancel the proc if there is no log file yet
	if { [file exists [file join ${log_dir} ${email}.log]] == 1 } {
		set id [open "[file join ${log_dir} ${email}.log]" r]
		set size [file size [file join ${log_dir} ${email}.log]]
	} elseif {[::config::getKey logsbydate] == 1} {
		set date_list [list]
		set erdate_list [list]
		foreach date [glob -nocomplain -types f [file join ${log_dir} * ${email}.log]] {
			set date [getfilename [file dirname $date]]
			if { [catch { clock scan "1 $date"}] == 0 } {
				lappend date_list  [clock scan "1 $date"]
			} else {
				lappend erdate_list $date
			}
		}
		set sorteddate_list [lsort -integer -decreasing $date_list]

		set date [lindex $sorteddate_list 0]
		set date "[clock format $date -format "%B"] [clock format $date -format "%Y"]"

		set id [open [file join ${log_dir} ${date} ${email}.log] r]

	} else {
		return
	}

	fconfigure $id -encoding utf-8
	
	if { $size > 16384 } {
		#Avoid loading the full log if it's too big
		seek $id [expr {$size - 16384}]
		set logvar [read $id 16384]
	} else {
		set logvar [read $id $size]
	}

	close $id

	# Select the $nbline last lines
	set loglines [split $logvar "\n"]
	#status_log "LOG_LINES 1 = $loglines" green
	set nbline [expr {int($::remind::config(nbline))}]
	set begin [expr {[llength $loglines] - $nbline}]
	while {[string range [lindex $loglines $begin] 0 2] != "\|\"L" && $begin >= 0 } {
		incr begin -1;
	}
	set loglines [lrange $loglines $begin end]
	#status_log "LOG_LINES 2 = $loglines" green
	return $loglines

}


##############################################
# ::remind::CheckNote email                  #
# ------------------------------------------ #
# Check if there are notes about the contact #
##############################################

proc CheckNote { chatid email } {

	global HOME

	set file [file join $HOME notes ${email}_note.xml]
	
	if { [file exists $file] } {
		status_log "REMIND : OK\n" red
		::remind::WinWrite "$chatid" "\n[trans noteswritten]\n" blue

	}
	
}


####################################################
# ::remind::WinWrite chatid txt tagname fontformat #
# ------------------------------------------------ #
# Light version of ::amsn::WinWrite (faster)       #
####################################################

proc WinWrite {chatid txt tagname {fontformat ""}} {


	set win_name [::ChatWindow::For $chatid]

	if { [::ChatWindow::For $chatid] == 0} {
		return 0
	}

	set fontname [lindex $fontformat 0]
	set fontstyle [lindex $fontformat 1]      
	set fontcolor [lindex $fontformat 2]

	set tagid $tagname

	if { $tagid == "user" } {
		set size [expr {[lindex [::config::getGlobalKey basefont] 1]+[::config::getKey textsize]}]
		set font "\"$fontname\" $size $fontstyle"
		set tagid [::md5::md5 "$font$fontcolor"]

		[::ChatWindow::GetOutText ${win_name}] tag configure $tagid -foreground #$fontcolor -font $font
	}

	[::ChatWindow::GetOutText ${win_name}] roinsert end "$txt" $tagid

}


}
