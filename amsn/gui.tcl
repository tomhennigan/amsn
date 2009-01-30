
::Version::setSubversionId {$Id$}

if { $initialize_amsn == 1 } {

	if {![::picture::Loaded]} {
		if { [OnDarwin] } {	
			tk_messageBox -default ok -message "There's a problem loading a module of aMSN (TkCxImage) on this \
			computer. You need to update your system to Mac OS 10.3.9" -icon warning	
		} else {
			tk_messageBox -default ok -message "Loading TkCximage failed. This module is needed to run \
			aMSN. Please compile aMSN first, instructions on how to compile are located in the file INSTALL" \
			    -icon warning
		}
		exit
	}

	package require BWidget
	source BWidget_mods.tcl
	
	if {[catch {package require -exact tkdnd 1.0}] } {
		proc dnd { args } {}
		proc shape { args } {}
	}

	if { [version_vcompare [info patchlevel] 8.4.13] >= 0} {
		package require snit
	} else {
		source utils/snit/snit.tcl
	}
	
	#package require pixmapbutton
	if { [OnMac] } {
		# Use brushed metal style windows on Mac OS X.
		catch {package require tkUnsupported}
		# tclCarbon has tclCarbonHICommand, and tclCarbonNotification...
		catch {package require tclCarbon}
		catch {package require QuickTimeTcl}
		catch {load utils/macosx/Quicktimetcl3.1/quicktimetcl3.1.dylib}
	} else {
		package require pixmapscroll
	}
	
	::skin::setKey mainwindowbg #7979f2
	::skin::setKey contactlistbg #ffffff
	::skin::setKey contactlistborderbg #ffffff
	::skin::setKey contactlistbd 0
	::skin::setKey topcontactlistbg #ffffff
	::skin::setKey bannerbg #ffffff
	::skin::setKey contact_mobile #404040
	::skin::setKey chatwindowbg #EAEAEA

	::skin::setKey loginbg #ffffff
	::skin::setKey loginwidgetbg #ffffff
	::skin::setKey loginfg #000000
	::skin::setKey loginurlfg #0000ff
	::skin::setKey logincheckfg #ffffff
	::skin::setKey loginbuttonbg #c3c2d2
	::skin::setKey loginbuttonfg black
	::skin::setKey loginbuttonfghover black

	::skin::setKey tabbarbg "[::skin::getKey chatwindowbg]"
	::skin::setKey tabfg #000000
	::skin::setKey tab_text_x 5
	::skin::setKey tab_text_y 5
	::skin::setKey tab_text_width 80
	::skin::setKey tab_close_x 85
	::skin::setKey tab_close_y 5
	::skin::setKey chat_tabbar_padx 0
	::skin::setKey chat_tabbar_pady 0
	::skin::setKey buttonbarbg #eeeeff
	::skin::setKey sendbuttonbg #c3c2d2
	::skin::setKey sendbuttonfg black
	::skin::setKey sendbuttonfghover black
	::skin::setKey topbarbg #5050e5
	::skin::setKey topbarbg_sel #d3d0ce
	::skin::setKey topbartext #ffffff
	::skin::setKey topbarborder #000000
	::skin::setKey topbarawaybg #00AB00
	::skin::setKey topbarawaybg_sel #d3d0ce
	::skin::setKey topbarawaytext #000000
	::skin::setKey topbarawayborder #000000
	::skin::setKey topbarbusybg #CF0000
	::skin::setKey topbarbusybg_sel #d3d0ce
	::skin::setKey topbarbusytext #000000
	::skin::setKey topbarbusyborder #000000
	::skin::setKey topbarofflinebg #404040
	::skin::setKey topbarofflinebg_sel #d3d0ce
	::skin::setKey topbarofflinetext #ffffff
	::skin::setKey topbarofflineborder #000000
	::skin::setKey topbaridlebg #dfe7f0
	::skin::setKey topbaridletext #000000
	::skin::setKey topbaridleborder #7da0af
	::skin::setKey topbarbrbbg #dfe7f0
	::skin::setKey topbarbrbtext #000000
	::skin::setKey topbarbrbborder #7da0af
	::skin::setKey topbarphonebg #dfe7f0
	::skin::setKey topbarphonetext #000000
	::skin::setKey topbarphoneborder #7da0af
	::skin::setKey topbarlunchbg #dfe7f0
	::skin::setKey topbarlunchtext #000000
	::skin::setKey topbarlunchborder #7da0af

	::skin::setKey topbarpadx 6
	::skin::setKey topbarpady 6
	::skin::setKey loginbuttonx 6
	::skin::setKey loginbuttony 6
	::skin::setKey sendbuttonx 6
	::skin::setKey sendbuttony 6
	::skin::setKey chat_top_pixmap 0
	
	::skin::setKey statusbarbg #eeeeee
	::skin::setKey statusbarbg_sel #d3d0ce
	::skin::setKey statusbartext #000000
	::skin::setKey groupcolorextend #000080
	::skin::setKey groupcolorcontract #000080

	::skin::setKey chat_top_padx 0
	::skin::setKey chat_top_pady 0
	::skin::setKey chat_paned_padx 0
	::skin::setKey chat_paned_pady 0
	::skin::setKey chat_output_padx 0
	::skin::setKey chat_output_pady 0
	::skin::setKey chat_buttons_padx 0
	::skin::setKey chat_buttons_pady 0
	::skin::setKey chat_input_padx 0
	::skin::setKey chat_input_pady 0
	::skin::setKey chat_dp_padx 0
	::skin::setKey chat_dp_pady 0
	::skin::setKey chat_leftframe_padx 0
	::skin::setKey chat_leftframe_pady 0
	::skin::setKey chat_sendbutton_padx 0
	::skin::setKey chat_sendbutton_pady 0
	::skin::setKey chat_status_padx 0
	::skin::setKey chat_status_pady 0
	::skin::setKey chat_sash_width 2
	::skin::setKey chat_sash_relief raised
	::skin::setKey chat_sash_showhandle 0
	::skin::setKey chat_sash_pady 0

	::skin::setKey chat_status_border_color #000000
	::skin::setKey chat_output_border_color #000000
	::skin::setKey chat_output_back_color #ffffff
	::skin::setKey chat_input_border_color #000000
	::skin::setKey chat_input_back_color #ffffff
	::skin::setKey chat_buttons_border_color #000000
	::skin::setKey chat_dp_border_color #000000

	::skin::setKey chat_top_border 0
	::skin::setKey chat_output_border 0
	::skin::setKey chat_buttons_border 0
	::skin::setKey chat_input_border 0
	::skin::setKey chat_status_border 0
	::skin::setKey chat_dp_border 1
	
	::skin::setKey chat_show_sendbuttonframe 1
	::skin::setKey chat_show_statusbarframe 1
	::skin::setKey chat_show_topframe 1

	::skin::setKey menuforeground #000000
	::skin::setKey menuactivebackground #565672
	::skin::setKey menuactiveforeground #ffffff
	::skin::setKey mystatus grey
	::skin::setKey buddylistpad 4
	::skin::setKey showdisplaycontactlist 0
	::skin::setKey emailabovecolorbar 0
	::skin::setKey underline_contact 0
	::skin::setKey underline_group 0
	::skin::setKey changecursor_contact 1
	::skin::setKey changecursor_group 1		
	::skin::setKey bigstate_xpad 0
	::skin::setKey bigstate_ypad 0
	::skin::setKey mystatus_xpad 3
	::skin::setKey mystatus_ypad 0
	::skin::setKey mailbox_xpad 2
	::skin::setKey mailbox_ypad 2
	::skin::setKey contract_xpad 8
	::skin::setKey contract_ypad 6
	::skin::setKey expand_xpad 8
	::skin::setKey expand_ypad 6
	::skin::setKey x_dp_top 4
	::skin::setKey y_dp_top 4
	::skin::setKey balloonbackground #daeefe
	::skin::setKey balloonborderwidth 1
	::skin::setKey balloonborder #2e8afe
	::skin::setKey balloontext #0000dd
	::skin::setKey buddy_xpad 15
	::skin::setKey buddy_ypad 3

	::skin::setKey notifwidth 150
	::skin::setKey notifheight 100
	::skin::setKey notifyfg black
	::skin::setKey x_notifyclose 140
	::skin::setKey y_notifyclose 2
	::skin::setKey x_notifydp 1
	::skin::setKey y_notifydp 22
	::skin::setKey x_notifytext 55
	::skin::setKey y_notifytext 22
	::skin::setKey width_notifytext 93
	::skin::setKey notify_font sboldf
	::skin::setKey notify_dp_border 0

	if { [OnMac] } {
		::skin::setKey balloonbackground #ffffca
		::skin::setKey menubackground #ECECEC
	} else {
		::skin::setKey balloonbackground #ffffaa
		::skin::setKey menubackground #eae7e4
	}
	::skin::setKey balloonfont sboldf
	::skin::setKey balloonborder #000000
	::skin::setKey balloonalpha 0.9

	::skin::setKey assistanttitleheight 50
	::skin::setKey assistanttitlefg #FFFFFF
	::skin::setKey assistanttitlebg #565672

	
	::skin::setKey extrastdwindowcolor #efefef
	::skin::setKey extrastdbgcolor #ffffff
	::skin::setKey extrastdtxtcolor #333333
	::skin::setKey extraselectedtxtcolor #222222
	::skin::setKey extraselectedbgcolor #dddddd
	::skin::setKey extradisabledtxtcolor #666666
	::skin::setKey extradisabledbgcolor #efefef
	::skin::setKey extrastderrcolor #FF0000
	::skin::setKey extrastdokcolor #559c2a
	::skin::setKey extralistboxselected #0000FF
	::skin::setKey extralistboxselectedbg #ffffff
	::skin::setKey extralistboxtitlebg #ffffff
	::skin::setKey extralistboxtitlefg #000000
	::skin::setKey extrabuttonbgcolor #efefef
	::skin::setKey extrabuttontxtcolor #333333
	::skin::setKey extrabuttonbgcoloractive #dddddd
	::skin::setKey extrabuttontxtcoloractive #222222
	::skin::setKey extralinkcolor #0000FF
	::skin::setKey extralinkcoloractive #6931CA
	::skin::setKey extralinkbgcoloractive #ffffff
	::skin::setKey extracheckbuttonselectedcolor #ff0000

	::skin::setKey extraprivacy_old_bg #000000
	::skin::setKey extraprivacy_old_fg #FF8F8F
	::skin::setKey extraprivacy_notrl_bg #FF6060
	::skin::setKey extraprivacy_notrl_fg #A00000
	::skin::setKey extraprivacy_notfl_bg #FFFF80
	::skin::setKey extraprivacy_notfl_fg #A00000
	::skin::setKey extraprivacy_intoal_fg #008000
	::skin::setKey extraprivacy_intobl_fg #A00000

	::skin::setKey loginurlfghover #6931CA
	::skin::setKey emailfg #000000
	::skin::setKey emailhover #000000
	::skin::setKey emailhoverbg #ffffff

	::skin::setKey tabfg_hover #333333
	
	::skin::setKey statusbartext_sel #000000
	
	#Virtual events used by Button-click
	#On Mac OS X, Control emulate the "right click button"
	#On Mac OS X, there's a mistake between button2 and button3
	if { [OnMac] } {
		event add <<Button1>> <Button1-ButtonRelease>
		event add <<Button1-Press>> <ButtonPress-1>
		event add <<Button1-Motion>> <B1-Motion>
		event add <<Button2>> <Button3-ButtonRelease>
		event add <<Button2-Press>> <ButtonPress-3>
		event add <<Button2-Motion>> <B3-Motion>
		event add <<Button3>> <Control-ButtonRelease>
		event add <<Button3>> <Button2-ButtonRelease>
		event add <<Button3-Press>> <ButtonPress-2>
		event add <<Button3-Motion>> <B2-Motion>
		event add <<Escape>> <Command-w> <Command-W>
		event add <<Paste>> <Command-v> <Command-V>
		event add <<Copy>> <Command-c> <Command-C>
		event add <<Cut>> <Command-x> <Command-X>
	} elseif { [OnMaemo] } {
                event add <<Button1>> <Button1-ButtonRelease>
                event add <<Button1-Press>> <ButtonPress-1>
                event add <<Button1-Motion>> <B1-Motion>
                event add <<Button2>> <Button2-ButtonRelease>
                event add <<Button2-Press>> <ButtonPress-2>
                event add <<Button2-Motion>> <B2-Motion>
		event add <<Button3>> <Control-ButtonRelease>
		event add <<Button3-Press>> <Control-ButtonPress>
		event add <<Button3-Motion>> <B3-Motion>
                event add <<Escape>> <Escape>
                event add <<Paste>> <Control-v> <Control-V>
                event add <<Copy>> <Control-c> <Control-C>
                event add <<Cut>> <Control-x> <Control-X>
	} else {
		event add <<Button1>> <Button1-ButtonRelease>
		event add <<Button1-Press>> <ButtonPress-1>
		event add <<Button1-Motion>> <B1-Motion>
		event add <<Button2>> <Button2-ButtonRelease>
		event add <<Button2-Press>> <ButtonPress-2>
		event add <<Button2-Motion>> <B2-Motion>
		event add <<Button3>> <Button3-ButtonRelease>
		event add <<Button3-Press>> <ButtonPress-3>
		event add <<Button3-Motion>> <B3-Motion>
		event add <<Escape>> <Escape>
		event add <<Paste>> <Control-v> <Control-V>
		event add <<Copy>> <Control-c> <Control-C>
		event add <<Cut>> <Control-x> <Control-X>
	}

	if { [OnLinux] } {
		#Mappings for Shift-BackSpace
		bind Entry <Terminate_Server> [bind Entry <BackSpace>]
		bind Text <Terminate_Server> [bind Text <BackSpace>]
	}

	#This proc bugs anyway
	rename ::tk::FirstMenu ::tk::Original_FirstMenu
	proc ::tk::FirstMenu { args } { }

	#To avoid a bug inside panedwindow, by Youness
	rename ::tk::panedwindow::Cursor ::tk::panedwindow::Original_Cursor
	proc ::tk::panedwindow::Cursor { args } {
		catch { eval ::tk::panedwindow::Original_Cursor $args }
	}

	#For proc WinWrite
	namespace eval ::amsn {
		variable urlcount 0
		set urlstarts { "http://" "https://" "ftp://" "www." }
	}

	#For idle checking
	global idletime oldmousepos autostatuschange
	set idletime 0
	set oldmousepos [list]
	set autostatuschange 0
}

namespace eval ::amsn {

	namespace export initLook aboutWindow showHelpFile errorMsg infoMsg \
		blockUnblockUser blockUser unblockUser deleteUser removeUserFromGroup \
		fileTransferRecv fileTransferProgress \
		errorMsg notifyAdd initLook messageFrom userJoins userLeaves \
		updateTypers ackMessage nackMessage chatUser


	##PUBLIC

	proc initLook { family size bgcolor} {
		font create menufont -family $family -size $size -weight normal
		font create sboldf -family $family -size $size -weight bold
		font create splainf -family $family -size $size -weight normal
		font create sunderf -family $family -size $size -weight normal -underline yes
		font create sboldunderf -family $family -size $size -weight bold -underline yes
		font create sbolditalf -family $family -size $size -weight bold -slant italic
		font create sitalf -family $family -size $size -slant italic
		font create macfont -family [list {Lucida Grande}] -size 13 -weight normal

		if { [::config::getKey strictfonts] } {
			font create bboldf -family $family -size $size -weight bold
			font create bboldunderf -family $family -size $size -weight bold -underline true
			font create bplainf -family $family -size $size -weight normal
			font create bsunderf -family $family -size $size -weight normal -underline yes
			font create bigfont -family $family -size $size -weight bold
			font create examplef -family $family -size $size -weight normal
		} else {
			font create bboldf -family $family -size [expr {$size+1}] -weight bold
			font create bboldunderf -family $family -size [expr {$size+1}] -weight bold -underline true
			font create bplainf -family $family -size [expr {$size+1}] -weight normal
			font create bsunderf -family $family -size [expr {$size+1}] -weight normal -underline true
			font create bigfont -family $family -size [expr {$size+2}] -weight bold
			font create examplef -family $family -size [expr {$size-1}] -weight normal
		}

		catch {tk_setPalette [::skin::getKey menubackground]}
		option add *Menu.font menufont

		option add *Canvas.highlightThickness 0
		option add *Photo.format cximage widgetDefault

		option add *Font splainf userDefault
		option add *background [::skin::getKey extrastdwindowcolor]
		option add *foreground [::skin::getKey extrastdtxtcolor]
		option add *activeBackground [::skin::getKey extrabuttonbgcoloractive]
		option add *activeForeground [::skin::getKey extrabuttontxtcoloractive]
		option add *selectColor [::skin::getKey extracheckbuttonselectedcolor]

		option add *Combobox.buttonBackground [::skin::getKey extrastdbgcolor]
		option add *Combobox.background [::skin::getKey extrastdbgcolor]

		if { ![OnMac] } {
			option add *borderWidth 1 widgetDefault
			option add *activeBorderWidth 1 widgetDefault
			option add *selectBorderWidth 1 widgetDefault
			option add *highlightThickness 0 widgetDefault
			option add *troughColor #c3c3c3 widgetDefault

			option add *Frame.borderWidth 2 widgetDefault
			option add *Frame.background [::skin::getKey extrastdwindowcolor]
			option add *Frame.foreground [::skin::getKey extrastdtxtcolor]

			option add *Labelframe.borderWidth 2 widgetDefault
			option add *Labelframe.padY 8 widgetDefault
			option add *Labelframe.padX 12 widgetDefault
			option add *Labelframe.background [::skin::getKey extrastdwindowcolor]
			option add *Labelframe.foreground [::skin::getKey extrastdtxtcolor]

			option add *Label.foreground [::skin::getKey extrastdtxtcolor]

			option add *Entry.borderWidth 1 widgetDefault
			option add *Entry.selectBorderWidth 0 widgetDefault
			option add *Entry.padX 2 widgetDefault
			option add *Entry.padY 4 widgetDefault
			option add *Entry.background [::skin::getKey extrastdbgcolor]
			option add *Entry.foreground [::skin::getKey extrastdtxtcolor]
			option add *Entry.disabledBackground [::skin::getKey extradisabledbgcolor] 
			option add *Entry.disabledForeground [::skin::getKey extradisabledtxtcolor]
			option add *Entry.selectBackground [::skin::getKey extraselectedbgcolor]
			option add *Entry.selectForeground [::skin::getKey extraselectedtxtcolor]

			option add *Text.selectBorderWidth 0 widgetDefault
			option add *Text.padX 2 widgetDefault
			option add *Text.padY 4 widgetDefault


			option add *Text.background [::skin::getKey extrastdbgcolor]
			option add *Text.foreground [::skin::getKey extrastdtxtcolor]
			option add *Text.disabledBackground [::skin::getKey extradisabledbgcolor] 
			option add *Text.disabledForeground [::skin::getKey extradisabledtxtcolor]
			option add *Text.selectBackground [::skin::getKey extraselectedbgcolor]
			option add *Text.selectForeground [::skin::getKey extraselectedtxtcolor]
 
			option add *Button.background [::skin::getKey extrabuttonbgcolor]
			option add *Button.foreground [::skin::getKey extrabuttontxtcolor]
			option add *Button.activeBackground [::skin::getKey extrabuttonbgcoloractive]
			option add *Button.activeForeground [::skin::getKey extrabuttontxtcoloractive]

			option add *Checkbutton.background [::skin::getKey extrastdwindowcolor]
			option add *Checkbutton.foreground [::skin::getKey extrabuttontxtcolor]
			option add *Checkbutton.activeBackground [::skin::getKey extrabuttonbgcoloractive]
			option add *Checkbutton.activeForeground [::skin::getKey extrabuttontxtcoloractive]
			option add *Checkbutton.selectColor [::skin::getKey extracheckbuttonselectedcolor]

			option add *Radiobutton.background [::skin::getKey extrastdwindowcolor]
			option add *Radiobutton.foreground [::skin::getKey extrabuttontxtcolor]
			option add *Radiobutton.activeBackground [::skin::getKey extrabuttonbgcoloractive] 
			option add *Radiobutton.activeForeground [::skin::getKey extrabuttontxtcoloractive]
			option add *Radiobutton.selectColor [::skin::getKey extracheckbuttonselectedcolor]

			option add *Listbox.selectBorderWidth 0 widgetDefault
			option add *Listbox.relief sunken
			option add *Listbox.background [::skin::getKey extrastdbgcolor]
			option add *Listbox.foreground [::skin::getKey extrastdtxtcolor]
			option add *Listbox.selectBackground [::skin::getKey extraselectedbgcolor] 
			option add *Listbox.selectForeground [::skin::getKey extraselectedtxtcolor]

			option add *Menu.activeBorderWidth 0 widgetDefault
			option add *Menu.highlightThickness 0 widgetDefault
			option add *Menu.borderWidth 1 widgetDefault
			option add *Menu.background [::skin::getKey menubackground]
			option add *Menu.foreground [::skin::getKey menuforeground]
			option add *Menu.activeBackground [::skin::getKey menuactivebackground]
			option add *Menu.activeForeground [::skin::getKey menuactiveforeground]

			option add *Menubutton.background [::skin::getKey extrabuttonbgcolor]
			option add *Menubutton.foreground [::skin::getKey extrabuttontxtcolor]
			option add *Menubutton.activeBackground [::skin::getKey extrabuttonbgcoloractive]
			option add *Menubutton.activeForeground [::skin::getKey extrabuttontxtcoloractive]
			option add *Menubutton.relief raised

			option add *Menubutton.padX 2 widgetDefault
			option add *Menubutton.padY 4 widgetDefault

			#option add *NoteBook.background [::skin::getKey extrastdwindowcolor]
			#option add *NoteBook.Canvas.background [::skin::getKey extrastdwindowcolor]
			#option add *NoteBook.Canvas.ArrowButton.background [::skin::getKey extrastdwindowcolor]
				# -activebackground [::skin::getKey extrabuttonbgcoloractive] -activeforeground [::skin::getKey extrabuttontxtcoloractive]

			option add *Scrollbar.width		10
			option add *Scrollbar.borderWidth		1
			option add *Scrollbar.highlightThickness	0 widgetDefault

		}
		#Use different width for scrollbar on Mac OS X
		#http://wiki.tcl.tk/12987
		if { [OnMac] } {
			option add *background #ECECEC
			option add *highlightbackground #ECECEC
			option add *Scrollbar.width 16 userDefault
			option add *Button.Font macfont userDefault
			option add *Button.highlightBackground #ECECEC userDefault
		} elseif { [OnWin] } {
			#option add *background [::skin::getKey extrastdwindowcolor]
			option add *Scrollbar.width 14 userDefault
			option add *Button.Font sboldf userDefault
		}

		#option add *Scrollbar.borderWidth 1 userDefault

		#set Entry {-bg #FFFFFF -foreground #000000}
		#set Label {-bg #FFFFFF -foreground #000000}
		#::themes::AddClass Amsn Entry $Entry 90
		#::themes::AddClass Amsn Label $Label 90
		::abookGui::Init


		#Register events
		::Event::registerEvent loggedIn all loggedInGuiConf
		::Event::registerEvent loggedOut all loggedOutGuiConf

	}

	#///////////////////////////////////////////////////////////////////////////////
	# Draws the about window
	proc aboutWindow {} {
		global langenc date weburl
		
		set filename "[file join docs README[::config::getGlobalKey language]]"
		
		set current_enc $langenc


		if {![file exists $filename]} {
			status_log "File $filename NOT exists!!\n\tUsing english one instead." red
			set filename README
			set current_enc "iso8859-1"

			if {![file exists $filename]} {
				status_log "no english README either .. Houston, we have a problem, you ***'ed up your aMSN install!"
				msg_box "[trans transnotexists]"
				return
			}
		}
				
		if { [winfo exists .about] } {
			raise .about
			return
		}

		toplevel .about
		wm title .about "[trans aboutamsn]"

		ShowTransient .about

		wm state .about withdrawn

		#Top frame (Picture and name of developers)
		set developers "Didimo Grimaldo\n Alvaro J. Iradier\n Khalaf Philippe\n Alaoui Youness\n Dave Mifsud\n..."

		set version "aMSN $::version ([::abook::dateconvert $date])"
		if {[string index $::version end] == "b" && $::Version::amsn_revision > 0} {
			append version "\n[trans svnversion] : $::Version::amsn_revision"
		}
		label .about.image -image [::skin::loadPixmap msndroid]
		label .about.title -text $version -font bboldf
		label .about.what -text "[trans whatisamsn]\n"
		pack .about.image .about.title .about.what -side top

		#names-frame
		frame .about.names
		label .about.names.t -font splainf -text "[trans broughtby]:\n$developers"
		pack .about.names.t -side top
		pack .about.names -side top


		#Middle frame (About text)
		frame .about.middle
		frame .about.middle.list -borderwidth 0
		text .about.middle.list.text -width 80 -height 10 -wrap word \
			-yscrollcommand ".about.middle.list.ys set" -font splainf
		scrollbar .about.middle.list.ys -command ".about.middle.list.text yview"
		pack .about.middle.list.ys -side right -fill y
		pack .about.middle.list.text -side left -expand true -fill both
		pack .about.middle.list -side top -expand true -fill both -padx 1 -pady 1

		label .about.middle.url -text $weburl -font bplainf \
			-background [::skin::getKey extrastdwindowcolor] -foreground [::skin::getKey extralinkcolor]

		pack .about.middle.url -side top -pady 3
		bind .about.middle.url <Enter> ".about.middle.url configure \
			-font bsunderf -cursor hand2 \
			-background [::skin::getKey extralinkbgcoloractive] -foreground [::skin::getKey extralinkcoloractive]"
 
		bind .about.middle.url <Leave> ".about.middle.url configure  \
			-font bplainf -cursor left_ptr \
			-background [::skin::getKey extrastdwindowcolor] -foreground [::skin::getKey extralinkcolor]"

		

		bind .about.middle.url <<Button1>> "launch_browser $weburl"


		#Bottom frame (Close button)
		frame .about.bottom
		button .about.bottom.close -text "[trans close]" -command "destroy .about"
		button .about.bottom.credits -text "[trans credits]..." -command [list ::amsn::showHelpFileWindow CREDITS [trans credits]]
		bind .about <<Escape>> "destroy .about"

		pack .about.bottom.close -side right
		pack .about.bottom.credits -side left

		pack .about.bottom -side bottom -fill x -pady 3 -padx 5
		pack .about.middle -expand true -fill both -side top

		#Insert the text in .about.middle.list.text
		set id [open $filename r]
		fconfigure $id -encoding $current_enc

		.about.middle.list.text insert 1.0 [read $id]
		close $id

		.about.middle.list.text configure -state disabled

		update idletasks

		wm state .about normal
		set x [expr {([winfo vrootwidth .about] - [winfo width .about]) / 2}]
		set y [expr {([winfo vrootheight .about] - [winfo height .about]) / 2}]
		wm geometry .about +${x}+${y}
		moveinscreen .about 30

		#Should we disable resizable? Since when we make the windows smaller (in y), we lost the "Close button"
		#wm resizable .about 0 0
	}
	#///////////////////////////////////////////////////////////////////////////////


	#///////////////////////////////////////////////////////////////////////////////
	# showHelpFileWindow(file, windowtitle, ?english?)
	proc showHelpFileWindow {file title {english 0}} {
		global langenc

		set langcode [::config::getGlobalKey language]
		set encoding $langenc
			

		if {$english == 1} {
			set langcode "en"
			set encoding "iso8859-1"
		}

		set filename [file join "docs" "${file}$langcode"]
		if {$langcode == "en"} {
			set filename $file
		}


		if {![file exists $filename]} {
			status_log "File $filename NOT exists!!\n\tOpening English one instead." red
			set filename "${file}"
			set langcode "en"
			set encoding "iso8859-1"
			if {![file exists $filename]} {			
				status_log "Couldn't open $filename!" red
				msg_box "[trans transnotexists]"
				return
			}
		}

		if {$file == "CREDITS"} {
			set encoding "utf-8"
		}
			
		if {$langcode == "en"} {
			set w help${filename}en
		} else {
			set w help${filename}
		}

		status_log "filename: $filename"

		# Used to avoid a bug for dbusviewer where the $filename points to /home/user/.amsn the dot makes 
		# tk think it's a window's path separator and it says that the window .help/home/user/ doesn't exit (for .amsn to be its child)
		set w ".[string map {. "_" " " "__"} $w]"


		if { [winfo exists $w] } {
			raise $w
			return
		}

		toplevel $w
		wm title $w "$title"

		ShowTransient $w


		#Top frame (Help text area)
		frame $w.info
		frame $w.info.list -borderwidth 0
		text $w.info.list.text -width 80 -height 30 -wrap word \
			-yscrollcommand "$w.info.list.ys set" -font splainf

		scrollbar $w.info.list.ys -command "$w.info.list.text yview"
		pack $w.info.list.ys 	-side right -fill y
		pack $w.info.list.text -expand true -fill both -padx 1 -pady 1
		pack $w.info.list 		-side top -expand true -fill both -padx 1 -pady 1
		pack $w.info 			-expand true -fill both -side top

		#Bottom frame (Close button)
		button $w.close -text "[trans close]" -command "destroy $w"
		button $w.eng -text "English version" -command [list ::amsn::showHelpFileWindow $file "$title - English version" 1]
		bind $w <<Escape>> "destroy $w"
		pack $w.close

		if {$langcode != "en" && $english != 1} {
			pack $w.eng  -side right -anchor e -padx 5 -pady 3
		}
		pack $w.close  -side right -anchor e -padx 5 -pady 3

		#Insert FAQ text
		set id [open $filename r]
		fconfigure $id -encoding $encoding
		$w.info.list.text insert 1.0 [read $id]
		close $id

		$w.info.list.text configure -state disabled

		update idletasks

		set x [expr {([winfo vrootwidth $w] - [winfo width $w]) / 2}]
		set y [expr {([winfo vrootheight $w] - [winfo height $w]) / 2}]
		wm geometry $w +${x}+${y}

		#Should we disable resizable? Since when we make the windows smaller (in y), we lost the "Close button"
		#wm resizable .about 0 0
		return $w
	}

	#///////////////////////////////////////////////////////////////////////////////

	proc messageBox { message type icon {title ""} {parent ""}} {
		#If we are on MacOS X, don't put the box in the parent because there are some problems
		if { [OnMac] } {
			set answer [tk_messageBox -message "$message" -type $type -icon $icon]
		} else {
			if { $parent == ""} {
				set parent [focus]
				if { $parent == "" } { set parent "." }
			}
				set answer [tk_messageBox -message "$message" -type $type -icon $icon -title $title -parent $parent]
		}
		return $answer
	}

	#///////////////////////////////////////////////////////////////////////////////
	
	#///////////////////////////////////////////////////////////////////////////////
	proc customMessageBox { message type {icon ""} {title ""} {parent ""} {askRememberAnswer 0} {modal 0} {uniqueId ""}} {
		# This tracker is so we can TkWait. It needs to be global so that the buttons can modify it.
		global customMessageBoxAnswerTracker
		# This is the tracker for the checkbox.
		# It needs to be an array because we may have more than one message box open (hence the unique index). 
		global customMessageBoxRememberTracker

		if {$uniqueId == ""} {
			set uniqueId [clock seconds]
		} else {
			if {[winfo exists ".messagebox_$uniqueId"]} {
				return "duplicate"
			}
		}
		set w ".messagebox_$uniqueId"

		if { [winfo exists $w] } {
			raise $w
			return
		}

		set w [toplevel $w]

		if {$title == ""} {
			set title [trans title]
		}
		wm title $w $title
		wm group $w .
		wm resizable $w 0 0

		#Create the 2 frames
		frame $w.top
		frame $w.buttons

		if {$icon == ""} {
			label $w.top.bitmap -image [::skin::loadPixmap warning]
		} else {
			label $w.top.bitmap -image [::skin::loadPixmap $icon]
		}
		pack $w.top.bitmap -side left -pady 0 -padx [list 0 12 ]

		label $w.top.message -text $message -wraplength 400 -justify left
		pack $w.top.message -pady 0 -padx 0 -side top
		if {$askRememberAnswer != 0} {
			if {$askRememberAnswer == 1} {
				set rememberText [trans remembersetting]
			} else {
				set rememberText [trans $askRememberAnswer]
			}
			checkbutton $w.top.remember -variable customMessageBoxRememberTracker($uniqueId) \
				-text $rememberText -anchor w -state normal

			pack $w.top.remember -pady 5 -padx 10 -side bottom -fill x
		}

		switch $type {
			abortretryignore {
				set buttons [list [list "abort" [trans abort]] [list "retry" [trans retry]] [list "ignore" [trans ignore]]]
			}
			ok {
				set buttons [list [list "ok" [trans ok]]]
			}
			okcancel {
				set buttons [list [list "ok" [trans ok]] [list "cancel" [trans cancel]]]
			}
			retrycancel {
				set buttons [list [list "retry" [trans retry]] [list "cancel" [trans cancel]]]
			}
			yesno {
				set buttons [list [list "yes" [trans yes]] [list "no" [trans no]]]
			}
			yesnocancel {
				set buttons [list [list "yes" [trans yes]] [list "no" [trans no]] [list "cancel" [trans cancel]]]
			}
			deletecancel {
				set buttons [list [list "delete" [trans delete]] [list "cancel" [trans cancel]]]
			}
			deleteblockcancel {
				set buttons [list [list "delete" [trans delete]] [list "deleteblock" [trans deleteblock]] [list "cancel" [trans cancel]]]
			}
			default {
				set buttons [list [list "ok" [trans ok]]]
			}
		}

		set customMessageBoxAnswerTracker($uniqueId) ""

		#Create the buttons
		foreach button $buttons {
			set buttonName [lindex $button 0]
			set buttonLabel [lindex $button 1]
			button $w.buttons.$buttonName -text $buttonLabel -command [list set customMessageBoxAnswerTracker($uniqueId) $buttonName]
			pack $w.buttons.$buttonName -pady 0 -padx 0 -side right
		}

		#Pack frames
		pack $w.top -pady 12 -padx 12 -side top
		pack $w.buttons -pady 12 -padx 12 -fill x

		moveinscreen $w 30
		bind $w <<Escape>> "destroy $w"
		wm protocol $w WM_DELETE_WINDOW [list set customMessageBoxAnswerTracker($uniqueId) ""]

		set oldgrab ""
		if { $modal } {
			set oldgrab [grab current]
			grab set $w
		}

		tkwait variable customMessageBoxAnswerTracker($uniqueId)

		if { $oldgrab != "" } {
			grab set $oldgrab
		}

		catch { destroy $w }
		if {$askRememberAnswer != 0} {
			set answer [list $customMessageBoxAnswerTracker($uniqueId) $customMessageBoxRememberTracker($uniqueId)]
			unset customMessageBoxAnswerTracker($uniqueId)
			unset customMessageBoxRememberTracker($uniqueId)
		} else {
			set answer $customMessageBoxAnswerTracker($uniqueId)
			unset customMessageBoxAnswerTracker($uniqueId)
		}

		return $answer
	}
	#///////////////////////////////////////////////////////////////////////////////

	#///////////////////////////////////////////////////////////////////////////////
	# Shows the error message specified by "msg"
	proc errorMsg { msg } {
		::amsn::messageBox $msg ok error "[trans title] Error"
	}
	#///////////////////////////////////////////////////////////////////////////////

	#///////////////////////////////////////////////////////////////////////////////
	# Shows the error message specified by "msg"
	proc infoMsg { msg {icon "info"} } {
		::amsn::messageBox $msg ok $icon [trans title]
	}
	#///////////////////////////////////////////////////////////////////////////////

	#///////////////////////////////////////////////////////////////////////////////
	proc blockUnblockUser { user_login } {
		if { [::MSN::userIsBlocked $user_login] } {
			unblockUser $user_login
		} else {
			blockUser $user_login
		}
	}
	#///////////////////////////////////////////////////////////////////////////////



	#///////////////////////////////////////////////////////////////////////////////
	proc blockUser {user_login} {
		set answer [::amsn::messageBox "[trans confirmbl] ($user_login)" yesno question [trans block]]
		if { $answer == "yes"} {
			set name [::abook::getNick ${user_login}]
			::MSN::blockUser ${user_login}
		}
	}
	#///////////////////////////////////////////////////////////////////////////////


	#///////////////////////////////////////////////////////////////////////////////
	proc unblockUser {user_login} {
		set name [::abook::getNick ${user_login}]
		::MSN::unblockUser ${user_login}
	}
	#///////////////////////////////////////////////////////////////////////////////

	
	#///////////////////////////////////////////////////////////////////////////////
	proc removeUserFromGroup {user_login grId} {
		::MSN::removeUserFromGroup $user_login $grId
	}
	#///////////////////////////////////////////////////////////////////////////////


	#///////////////////////////////////////////////////////////////////////////////
	#Delete user window, user can choose to delete user, cancel the action or block and delete the user
	proc deleteUser { user_login } {
		if {[lsearch [::abook::getLists $user_login] BL] == -1} {
			# User is not blocked.
			set type deleteblockcancel
		} else {
			# User is already blocked.
			set type deletecancel
		}
		if {[::MSN::userIsNotIM $user_login] } {
			set answer [customMessageBox [trans confirmdu] $type "" "[trans delete] - $user_login" "." 0]
			set fulldelete 1
		} else {
			set answer [customMessageBox [trans confirmdu] $type "" "[trans delete] - $user_login" "." confirmfulldelete]
			foreach {answer fulldelete} $answer break
		}
		if {$answer == "deleteblock"} {
			# Delete the user and block.
			::amsn::deleteUserAction $user_login 1 $fulldelete
		} elseif {$answer == "delete"} {
			# Only delete the user.
			::amsn::deleteUserAction $user_login 0 $fulldelete
		}
	}

	#///////////////////////////////////////////////////////////////////////////////
	# deleteUserAction {user_login answer grId block}
	# Action to do when someone click delete a user
	proc deleteUserAction {user_login {block 0} {full 0}} {
		#If the user wants to delete AND block a user
		if { $block == 1 } {
			set name [::abook::getNick ${user_login}]
			::MSN::blockUser ${user_login}
		}

		::MSN::deleteUser ${user_login} $full
		::abook::setContactData $user_login alarms ""

		return
	}
	

	proc InkSend { win_name filename {friendlyname ""}} {
		set chatid [::ChatWindow::Name $win_name]

		if { $chatid == 0 } {
			status_log "VERY BAD ERROR in ::amsn::InkSend!!!\n" red
			return 0
		}

		#Blank ink
		if {$filename == ""} { return 0 }

		if { $friendlyname != "" } {
			set nick $friendlyname
			set p4c 1
		} elseif { [::abook::getContactData [::ChatWindow::Name $win_name] cust_p4c_name] != ""} {
			set friendlyname [::abook::parseCustomNick [::abook::getContactData [::ChatWindow::Name $win_name] cust_p4c_name] [::abook::getPersonal MFN] [::abook::getPersonal login] "" [::abook::getpsmmedia] ]
			set nick $friendlyname
			set p4c 1
		} elseif { [::config::getKey p4c_name] != ""} {
			set nick [::config::getKey p4c_name]
			set p4c 1
		} else {
			set nick [::abook::getPersonal MFN]
			set p4c 0
		}
		#Postevent when we send a message
		set evPar(nick) nick
		set evPar(ink) filename
		set evPar(chatid) chatid
		set evPar(win_name) win_name
		::plugins::PostEvent chat_ink_send evPar

		#Draw our own message
		#Does this image ever gets destroyed ? When destroying the chatwindow it's embeddeed in it should I guess ? This is not the leak I'm searching for though as I'm not sending inks...
		# don't try to display it if the image is considered as invalid
		if {[catch {set img [image create photo [TmpImgName] -file $filename]}]} {
			status_log "(::amsn::InkSend) trying to display an invalid image, but keep sending it." red
		} else {
			SendMessageFIFO [list ::amsn::ShowInk $chatid [::abook::getPersonal login] $nick $img ink $p4c] "::amsn::messages_stack($chatid)" "::amsn::messages_flushing($chatid)"
		}
		::MSN::ChatQueue $chatid [list ::MSN::SendInk $chatid $filename]

		::plugins::PostEvent chat_ink_sent evPar
	}

	proc InviteCallFromCW {win_name} {
		if {![winfo exists $win_name] } {
			set win_name [::amsn::chatUser $win_name]
		}
		set chatid [::ChatWindow::Name $win_name]
		status_log "chatid:=$chatid" red

		set users [::MSN::usersInChat $chatid]

		if {[llength $users] > 1} {
			#TODO: add a new key?
			::amsn::errorMsg [trans sipcallyouarebusy]
		} elseif {[llength $users] == 1} {
			::amsn::SIPCallInviteUser [lindex $users 0]
		} else {
			::amsn::SIPCallInviteUser $chatid
		}

	}

	proc FileTransferSend { win_name {filename ""} } {
		if {![winfo exists $win_name] } {
			set win_name [::amsn::chatUser $win_name]
		}
			
		global starting_dir

#		set filename [ $w.top.fields.file get ]
		if { $filename == "" } {
			set filename [chooseFileDialog "" [trans sendfile] $win_name]
			status_log $filename
		}

		if { $filename == "" } { return }

		#Remember last directory
		set starting_dir [file dirname $filename]

		if {![file readable $filename]} {
			msg_box "[trans invalidfile [trans filename] $filename]"
			return
		}

		if { [::config::getKey autoftip] } {
			set ipaddr [::config::getKey myip]
		} else {
			set ipaddr [::config::getKey manualip]
		}

		if { [catch {set filesize [file size $filename]} res]} {
			::amsn::errorMsg "[trans filedoesnotexist]"
			#::amsn::fileTransferProgress c $cookie -1 -1
			return 1
		}

		set chatid [::ChatWindow::Name $win_name]
		status_log "chatid:=$chatid" red

		set users [::MSN::usersInChat $chatid]


		foreach chatid $users {
			chatUser $chatid

			#Calculate a random cookie
			set cookie [expr {([clock clicks]) % (65536 * 8)}]
			set txt "[trans ftsendinvitation [::abook::getDisplayNick $chatid] $filename [::amsn::sizeconvert $filesize]]"
			

			status_log "Random generated cookie: $cookie\n"
			SendMessageFIFO [list ::amsn::WinWriteFTSend $chatid $txt $cookie] "::amsn::messages_stack($chatid)" "::amsn::messages_flushing($chatid)"

			::MSN::ChatQueue $chatid [list ::MSNFT::sendFTInvitation $chatid $filename $filesize $ipaddr $cookie]
			#::MSNFT::sendFTInvitation $chatid $filename $filesize $ipaddr $cookie

			::log::ftlog $chatid $txt

			# Postevent when we send a file transfer invitation
			set evPar(chatid) $chatid
			set evPar(filename) $filename
			::plugins::PostEvent sent_ft_invite evPar
		}
		return 0
	}

	proc WinWriteFTSend { chatid txt cookie } {
		WinWrite $chatid "\n" green
		WinWriteIcon $chatid greyline 3
		WinWrite $chatid "\n" green
		WinWriteIcon $chatid fticon 3 2
		WinWrite $chatid "$txt " green
		WinWriteClickable $chatid "[trans cancel]" \
			"::amsn::CancelFTInvitation $chatid $cookie" ftno$cookie
		WinWrite $chatid "\n" green
		WinWriteIcon $chatid greyline 3
	}

	proc DisableCancelText { cookie chatid } {

		set win_name [::ChatWindow::For $chatid]
		if { [winfo exists $win_name] } {
			[::ChatWindow::GetOutText ${win_name}] tag configure ftno$cookie \
				-foreground #808080 -font bplainf -underline false
			[::ChatWindow::GetOutText ${win_name}] tag bind ftno$cookie <Enter> ""
			[::ChatWindow::GetOutText ${win_name}] tag bind ftno$cookie <Leave> ""
			[::ChatWindow::GetOutText ${win_name}] tag bind ftno$cookie <<Button1>> ""

			[::ChatWindow::GetOutText ${win_name}] conf -cursor xterm
		}

	}

	proc CancelFTInvitation { chatid cookie } {
		#::MSNFT::acceptFT $chatid $cookie

		set win_name [::ChatWindow::For $chatid]
		if { [::ChatWindow::For $chatid] == 0} {
			return 0
		}

		::MSNFT::cancelFTInvitation $chatid $cookie
		DisableCancelText $cookie $chatid

		set txt [trans invitationcancelled]

		SendMessageFIFO [list ::amsn::WinWriteCancelFT $chatid $txt] "::amsn::messages_stack($chatid)" "::amsn::messages_flushing($chatid)"

		set email [::MSN::usersInChat $chatid]
		::log::ftlog $email $txt
	}

	proc WinWriteCancelFT {chatid txt} {
		WinWrite $chatid "\n" green
		WinWriteIcon $chatid greyline 3
		WinWrite $chatid "\n" green
		WinWriteIcon $chatid ftreject 3 2
		WinWrite $chatid " $txt\n" green
		WinWriteIcon $chatid greyline 3
	}

	proc acceptedFT { chatid who filename } {
		set win_name [::ChatWindow::For $chatid]
		if { [::ChatWindow::For $chatid] == 0} {
			return 0
		}
		set txt [trans ftacceptedby [::abook::getDisplayNick $chatid] $filename]

		WinWrite $chatid "\n" green
		WinWriteIcon $chatid greyline 3
		WinWrite $chatid "\n" green
		WinWriteIcon $chatid fticon 3 2
		WinWrite $chatid " $txt\n" green
		WinWriteIcon $chatid greyline 3

		set email [::MSN::usersInChat $chatid]
		::log::ftlog $email $txt
	}

	proc rejectedFT { chatid who filename } {
		set win_name [::ChatWindow::For $chatid]
		if { [::ChatWindow::For $chatid] == 0} {
			return 0
		}
		set txt [trans ftrejectedby [::abook::getDisplayNick $chatid] $filename]

		WinWrite $chatid "\n" green
		WinWriteIcon $chatid greyline 3
		WinWrite $chatid " \n" green
		WinWriteIcon $chatid ftreject 3 2
		WinWrite $chatid " $txt\n" green
		WinWriteIcon $chatid greyline 3

		set email [::MSN::usersInChat $chatid]
		::log::ftlog $email $txt
	}

	#////////////////////////////////////////////////////////////////////////////////
	#  GotFileTransferRequest ( chatid dest branchuid cseq uid sid filename filesize)
	#  This procedure is called when we receive an MSN6 File Transfer Request
	proc GotFileTransferRequest { chatid dest branchuid cseq uid sid filename filesize} {
		set win_name [::ChatWindow::For $chatid]

		if { [::ChatWindow::For $chatid] == 0} {
			return 0
		}

                set semic [string first ";" $dest]
                if { $semic > 0 } {
                        set dest [string range $dest 0 [expr {$semic - 1}]]
                }

		set fromname [::abook::getDisplayNick $dest]
		set txt [trans ftgotinvitation $fromname '$filename' [::amsn::sizeconvert $filesize] [::config::getKey receiveddir]]
		set win_name [::ChatWindow::MakeFor $chatid $txt $dest]
		WinWrite $chatid "\n" green
		WinWriteIcon $chatid greyline 3
		WinWrite $chatid " \n" green

		if { [::skin::loadPixmap "FT_preview_${sid}"] != "" } {
			WinWriteIcon $chatid FT_preview_${sid} 5 5
			WinWrite $chatid "\n" green
		}

		WinWriteIcon $chatid fticon 3 2
		WinWrite $chatid $txt green
		WinWrite $chatid " - (" green
		WinWriteClickable $chatid "[trans accept]" [list ::amsn::AcceptFT $chatid -1 [list $dest $branchuid $cseq $uid $sid $filename]] ftyes$sid
		WinWrite $chatid " / " green
		WinWriteClickable $chatid "[trans saveas]" [list ::amsn::SaveAsFT $chatid -1 [list $dest $branchuid $cseq $uid $sid $filename]] ftsaveas$sid
		WinWrite $chatid " / " green
		WinWriteClickable $chatid "[trans reject]" [list ::amsn::RejectFT $chatid -1 [list $sid $branchuid $uid]] ftno$sid
		WinWrite $chatid ")\n" green
		WinWriteIcon $chatid greyline 3

		::log::ftlog $dest $txt

		if { ![file writable [::config::getKey receiveddir]]} {
			WinWrite $chatid "\n[trans readonlywarn [::config::getKey receiveddir]]\n" red
			WinWriteIcon $chatid greyline 3
			}

		if { [::config::getKey ftautoaccept] == 1  || [::abook::getContactData $dest autoacceptft] == 1 } {
			WinWrite $chatid "\n[trans autoaccepted]" green
			::amsn::AcceptFT $chatid -1 [list $dest $branchuid $cseq $uid $sid $filename]
		}
	}

	#Message shown when receiving a file
	proc fileTransferRecv {filename filesize cookie chatid fromlogin} {
		set win_name [::ChatWindow::For $chatid]
		if { [::ChatWindow::For $chatid] == 0} {
			return 0
		}

		set semic [string first ";" $fromlogin]
		if { $semic > 0 } {
			set fromlogin [string range $fromlogin 0 [expr {$semic - 1}]]
		}

		set fromname [::abook::getDisplayNick $fromlogin]
		set txt [trans ftgotinvitation $fromname '$filename' [::amsn::sizeconvert $filesize] [::config::getKey receiveddir]]

		set win_name [::ChatWindow::MakeFor $chatid $txt $fromlogin]

		WinWrite $chatid "\n" green
		WinWriteIcon $chatid greyline 3
		WinWrite $chatid "\n" green
		WinWriteIcon $chatid fticon 3 2
		WinWrite $chatid $txt green
		WinWrite $chatid " - (" green
		WinWriteClickable $chatid "[trans accept]" \
			"::amsn::AcceptFT $chatid $cookie" ftyes$cookie
		WinWrite $chatid " / " green
		WinWriteClickable $chatid "[trans saveas]" \
			"::amsn::SaveAsFT $chatid $cookie" ftsaveas$cookie
		WinWrite $chatid " / " green
		WinWriteClickable $chatid "[trans reject]" \
			"::amsn::RejectFT $chatid $cookie" ftno$cookie
		WinWrite $chatid ")\n" green
		WinWriteIcon $chatid greyline 3

		::log::ftlog $fromlogin $txt

		if { ![file writable [::config::getKey receiveddir]]} {
			WinWrite $chatid "\n[trans readonlywarn [::config::getKey receiveddir]]\n" red
			WinWriteIcon $chatid greyline 3
		}

		if { [::config::getKey ftautoaccept] == 1 || [::abook::getContactData $dest autoacceptft] == 1 } {
			WinWrite $chatid "\n[trans autoaccepted]" green
			::amsn::AcceptFT $chatid $cookie
		}
	}

	proc AcceptFTOpenSB { chatid cookie {varlist ""} } {
		#::amsn::RecvWin $cookie
		if { $cookie != -1 } {
			::MSNFT::acceptFT $chatid $cookie
		} else {
			::MSN6FT::AcceptFT $chatid [lindex $varlist 0] [lindex $varlist 1] [lindex $varlist 2] [lindex $varlist 3] [lindex $varlist 4] [lindex $varlist 5]
			set cookie [lindex $varlist 4]
		}
	}

	proc AcceptFT { chatid cookie {varlist ""} } {
		foreach var $varlist {
			status_log "Var: $var\n" red
		}

		set chatid [::MSN::chatTo $chatid]

		::MSN::ChatQueue $chatid [list ::amsn::AcceptFTOpenSB $chatid $cookie $varlist]

		set win_name [::ChatWindow::For $chatid]
		if { [::ChatWindow::For $chatid] == 0} {
			return 0
		}

		if { $cookie == -1 } {
			set cookie [lindex $varlist 4]
		}

		[::ChatWindow::GetOutText ${win_name}] tag configure ftyes$cookie \
			-foreground #808080 -font bplainf -underline false
		[::ChatWindow::GetOutText ${win_name}] tag bind ftyes$cookie <Enter> ""
		[::ChatWindow::GetOutText ${win_name}] tag bind ftyes$cookie <Leave> ""
		[::ChatWindow::GetOutText ${win_name}] tag bind ftyes$cookie <<Button1>> ""

		[::ChatWindow::GetOutText ${win_name}] tag configure ftsaveas$cookie \
			-foreground #808080 -font bplainf -underline false
		[::ChatWindow::GetOutText ${win_name}] tag bind ftsaveas$cookie <Enter> ""
		[::ChatWindow::GetOutText ${win_name}] tag bind ftsaveas$cookie <Leave> ""
		[::ChatWindow::GetOutText ${win_name}] tag bind ftsaveas$cookie <<Button1>> ""

		DisableCancelText $cookie $chatid
		
		set txt [trans ftaccepted]

		SendMessageFIFO [list ::amsn::WinWriteAcceptFT $chatid $txt] "::amsn::messages_stack($chatid)" "::amsn::messages_flushing($chatid)"

		set email [::MSN::usersInChat $chatid]
		::log::ftlog $email $txt
	}

	proc WinWriteAcceptFT {chatid txt} {
		WinWrite $chatid "\n" green
		WinWriteIcon $chatid greyline 3
		WinWrite $chatid "\n" green
		WinWriteIcon $chatid fticon 3 2
		WinWrite $chatid " $txt\n" green
		WinWriteIcon $chatid greyline 3
	}


	proc SaveAsFT {chatid cookie {varlist ""} } {
		global HOME
		if {$cookie != -1} {
			set initialfile [::MSNFT::getFilename $cookie]
		} {
			set initialfile [lindex $varlist 5]
		}
		if {[catch {set filename [tk_getSaveFile -initialfile $initialfile -initialdir [::config::getKey receiveddir]]} res]} {
			status_log "Error in SaveAsFT: $res \n"
			set filename [tk_getSaveFile -initialfile $initialfile -initialdir [set HOME]]
		
		}
		if {$filename != ""} {
			AcceptFT $chatid $cookie [list [lindex $varlist 0] [lindex $varlist 1] [lindex $varlist 2] [lindex $varlist 3] [lindex $varlist 4] "$filename"]
		} {return}
	}


	proc RejectFT {chatid cookie {varlist ""} } {
		if { $cookie != -1 && $cookie != -2 } {
			::MSNFT::rejectFT $chatid $cookie
		} elseif { $cookie == - 1 } {
			::MSN6FT::RejectFT $chatid [lindex $varlist 0] [lindex $varlist 1] [lindex $varlist 2]
			set cookie [lindex $varlist 0]
		} elseif { $cookie == -2 } {
			set cookie [lindex $varlist 0]
			set txt [trans filetransfercancelled]
		}

		set win_name [::ChatWindow::For $chatid]
		if { [::ChatWindow::For $chatid] == 0} {
			return 0
		}

		[::ChatWindow::GetOutText ${win_name}] tag configure ftyes$cookie \
		-foreground #808080 -font bplainf -underline false
		[::ChatWindow::GetOutText ${win_name}] tag bind ftyes$cookie <Enter> ""
		[::ChatWindow::GetOutText ${win_name}] tag bind ftyes$cookie <Leave> ""
		[::ChatWindow::GetOutText ${win_name}] tag bind ftyes$cookie <<Button1>> ""

		[::ChatWindow::GetOutText ${win_name}] tag configure ftsaveas$cookie \
		-foreground #808080 -font bplainf -underline false
		[::ChatWindow::GetOutText ${win_name}] tag bind ftsaveas$cookie <Enter> ""
		[::ChatWindow::GetOutText ${win_name}] tag bind ftsaveas$cookie <Leave> ""
		[::ChatWindow::GetOutText ${win_name}] tag bind ftsaveas$cookie <<Button1>> ""

		DisableCancelText $cookie $chatid		

		[::ChatWindow::GetOutText ${win_name}] conf -cursor xterm

		if { [info exists txt] == 0 } {
			set txt [trans ftrejected]
		}

		SendMessageFIFO [list ::amsn::WinWriteRejectFT $chatid $txt] "::amsn::messages_stack($chatid)" "::amsn::messages_flushing($chatid)"

		set email [::MSN::usersInChat $chatid]
		::log::ftlog $email $txt
	}

	proc WinWriteRejectFT {chatid txt} {
		WinWrite $chatid "\n" green
		WinWriteIcon $chatid greyline 3
		WinWrite $chatid "\n" green
		WinWriteIcon $chatid ftreject 3 2
		WinWrite $chatid "$txt\n" green
		WinWriteIcon $chatid greyline 3
	}

	# TODO it would be best to make it "[$extratitle] - $file - [trans filetranser]" 
	proc setFTWinTitle { w cookie filename {extratitle ""} } {
		variable ftwin_filename 
		
		if { ![info exists ftwin_filename($w,$cookie)] } {
			set file ""
			if { $filename != ""} {
				set file [getfilename $filename]
				set ftwin_filename($w,$cookie) $file
			}
		} else {
			set file [set ftwin_filename($w,$cookie)]
		}

		set title "$extratitle"
		
		if {$title != "" } {
			append title " - "
		}
				
		append title "$file - [trans filetransfer]"

		if { [string compare [wm title $w] "$title" ] } {
			wm title $w "$title"
		}

#		 if { [::MSNFT::getTransferType $cookie] == "received" } {
# 			wm title $w "$filename - [trans receivefile]"
# 		} else {
# 			wm title $w "$filename - [trans sendfile]"
# 		}

	}

	#PRIVATE: Opens Receiving Window
	proc FTWin {cookie filename user {chatid 0}} {
		status_log "Creating receive progress window\n"

		if { [string range $filename [expr {[string length $filename] - 11}] [string length $filename]] == ".incomplete" } {
			set filename [filenoext $filename]
		}

		# Set appropriate Cancel command
		if { [::MSNP2P::SessionList get $cookie] == 0 } {
			set cancelcmd "::MSNFT::cancelFT $cookie"
		} else {
			set cancelcmd "::MSN6FT::CancelFT $chatid $cookie"
		}

		set w .ft$cookie

		set lastfocus [focus]
		toplevel $w
		wm group $w .
		#wm geometry $w 360x170

		#frame $w.f -class amsnChatFrame -background [::skin::getKey chatwindowbg] -borderwidth 0 -relief flat
		#set w $ww.f

		label $w.user -text "[trans user]: $user" -font splainf
		pack $w.user -side top -anchor w
		label $w.file -text "[trans filename]: $filename" -font splainf
		pack $w.file -side top -anchor w

		pack [::dkfprogress::Progress $w.prbar] -fill x -expand 0 -padx 5 -pady 5 -side top

		label $w.progress -text "" -font splainf
		label $w.time -text "" -font splainf
		pack $w.progress $w.time -side top

		checkbutton $w.ftautoclose -text "[trans ftautoclose]" -onvalue 1 -offvalue 0 -variable [::config::getVar ftautoclose]
		pack $w.ftautoclose -side top
		#Specify the path to the file
		set filepath [file join [::config::getKey receiveddir] $filename]
		set filedir [file dirname $filepath]

		#Open directory and Open picture button
		button $w.close -text "[trans cancel]" -command $cancelcmd
		button $w.open -text "[trans opendir]" -state normal -command [list launch_filemanager $filedir]
		button $w.openfile -text "[trans openfile]" -state disable -command [list open_file $filepath]
		pack $w.close $w.open $w.openfile -side right -pady 5 -padx 10

		setFTWinTitle $w $cookie $filename

		bind $w <<Escape>> $cancelcmd
		wm protocol $w WM_DELETE_WINDOW $cancelcmd
		moveinscreen $w 30

		::dkfprogress::SetProgress $w.prbar 0
		update idletasks
		catch {focus $lastfocus}
	}


	#Updates filetransfer progress window/Bar
	#fileTransferProgress mode cookie filename bytes filesize
	# mode: a=Accepting invitation
	#       c=Connecting
	#       w=Waiting for connection
	#       e=Connect error
	#       i=Identifying/negotiating
	#       l=Connection lost
	#       ca=Cancel
	#       s=Sending
	#       r=Receiving
	#       fr=finish receiving
	#       fs=finish sending
	# cookie: ID for the filetransfer
	# bytes: bytes sent/received ( > filesize if finished / -1 if cancelling )
	# filesize: total bytes in the file
	# chatid: used for through server transfers
	#####
	proc FTProgress {mode cookie filename {bytes 0} {filesize 1000} {chatid 0}} {

		variable firsttimes    ;# Array. Times in ms when the FT started.
		variable ratetimer

		if { [info exists ratetimer($cookie)] } {
			after cancel $ratetimer($cookie)
		}

		set w .ft$cookie

		if { ([winfo exists $w] == 0) && ($mode != "ca")} {
			#set filename2 [::MSNFT::getFilename $cookie]
			if { $filename == "" } {
				FTWin $cookie [::MSNFT::getFilename $cookie] [::MSNFT::getUsername $cookie] $chatid
			} else {
				FTWin $cookie $filename $bytes $chatid
			}
		}

		if {[winfo exists $w] == 0} {
			return -1
		}

		switch $mode {
			a {
				$w.progress configure -text "[trans ftaccepting]..."
				setFTWinTitle $w $cookie $filename
				::dkfprogress::SetProgress $w.prbar 0 1000
			}
			c {
				$w.progress configure -text "[trans ftconnecting $bytes $filesize]..."
				setFTWinTitle $w $cookie $filename
				::dkfprogress::SetProgress $w.prbar 0 1000
			}
			w {
				$w.progress configure -text "[trans listeningon $bytes]..."
				setFTWinTitle $w $cookie $filename
				::dkfprogress::SetProgress $w.prbar 0 1000
			}
			e {
				$w.progress configure -text "[trans ftconnecterror]"
				$w.close configure -text "[trans close]" -command "destroy $w"
				wm protocol $w WM_DELETE_WINDOW "destroy $w"
				setFTWinTitle $w $cookie $filename "[trans error]"
			}
			i {
				# This means it's connected and it tries to authenticate the user...
				#$w.progress configure -text "[trans ftconnecting]"
				setFTWinTitle $w $cookie $filename
			}
			l {
				$w.progress configure -text "[trans ftconnectionlost]"
				$w.close configure -text "[trans close]" -command "destroy $w"
				wm protocol $w WM_DELETE_WINDOW "destroy $w"
				bind $w <<Escape>> "destroy $w"
				setFTWinTitle $w $cookie $filename "[trans error]"
			}
			r -
			s {
				#Calculate how many seconds has transmission lasted
				if {![info exists firsttimes] || ![info exists firsttimes($cookie)]} {
					set firsttimes($cookie) [clock seconds]
					set difftime 0
				} else {
					set difftime  [expr {[clock seconds] - $firsttimes($cookie)}]
				}

				if { $difftime == 0 || $bytes == 0} {
					set rate "???"
					set timeleft "-"
				} else {
					#Calculate rate and time
					set rate [format "%.1f" [expr {(1.0*$bytes / $difftime) / 1024.0 } ]]
					set secleft [expr {int(((1.0*($filesize - $bytes)) / $bytes) * $difftime)} ]
					set t1 [expr {$secleft % 60 }] ;#Seconds
					set secleft [expr {int($secleft / 60)}]
					set t2 [expr {$secleft % 60 }] ;#Minutes
					set secleft [expr {int($secleft / 60)}]
					set t3 $secleft ;#Hours
					set timeleft [format "%02i:%02i:%02i" $t3 $t2 $t1]
				}

				if {$mode == "r"} {
					$w.progress configure -text \
						"[trans receivedbytes [::amsn::sizeconvert $bytes] [::amsn::sizeconvert $filesize]] ($rate KB/s)"
				} elseif {$mode == "s"} {
					$w.progress configure -text \
						"[trans sentbytes [::amsn::sizeconvert $bytes] [::amsn::sizeconvert $filesize]] ($rate KB/s)"
				}
				$w.time configure -text "[trans timeremaining] :  $timeleft"
				set percent [expr {int(double($bytes)/ (double($filesize)/100.0))}]

				set ratetimer($cookie) [after 1000 [list ::amsn::FTProgress $mode $cookie $filename $bytes $filesize $chatid]]

				setFTWinTitle $w $cookie $filename "${percent}%"
				if { $filesize != 0 } {
					::dkfprogress::SetProgress $w.prbar $bytes $filesize
				}
			}
			ca {
				$w.progress configure -text "[trans filetransfercancelled]"
				$w.close configure -text "[trans close]" -command "destroy $w"
				wm protocol $w WM_DELETE_WINDOW "destroy $w"
				bind $w <<Escape>> "destroy $w"
				setFTWinTitle $w $cookie $filename "[trans cancelled]"
			}
			fs -
			fr {
				::dkfprogress::SetProgress $w.prbar 100
				$w.progress configure -text "[trans filetransfercomplete]"
				$w.close configure -text "[trans close]" -command "destroy $w"
				$w.openfile configure -state normal
				wm protocol $w WM_DELETE_WINDOW "destroy $w"
				bind $w <<Escape>> "destroy $w"
				setFTWinTitle $w $cookie $filename "[trans done]"
				::dkfprogress::SetProgress $w.prbar 1000 1000
			}
		}

		switch $mode {
			e -
			l -
			ca -
			fs -
			fr {
				# Whenever a file transfer is terminated in a way or in another,
				# remove the counters for this cookie.
				if {[info exists firsttimes($cookie)]} { unset firsttimes($cookie) }
				if {[info exists ratetimer($cookie)]} { unset ratetimer($cookie) }
				variable ftwin_filename 
				if {[info exists ftwin_filename($w,$cookie)]} { unset ftwin_filename($w,$cookie) }
			}
		}


		# Close the window if the filetransfer is finished
		if {($mode == "fr" || $mode == "fs") && [::config::getKey ftautoclose]} {
			destroy $w
		}

	}

 	#Converts filesize in KBytes or MBytes
 	proc sizeconvert {filesize} {
 		#Converts in KBytes
 		set filesizeK [expr {int($filesize/1024)}]
 		#Converts in MBytes
 		set filesizeM [expr {int($filesize/1048576)}]
 		#If the sizefile is bigger than 1Mo
 		if {$filesizeM != 0} {
 			set filesizeM2 [expr {int((($filesize/1048576.) - $filesizeM)*100)}]
 			if {$filesizeM2 < 10} {
 				set filesizeM2 "0$filesizeM2"
 			}
 			set filesizeM "$filesizeM,$filesizeM2"
 			return "${filesizeM}M"
 		#Elseif the filesize is bigger than 1Ko
 		} elseif {$filesizeK != 0} {
 			return "${filesizeK}K"
 		} else {
 			return "$filesize"
 		}
 	}


	#////////////////////////////////////////////////////////////////////////////////
	#  SIP CALLING FUNCTION
	#////////////////////////////////////////////////////////////////////////////////
	variable sipchatids
	set sipchatids [list]
	proc AddSIPchatidToList {chatid} {
		variable sipchatids
		lappend sipchatids $chatid
	}
	proc DelSIPchatidFromList {chatid} {
		variable sipchatids
		set pos [lsearch $sipchatids $chatid]
		if {$pos != -1} {
			set sipchatids [lreplace $sipchatids $pos $pos]
		}
	}
	proc SIPchatidExistsInList {chatid} {
		variable sipchatids
		if {[lsearch $sipchatids $chatid] != -1} {
			return 1
		} else {
			return 0
		}
	}


	proc SIPCallInviteUser { email } {
		set supports_sip 0

		status_log "CallInviteUser $email"

		set clientid [::abook::getContactData $email clientid]
		if { $clientid == "" } { set clientid 0 }
		set msnc [expr 0x100000]
		if { ($clientid & $msnc) != 0 } {
			set supports_sip 1
		}

		if {$supports_sip } {
			status_log "User $email supports SIP"
			AddSIPchatidToList $email
			::MSNSIP::InviteUser $email
		} else {
			status_log "User $email has no SIP flag"
			SIPCallNoSIPFlag $email			
		}
	}

	proc SIPPreparing {email sip callid} {
		::ChatWindow::MakeFor $email

		::ChatWindow::AddVoipControls $email $sip $callid
	}

	proc DisableSIPButton { chatid tag } {
		set win_name [::ChatWindow::For $chatid]
		if { [::ChatWindow::For $chatid] == 0} {
			return 0
		}

		# Disable SIP Button button
		[::ChatWindow::GetOutText ${win_name}] tag configure $tag \
		-foreground #808080 -font bplainf -underline false
		[::ChatWindow::GetOutText ${win_name}] tag bind $tag <Enter> ""
		[::ChatWindow::GetOutText ${win_name}] tag bind $tag <Leave> ""
		[::ChatWindow::GetOutText ${win_name}] tag bind $tag <<Button1>> ""

		[::ChatWindow::GetOutText ${win_name}] conf -cursor xterm
	}

	proc SIPCallBack { email} {
		DisableSIPButton $email sipcallback$email
		SIPCallInviteUser $email
	}

	proc SIPCallMessageCallBack { chatid txt} {
		::ChatWindow::MakeFor $chatid

		DisableSIPButton $chatid sipcallback$chatid

		WinWrite $chatid "\n" green
		WinWriteIcon $chatid greyline 3
		WinWrite $chatid "\n" green
		WinWriteIcon $chatid sipicon 3 2
		WinWrite $chatid " $txt\n" green
		WinWrite $chatid " (" green
		WinWriteClickable $chatid "[trans sipcallback]" [list ::amsn::SIPCallBack $chatid] sipcallback$chatid
		WinWrite $chatid ")\n" green
		WinWriteIcon $chatid greyline 3

	}

	proc SIPCallMessage { chatid txt } {
		::ChatWindow::MakeFor $chatid

		WinWrite $chatid "\n" green
		WinWriteIcon $chatid greyline 3
		WinWrite $chatid "\n" green
		WinWriteIcon $chatid sipicon 3 2
		WinWrite $chatid " $txt\n" green
		WinWriteIcon $chatid greyline 3

	}

	proc SIPCallReceived { chatid sip callid} {

		set fromname [::abook::getDisplayNick $chatid]
		set txt [trans sipgotinvitation $fromname]
		set win_name [::ChatWindow::MakeFor $chatid $txt $chatid]

		WinWrite $chatid "\n" green
		WinWriteIcon $chatid greyline 3
		WinWrite $chatid " \n" green

		WinWriteIcon $chatid sipicon 3 2
		WinWrite $chatid $txt green
		WinWrite $chatid " - (" green
		WinWriteClickable $chatid "[trans accept]" [list ::amsn::AcceptSIPCall $chatid $sip $callid] sipyes$callid
		WinWrite $chatid " / " green
		WinWriteClickable $chatid "[trans reject]" [list ::amsn::DeclineSIPCall $chatid $sip $callid] sipno$callid
		WinWrite $chatid ")\n" green
		WinWriteIcon $chatid greyline 3
		# The phone is ringing!!
		play_sound ring.wav
	}

	proc AcceptSIPCall { chatid sip callid } {

		status_log "Accepting SIP call from $chatid"

		set win_name [::ChatWindow::For $chatid]
		if { [::ChatWindow::For $chatid] == 0} {
			return 0
		}

		DisableSIPButton $chatid sipyes$callid 
		DisableSIPButton $chatid sipno$callid 


		WinWrite $chatid "\n" green
		WinWriteIcon $chatid greyline 3
		WinWrite $chatid "\n" green
		WinWriteIcon $chatid sipicon 3 2
		WinWrite $chatid " [trans sipcallaccepted]\n" green
		WinWrite $chatid " (" green
		WinWriteClickable $chatid "[trans hangup]" [list ::amsn::HangupSIPCall $chatid $sip $callid] siphangup$callid
		WinWrite $chatid ")\n" green
		WinWriteIcon $chatid greyline 3

		::MSNSIP::AcceptInvite $sip $callid
		AddSIPchatidToList $chatid
		::ChatWindow::setCallButton $chatid [list ::amsn::HangupSIPCall $chatid $sip $callid] [trans hangup]
		::ChatWindow::UpdateVoipControls $chatid $sip $callid
	}

	proc DeclineSIPCall { chatid sip callid } {

		status_log "Rejecting SIP call from $chatid"

		set win_name [::ChatWindow::For $chatid]
		if { [::ChatWindow::For $chatid] == 0} {
			return 0
		}

		DisableSIPButton $chatid sipyes$callid 
		DisableSIPButton $chatid sipno$callid 


		SIPCallMessage $chatid [trans sipcalldeclined]

		::MSNSIP::DeclineInvite $sip $callid
		DelSIPchatidFromList $chatid
		::ChatWindow::setCallButton $chatid "::amsn::InviteCallFromCW [::ChatWindow::For $chatid]" [trans sendsip] 0
		::ChatWindow::RemoveVoipControls $chatid
	}

	proc HangupSIPCall { chatid sip callid } {
		status_log "Hanging up SIP call"

		SIPCallEnded $chatid $sip $callid

		::MSNSIP::HangUp $sip $callid
		DelSIPchatidFromList $chatid
		::ChatWindow::setCallButton $chatid "::amsn::InviteCallFromCW [::ChatWindow::For $chatid]" [trans sendsip] 0
		::ChatWindow::RemoveVoipControls $chatid
	}

	proc CancelSIPCall { chatid sip callid} {
		status_log "Canceling SIP invite"

		DisableSIPButton $chatid siphangup$callid 

		::MSNSIP::CancelCall $sip $callid
		DelSIPchatidFromList $chatid
		::ChatWindow::setCallButton $chatid "::amsn::InviteCallFromCW [::ChatWindow::For $chatid]" [trans sendsip] 0
		::ChatWindow::RemoveVoipControls $chatid
	}

	proc SIPInviteSent { chatid sip callid } {
		status_log "SIP invite sent"

		WinWrite $chatid "\n" green
		WinWriteIcon $chatid greyline 3
		WinWrite $chatid "\n" green
		WinWriteIcon $chatid sipicon 3 2
		WinWrite $chatid " [trans sipcallsent [::abook::getDisplayNick $chatid]]\n" green
		WinWrite $chatid " (" green
		WinWriteClickable $chatid "[trans hangup]" [list ::amsn::CancelSIPCall $chatid $sip $callid] siphangup$callid
		WinWrite $chatid ")\n" green
		WinWriteIcon $chatid greyline 3
		# Can be weird to ring the phone there, but i think it's useful
		play_sound ring.wav
		::ChatWindow::setCallButton $chatid [list ::amsn::CancelSIPCall $chatid $sip $callid] [trans hangup]
		::ChatWindow::UpdateVoipControls $chatid $sip $callid
	}

	proc SIPCallEnded {chatid sip callid } {
		status_log "SIP call ended"

		SIPCallMessage $chatid [trans sipcallended]

		DisableSIPButton $chatid siphangup$callid 
		DelSIPchatidFromList $chatid
		::ChatWindow::setCallButton $chatid "::amsn::InviteCallFromCW [::ChatWindow::For $chatid]" [trans sendsip] 0
		::ChatWindow::RemoveVoipControls $chatid
	}

	proc SIPCalleeAccepted { chatid sip callid } {
		::ChatWindow::MakeFor $chatid

		status_log "SIP callee accepted our call"

		set win_name [::ChatWindow::For $chatid]
		if { [::ChatWindow::For $chatid] == 0} {
			return 0
		}

		SIPCallMessage $chatid [trans sipcalleeaccepted]

		# Modify Hangup button to hangup instead of cancel call 
		[::ChatWindow::GetOutText ${win_name}] tag bind siphangup$callid <<Button1>> [list ::amsn::HangupSIPCall $chatid $sip $callid]
		::ChatWindow::setCallButton $chatid [list ::amsn::HangupSIPCall $chatid $sip $callid] [trans hangup]
		::ChatWindow::UpdateVoipControls $chatid $sip $callid

	}
	proc SIPCallConnected { chatid sip callid } {
		::ChatWindow::MakeFor $chatid
		::ChatWindow::Status [ ::ChatWindow::For $chatid ] "Your audio call is now connected!"
		::ChatWindow::UpdateVoipControls $chatid $sip $callid

	}

	proc SIPCalleeBusy { chatid sip callid } {

		status_log "SIP callee is busy"

		SIPCallMessage $chatid [trans sipcalleebusy]

		DisableSIPButton $chatid siphangup$callid 
		DelSIPchatidFromList $chatid
		::ChatWindow::setCallButton $chatid "::amsn::InviteCallFromCW [::ChatWindow::For $chatid]" [trans sendsip] 0
		::ChatWindow::RemoveVoipControls $chatid
	}

	proc SIPCalleeDeclined { chatid sip callid } {
		status_log "SIP callee declined our call"

		SIPCallMessage $chatid [trans sipcalleedeclined]

		DisableSIPButton $chatid siphangup$callid 
		DelSIPchatidFromList $chatid
		::ChatWindow::setCallButton $chatid "::amsn::InviteCallFromCW [::ChatWindow::For $chatid]" [trans sendsip] 0
		::ChatWindow::RemoveVoipControls $chatid
	}

	proc SIPCalleeClosed { chatid sip callid } {
		status_log "SIP callee closed the call"

		SIPCallMessage $chatid [trans sipcalleeclosed]

		DisableSIPButton $chatid siphangup$callid 
		DelSIPchatidFromList $chatid
		::ChatWindow::setCallButton $chatid "::amsn::InviteCallFromCW [::ChatWindow::For $chatid]" [trans sendsip] 0
		::ChatWindow::RemoveVoipControls $chatid
	}

	proc SIPCalleeNoAnswer { chatid sip callid }  {
		status_log "SIP user did not answer our call"

		SIPCallMessage $chatid [trans sipcalleenoanswer]

		DisableSIPButton $chatid siphangup$callid 
		DelSIPchatidFromList $chatid
		::ChatWindow::setCallButton $chatid "::amsn::InviteCallFromCW [::ChatWindow::For $chatid]" [trans sendsip] 0
		::ChatWindow::RemoveVoipControls $chatid
	}

	proc SIPCalleeUnavailable { chatid sip callid }  {
		status_log "SIP user is currently unavailable"

		SIPCallMessage $chatid [trans sipcalleeunavailable]

		DisableSIPButton $chatid siphangup$callid 
		DelSIPchatidFromList $chatid
		::ChatWindow::setCallButton $chatid "::amsn::InviteCallFromCW [::ChatWindow::For $chatid]" [trans sendsip] 0
		::ChatWindow::RemoveVoipControls $chatid
	}

	proc SIPCallImpossible { chatid } {
		status_log "SIP call is impossible.. no farsight utility found/working"

		SIPCallMessage $chatid [trans sipcallimpossible]
		DelSIPchatidFromList $chatid
		::ChatWindow::setCallButton $chatid "::amsn::InviteCallFromCW [::ChatWindow::For $chatid]" [trans sendsip] 0
		::ChatWindow::RemoveVoipControls $chatid
	}

	proc SIPCallUnsupported { chatid } {
		status_log "Received unsupported SIP call from $chatid"

		SIPCallMessageCallBack $chatid [trans sipcallunsupported]
		DelSIPchatidFromList $chatid
		::ChatWindow::setCallButton $chatid "::amsn::InviteCallFromCW [::ChatWindow::For $chatid]" [trans sendsip] 0
		::ChatWindow::RemoveVoipControls $chatid
	}

	proc SIPCallNoSIPFlag { chatid } {
		status_log "User $chatid has no SIP flag in his clientid"
		SIPCallMessage $chatid [trans sipcallnosipflag]
		DelSIPchatidFromList $chatid
		::ChatWindow::setCallButton $chatid "::amsn::InviteCallFromCW [::ChatWindow::For $chatid]" [trans sendsip] 0
		::ChatWindow::RemoveVoipControls $chatid
	}

	proc SIPCallMissed { chatid {callid ""} } {
		status_log "We missed a SIP call from $chatid"

		SIPCallMessageCallBack $chatid [trans sipcallmissed [::abook::getDisplayNick $chatid]]
		if {$callid != "" } {
			DisableSIPButton $chatid sipyes$callid
			DisableSIPButton $chatid sipno$callid
		}
		DelSIPchatidFromList $chatid
		::ChatWindow::setCallButton $chatid "::amsn::InviteCallFromCW [::ChatWindow::For $chatid]" [trans sendsip] 0
		::ChatWindow::RemoveVoipControls $chatid
	}

	proc SIPCallYouAreBusy { chatid } {
		status_log "Trying to make multiple SIP calls"

		SIPCallMessage $chatid [trans sipcallyouarebusy]
		DelSIPchatidFromList $chatid
		::ChatWindow::setCallButton $chatid "::amsn::InviteCallFromCW [::ChatWindow::For $chatid]" [trans sendsip] 0
		::ChatWindow::RemoveVoipControls $chatid
	}


	proc SIPCalleeCanceled { chatid sip callid } {

		status_log "SIP callee canceled his invite"

		set win_name [::ChatWindow::For $chatid]
		if { [::ChatWindow::For $chatid] == 0} {
			return 0
		}

		DisableSIPButton $chatid sipyes$callid 
		DisableSIPButton $chatid sipno$callid 


		SIPCallMessage $chatid [trans sipcalleecanceled]
		DelSIPchatidFromList $chatid
		::ChatWindow::setCallButton $chatid "::amsn::InviteCallFromCW [::ChatWindow::For $chatid]" [trans sendsip] 0
		::ChatWindow::RemoveVoipControls $chatid
	}

	#///////////////////////////////////////////////////////////////////////////////
	# PUBLIC messageFrom(chatid,user,msg,type,[fontformat])
	# Called by the protocol layer when a message 'msg' arrives from the chat
	# 'chatid'.'user' is the login of the message sender, and 'user' can be "msg" to
	# send special messages not prefixed by "XXX says:". 'type' can be a style tag as
	# defined in the ::ChatWindow::Open proc, or just "user". If the type is "user",
	# the 'fontformat' parameter will be used as font format.
	# The procedure will open a window if it does not exists, add a notifyWindow and
	# play a sound if it's necessary
	proc messageFrom { chatid user nick message type {p4c 0} } {
		global remote_auth

		set fonttype [$message getHeader X-MMS-IM-Format]

		set begin [expr {[string first "FN=" $fonttype]+3}]
		set end   [expr {[string first ";" $fonttype $begin]-1}]
		set fontfamily "[urldecode [string range $fonttype $begin $end]]"

		set begin [expr {[string first "EF=" $fonttype]+3}]
		set end   [expr {[string first ";" $fonttype $begin]-1}]
		set fontstyle "[urldecode [string range $fonttype $begin $end]]"

		set begin [expr {[string first "CO=" $fonttype]+3}]
		set end   [expr {[string first ";" $fonttype $begin]-1}]
		set fontcolor "000000[urldecode [string range $fonttype $begin $end]]"
		set fontcolor "[string range $fontcolor end-1 end][string range $fontcolor end-3 end-2][string range $fontcolor end-5 end-4]"

		set style [list]
		if {[string first "B" $fontstyle] >= 0} {
			lappend style "bold"
		}
		if {[string first "I" $fontstyle] >= 0} {
			lappend style "italic"
		}
		if {[string first "U" $fontstyle] >= 0} {
			lappend style "underline"
		}
		if {[string first "S" $fontstyle] >= 0} {
			lappend style "overstrike"
		}
		if { [::config::getKey disableuserfonts] } {	 
			# If user wants incoming and outgoing messages to have the same font
			set fontfamily [lindex [::config::getKey mychatfont] 0]	 
			set style [lindex [::config::getKey mychatfont] 1]	 
			#set fontcolor [lindex [::config::getKey mychatfont] 2]	 
		} elseif { [::config::getKey theirchatfont] != "" && $user != [::config::getKey login] } {
			# If user wants to specify a font for incoming messages (to override that user's font)
			foreach { fontfamily style fontcolor } [::config::getKey theirchatfont] {}
			#set fontfamily [lindex  0]	 
			#set style [lindex [::config::getKey theirchatfont] 1]
			#set fontcolor [lindex [::config::getKey theirchatfont 2]
		}

		#if customfnick exists replace the nick with customfnick
		set customfnick [::abook::getVolatileData $user parsed_customfnick]

		if { $customfnick != "" } {
			set nick [::abook::getNick $user 1]
			set customnick [::abook::getVolatileData $user parsed_customnick]
			set nick [::abook::removeStyles [::abook::parseCustomNickStyled $customfnick $nick $user $customnick]]
		}
		
		set msg [$message getBody]

		set maxw [expr {[::skin::getKey notifwidth]-20}]
		incr maxw [expr {0-[font measure splainf -displayof . "[trans says [list]]:"]}]
		set nickt [trunc $nick $maxw splainf]

		#if { ([::config::getKey notifymsg] == 1) && ([string first ${win_name} [focus]] != 0)} {
		#	notifyAdd "[trans says $nickt]:\n$msg" "::amsn::chatUser $chatid"
		#}
		set tmsg "[trans says $nickt]:\n$msg"

		set win_name [::ChatWindow::MakeFor $chatid $tmsg $user]

		if { $remote_auth == 1 } {
			if { "$user" != "$chatid" } {
				write_remote "To $chatid : $msg" msgsent
			} else {
				write_remote "From $chatid : $msg" msgrcv
			}
		}

		PutMessage $chatid $user $nick $msg $type [list $fontfamily $style $fontcolor] $p4c
	}
	#///////////////////////////////////////////////////////////////////////////////

	#///////////////////////////////////////////////////////////////////////////////
	# PUBLIC ShowInk(chatid,user,image,type,p4c)
	# Called by the protocol layer when an ink 'image' arrives from the chat
	# 'chatid'.'user' is the login of the message sender, and 'user' can be "msg" to
	# send special messages not prefixed by "XXX says:". 'type' can be a style tag as
	# defined in the ::ChatWindow::Open proc, or just "user". If the type is "user",
	# the 'fontformat' parameter will be used as font format.
	# The procedure will open a window if it does not exists, add a notifyWindow and
	# play a sound if it's necessary
	proc ShowInk { chatid user nick image type {p4c 0} } {
		global remote_auth

		#if customfnick exists replace the nick with customfnick
		set customfnick [::abook::getVolatileData $user parsed_customfnick]

		if { $customfnick != "" } {
			set nick [::abook::getNick $user 1]
			set customnick [::abook::getVolatileData $user parsed_customnick]
			set nick [::abook::removeStyles [::abook::parseCustomNickStyled $customfnick $nick $user $customnick]]
		}
		
		set maxw [expr {[::skin::getKey notifwidth]-20}]
		incr maxw [expr {0-[font measure splainf -displayof . "[trans says [list]]:"]}]
		set nickt [trunc $nick $maxw splainf]
		set tmsg "[trans gotink $user]"
		set win_name [::ChatWindow::MakeFor $chatid $tmsg $user]

		PutMessageWrapped $chatid $user $nickt "" $type "" $p4c
		
		set scrolling [::ChatWindow::getScrolling [::ChatWindow::GetOutText ${win_name}]]
		[::ChatWindow::GetOutText ${win_name}] image create end -image $image
		if { $scrolling } { ::ChatWindow::Scroll [::ChatWindow::GetOutText ${win_name}] }
	}
	#///////////////////////////////////////////////////////////////////////////////


	#///////////////////////////////////////////////////////////////////////////////
	# enterCustomStyle ()
	# Dialog window to edit the custom chat style
	proc enterCustomStyle {} {
		set w .change_custom_style
		if {[winfo exists $w]} {
			raise $w
			return 0
		}

		toplevel $w
		wm group $w .
		wm title $w "[trans customstyle]"

		frame $w.fn
		label $w.fn.label -font sboldf -text "[trans customstyle]:"
		entry $w.fn.ent -width 40 -bd 1 -font splainf
		menubutton $w.fn.help -font sboldf -text "<-" -menu $w.fn.help.menu
		menu $w.fn.help.menu -tearoff 0
		$w.fn.help.menu add command -label [trans nick] -command "$w.fn.ent insert insert \\\$nick"
		$w.fn.help.menu add command -label [trans timestamp] -command "$w.fn.ent insert insert \\\$tstamp"
		$w.fn.help.menu add command -label [trans newline] -command "$w.fn.ent insert insert \\\$newline"
		$w.fn.help.menu add separator
		$w.fn.help.menu add command -label [trans delete] -command "$w.fn.ent delete 0 end"
		$w.fn.ent insert end [::config::getKey customchatstyle]

		frame $w.fb
		button $w.fb.ok -text [trans ok] -command [list ::amsn::enterCustomStyleOk $w]
		button $w.fb.cancel -text [trans cancel] -command "destroy $w"

		pack $w.fn.label $w.fn.ent $w.fn.help -side left -fill x -expand true
		pack $w.fb.ok $w.fb.cancel -side right -padx 5

		pack $w.fn $w.fb -side top -fill x -expand true -padx 5

		bind $w.fn.ent <Return> [list ::amsn::enterCustomStyleOk $w]

		catch {
			raise $w
			focus -force $w.fn.ent
		}
		moveinscreen $w 30
	}

	proc enterCustomStyleOk {w} {
		::config::setKey customchatstyle [$w.fn.ent get]
		destroy $w
	}


	#///////////////////////////////////////////////////////////////////////////////
	# userJoins (chatid, user_name)
	# called from the protocol layer when a user JOINS a chat
	# It should be called after a JOI in the switchboard.
	# If a window exists, it will show "user joins conversation" in the status bar
	# - 'chatid' is the chat name
	# - 'usr_name' is the user that joins email
	proc userJoins { chatid usr_name {create_win 1} } {
		set win_name [::ChatWindow::For $chatid]

		if { $create_win && $win_name == 0 && [::config::getKey newchatwinstate]!=2 } {
			set win_name [::ChatWindow::MakeFor $chatid "" $usr_name]

			# PostEvent 'new_conversation' to notify plugins that the window was created
			set evPar(chatid) $chatid
			set evPar(usr_name) $usr_name
			::plugins::PostEvent new_conversation evPar
		}

		if { $win_name != 0 } {

			set statusmsg "[timestamp] [trans joins [::abook::getDisplayNick $usr_name]]\n"
			::ChatWindow::Status [ ::ChatWindow::For $chatid ] $statusmsg minijoins
			::ChatWindow::TopUpdate $chatid

			if { [winfo exists [::ChatWindow::GetOutDisplayPicturesFrame $win_name].dps] } {
				::amsn::ShowOrHidePicture
				::amsn::ShowOrHideTopPicture
				::amsn::UpdatePictures $win_name
			} else {
				if { [::config::getKey showdisplaypic] && $usr_name != ""} {
					::amsn::ChangePicture $win_name [::skin::getDisplayPicture $usr_name] [trans showuserpic $usr_name]
				} else {
					::amsn::ChangePicture $win_name [::skin::getDisplayPicture $usr_name] [trans showuserpic $usr_name] nopack
				}
			}

			if { [::config::getKey leavejoinsinchat] == 1 } {
				
				SendMessageFIFO [list ::amsn::WinWriteJoin $chatid $usr_name] "::amsn::messages_stack($chatid)" "::amsn::messages_flushing($chatid)"
			}
		}

		if { [::config::getKey keep_logs] } {
			::log::JoinsConf $chatid $usr_name
		}
		#Postevent when user joins a chat
		set evPar(usr_name) usr_name
		set evPar(chatid) chatid
		set evPar(win_name) win_name
		::plugins::PostEvent user_joins_chat evPar
	}

	proc WinWriteJoin {chatid usr_name} {
		::amsn::WinWrite $chatid "\n" green "" 0
		::amsn::WinWriteIcon $chatid minijoins 5 0
		::amsn::WinWrite $chatid "[timestamp] [trans joins [::abook::getDisplayNick $usr_name]]" green "" 0
	}
	#///////////////////////////////////////////////////////////////////////////////


	#///////////////////////////////////////////////////////////////////////////////
	# userLeaves (chatid, user_name)
	# called from the protocol layer when a user LEAVES a chat.
	# It will show the status message. No need to show it if the window is already
	# closed, right?
	# - 'chatid' is the chat name
	# - 'usr_name' is the user email to show in the status message
	proc userLeaves { chatid usr_name closed } {
		global automsgsent

		set win_name [::ChatWindow::For $chatid]
		if { $win_name == 0} {
			return 0
		}

		set username [::abook::getDisplayNick $usr_name]

		if { $closed } {
			set statusmsg "[timestamp] [trans leaves $username]\n"
			set icon minileaves

			if { [::config::getKey leavejoinsinchat] == 1 } {
				SendMessageFIFO [list ::amsn::WinWriteLeave $chatid $username] "::amsn::messages_stack($chatid)" "::amsn::messages_flushing($chatid)"
			}

		} else {
			set statusmsg "[timestamp] [trans closed $username]\n"
			set icon minileaves
		}

		if { [winfo exists [::ChatWindow::GetOutDisplayPicturesFrame $win_name].dps] } {
			::amsn::UpdatePictures $win_name
		} else {
			#Check if the image that is currently showing is
			#from the user that left. Then, change it
			set current_image ""
			#Catch it, because the window might be closed
			catch {set current_image [[::ChatWindow::GetInDisplayPictureFrame $win_name].pic.image cget -image]}
			if { [string compare $current_image [::skin::getDisplayPicture $usr_name]]==0} {
				set users_in_chat [::MSN::usersInChat $chatid]
				set new_user [lindex $users_in_chat 0]
				::amsn::ChangePicture $win_name [::skin::getDisplayPicture $new_user] [trans showuserpic $new_user] nopack
			}
		}

		::ChatWindow::Status $win_name $statusmsg $icon


		::ChatWindow::TopUpdate $chatid

		if { [::config::getKey keep_logs] } {
			::log::LeavesConf $chatid $usr_name
		}

		# Unset automsg if he leaves so that it sends again on next msg
		if { [info exists automsgsent($usr_name)] } {
			unset automsgsent($usr_name)
		}
		#Postevent when user leaves a chat
		set evPar(usr_name) usr_name
		set evPar(chatid) chatid
		set evPar(win_name) win_name
		::plugins::PostEvent user_leaves_chat evPar
	}

	proc WinWriteLeave {chatid username} {
		::amsn::WinWrite $chatid "\n" green "" 0
		::amsn::WinWriteIcon $chatid minileaves 5 0
		::amsn::WinWrite $chatid "[timestamp] [trans leaves $username]" green "" 0
	}
	#///////////////////////////////////////////////////////////////////////////////



	#///////////////////////////////////////////////////////////////////////////////
	# updateTypers (chatid)
	# Called from the protocol.
	# Asks the protocol layer to get a list of typing users in the chat, and shows
	# a message in the status bar.
	# - 'chatid' is the name of the chat
	proc updateTypers { chatid } {
		if {[::ChatWindow::For $chatid] == 0} {
			return 0
		}

		set typers_list [::MSN::typersInChat $chatid]

		set typingusers ""

		foreach login $typers_list {
			set user_name [::abook::getDisplayNick $login]
			set typingusers "${typingusers}${user_name}, "
		}

		set typingusers [string replace $typingusers end-1 end ""]

		set statusmsg ""
		set icon ""

		if {[llength $typers_list] == 0} {
			set lasttime [::MSN::lastMessageTime $chatid]
			if { $lasttime != 0 } {
				set statusmsg "[trans lastmsgtime $lasttime]"
			}
		} elseif {[llength $typers_list] == 1} {
			set statusmsg " [trans istyping $typingusers]."
			set icon typingimg
		} else {
			set statusmsg " [trans aretyping $typingusers]."
			set icon typingimg
		}

		::ChatWindow::Status [::ChatWindow::For $chatid] $statusmsg $icon
	}
	#///////////////////////////////////////////////////////////////////////////////

	if { $initialize_amsn == 1 } {
		variable clipboard ""
	}

	proc ToggleShowPicture { } {
		if { [::config::getKey showdisplaypic 0] == 1 } {
			::config::setKey showdisplaypic 0
		} else {
			::config::setKey showdisplaypic 1
		}
		::amsn::ShowOrHidePicture
	}

	proc ShowTopPicMenu { win user x y } {
		catch {menu $win.picmenu -tearoff 0}
		$win.picmenu delete 0 end

		#Make the picture menu appear on the conversation window instead of having it in the bottom of screen (and sometime lost it if the conversation window is in the bottom of the window)
		if { [OnMac] } {
			#Cursor at the top right hand corner (NE) of the popup.
			incr x -123
			incr y +2
		}

		set chatid [::ChatWindow::Name $win]
		set pic [::skin::getDisplayPicture $user]
		if { $pic != "displaypicture_std_none" && $user != ""} {
			$win.picmenu add command -label "[trans changesize]" -command [list ::amsn::ShowTopPicMenu $win $user $x $y]
			#4 possible size (someone can add something to let the user choose his size)
			$win.picmenu add command -label " -> [trans small]" -command "::skin::ConvertDPSize $user 64 64; ::amsn::UpdateAllPictures"
			$win.picmenu add command -label " -> [trans default2]" -command "::skin::ConvertDPSize $user 96 96; ::amsn::UpdateAllPictures"
			$win.picmenu add command -label " -> [trans large]" -command "::skin::ConvertDPSize $user 128 128; ::amsn::UpdateAllPictures"
			$win.picmenu add command -label " -> [trans huge]" -command "::skin::ConvertDPSize $user 192 192; ::amsn::UpdateAllPictures"
			#Get back to original picture
			$win.picmenu add command -label " -> [trans original]" -command "::MSNP2P::loadUserPic $chatid $user 1"
			tk_popup $win.picmenu $x $y
		}
	}
	proc ShowPicMenu { win x y } {
		status_log "Show menu in window $win, position $x $y\n" blue
		catch {menu $win.picmenu -tearoff 0}
		$win.picmenu delete 0 end

		#Make the picture menu appear on the conversation window instead of having it in the bottom of screen (and sometime lost it if the conversation window is in the bottom of the window)
		if { [OnMac] } {
			#Cursor in the bottom right hand corner (SE) of the popup.
			incr x -212
			incr y -25
		}
	
		#Load Change Display Picture window
		$win.picmenu add command -label "[trans changedisplaypic]..." -command pictureBrowser

		tk_popup $win.picmenu $x $y
	}

	proc ShowOldPicMenu { win x y } {
		status_log "Show menu in window $win, position $x $y\n" blue
		catch {menu $win.picmenu -tearoff 0}
		$win.picmenu delete 0 end

		#Make the picture menu appear on the conversation window instead of having it in the bottom of screen (and sometime lost it if the conversation window is in the bottom of the window)
		if { [OnMac] } {
			incr x -50
			incr y -115
		}

		set chatid [::ChatWindow::Name $win]
		set users [::MSN::usersInChat $chatid]
		#Switch to "my picture" or "user picture"
		$win.picmenu add command -label "[trans showmypic]" \
			-command [list ::amsn::ChangePicture $win displaypicture_std_self [trans mypic]]
		foreach user $users {
			$win.picmenu add command -label "[trans showuserpic $user]" \
				-command "::amsn::ChangePicture $win \[::skin::getDisplayPicture $user\] \[trans showuserpic $user\]"
		}

		set user [[::ChatWindow::GetInDisplayPictureFrame $win].pic.image cget -image]
		if { $user != "[::skin::getNoDisplayPicture]" && $user != "displaypicture_std_self" } {
			#made easy for if we would change the image names
			set user [string range $user [string length "displaypicture_std_"] end]
			$win.picmenu add separator
			#Sub-menu to change size
			$win.picmenu add cascade -label "[trans changesize]" -menu $win.picmenu.size
			catch {menu $win.picmenu.size -tearoff 0 -type normal}
			$win.picmenu.size delete 0 end
			#4 possible size (someone can add something to let the user choose his size)
			$win.picmenu.size add command -label "[trans small]" -command "::skin::ConvertDPSize $user 64 64; ::amsn::UpdateAllPictures"
			$win.picmenu.size add command -label "[trans default2]" -command "::skin::ConvertDPSize $user 96 96; ::amsn::UpdateAllPictures"
			$win.picmenu.size add command -label "[trans large]" -command "::skin::ConvertDPSize $user 128 128; ::amsn::UpdateAllPictures"
			$win.picmenu.size add command -label "[trans huge]" -command "::skin::ConvertDPSize $user 192 192; ::amsn::UpdateAllPictures"
			#Get back to original picture
			$win.picmenu.size add command -label "[trans original]" -command "::MSNP2P::loadUserPic $chatid $user 1"
		}
		tk_popup $win.picmenu $x $y
	}

	proc ChangePicture {win picture balloontext {nopack ""}} {
		#pack [::ChatWindow::GetInDisplayPictureFrame $win].image -side left -padx 2 -pady 2

		set scrolling [::ChatWindow::getScrolling [::ChatWindow::GetOutText $win]]


		#Get the path to the image
		set f [::ChatWindow::GetInDisplayPictureFrame $win]
		set pictureinner [$f.pic.image getinnerframe]
		if { $balloontext != "" } {
			#TODO: Improve this!!! Use some kind of abstraction!
			change_balloon $pictureinner $balloontext
			#change_balloon [::ChatWindow::GetInDisplayPictureFrame $win].image $balloontext
		}
		if { [catch {[::ChatWindow::GetInDisplayPictureFrame $win].pic.image configure -image $picture}] } {
			status_log "Failed to set picture, using [::skin::getNoDisplayPicture]\n" red
			[::ChatWindow::GetInDisplayPictureFrame $win].pic.image configure -image [::skin::getNoDisplayPicture]
			#change_balloon [::ChatWindow::GetInDisplayPictureFrame $win].image [trans nopic]
			change_balloon $pictureinner [trans nopic]
		} elseif { $nopack == "" } {
			pack [::ChatWindow::GetInDisplayPictureFrame $win].pic.image -side left -padx 0 -pady 0 -anchor w
			[::ChatWindow::GetInDisplayPictureFrame $win].pic.showpic configure -image [::skin::loadPixmap imghide]
			bind [::ChatWindow::GetInDisplayPictureFrame $win].pic.showpic <Enter> "[::ChatWindow::GetInDisplayPictureFrame $win].pic.showpic configure -image [::skin::loadPixmap imghide_hover]"
			bind [::ChatWindow::GetInDisplayPictureFrame $win].pic.showpic <Leave> "[::ChatWindow::GetInDisplayPictureFrame $win].pic.showpic configure -image [::skin::loadPixmap imghide]"
			change_balloon [::ChatWindow::GetInDisplayPictureFrame $win].pic.showpic [trans hidedisplaypic]
			::config::setKey showdisplaypic 1
		}

		if { $scrolling } {
			update idletasks
			::ChatWindow::Scroll [::ChatWindow::GetOutText $win]
		}
		#compute the size of the frame
		if {[::config::getKey showdisplaypic 1] == 1 } {
			set max_width [image width $picture]
			if {[winfo exists $f.voip.volume] && $max_width <100} {
				set max_width 100
			}
			incr max_width [image width [::skin::loadPixmap imghide]]
		} else {
			set max_width 0
			if {[winfo exists $f.voip.volume] && $max_width <100} {
				set max_width 100
			}
			incr max_width [image width [::skin::loadPixmap imgshow]]
		}
		set width [expr {$max_width + (2 * [::skin::getKey chat_dp_border])}]
		[winfo parent $f] configure -width $width
	}

	proc UpdateAllPictures { } {
		set chatids [::ChatWindow::getAllChatIds]
		# Loop through the chats
		foreach chat $chatids {
			set win [::ChatWindow::For $chat]
			
			if { [winfo exists [::ChatWindow::GetOutDisplayPicturesFrame $win].dps]} {
				::amsn::UpdatePictures $win
			}
		}	
	}

	proc UpdatePictures { win } {
		set f  [::ChatWindow::GetOutDisplayPicturesFrame $win]
		set images $f.dps.imgs
		set chatid [::ChatWindow::Name $win]
		set users [::MSN::usersInChat $chatid]

		foreach child [winfo children $images] {
			destroy $child
		}

		# don't show user labels if there's only one user
		set show_user_labels 0
		if {[llength $users] > 1} {
			set show_user_labels 1
		}

		# Calculate the max width of the DPs shown, so we can know how much pixels to truncate all the labels
		set max_width 0
		foreach user $users {
			set new_width [image width [::skin::getDisplayPicture $user]]
			if {$new_width > $max_width } {
				set max_width $new_width
			}
		}

		set idx 0
		foreach user $users {
			if {$show_user_labels == 1} {
				set truncated [trunc [::abook::getDisplayNick $user] $images [expr {${max_width}-10}] sitalf 1]
	
				label $images.user_name$idx \
				    -background [::skin::getKey chatwindowbg] \
				    -relief flat -font sitalf -text $truncated

				pack $images.user_name$idx -side top -padx 0 -pady 0 -anchor n
			}
	
			framec $images.user_dp$idx -type label -relief solid -image [::skin::getDisplayPicture $user] \
			    -borderwidth [::skin::getKey chat_dp_border] \
			    -bordercolor [::skin::getKey chat_dp_border_color] \
			    -background [::skin::getKey chatwindowbg]\
			    -foreground [::skin::getKey statusbartext]; #TODO: add skin key
			set pictureinner [$images.user_dp$idx getinnerframe]
			bind $pictureinner <<Button1>> [list ::amsn::ShowTopPicMenu $win $user %X %Y]
			bind $pictureinner <<Button3>> [list ::amsn::ShowTopPicMenu $win $user %X %Y]
#TODO: support changing cusom dp's in the drophandler
#			::dnd bindtarget $pictureinner Files <Drop> "fileDropHandler %D setdp $user"
			pack $images.user_dp$idx -side top -padx 0 -pady 0 -anchor n

			set_balloon $pictureinner [trans showuserpic $user]

			incr idx
		}

		#compute the size of the frame
		if {[::config::getKey ShowTopPicture 0] == 1 } {
			if {[winfo exists $f.voip.volume] && $max_width <100} {
				set max_width 100
			}
			incr max_width [image width [::skin::loadPixmap imghide]]
		} else {
			set max_width 0
			if {[winfo exists $f.voip.volume] && $max_width <100} {
				set max_width 100
			}
			incr max_width [image width [::skin::loadPixmap imgshow]]
		}
		set width [expr {$max_width + (2 * [::skin::getKey chat_dp_border])}]
		[winfo parent $f] configure -width $width
	}

	proc HidePicture { win } {
		set f [::ChatWindow::GetInDisplayPictureFrame $win]
		set dpframe $f.pic
		pack forget $dpframe.image

		#grid [::ChatWindow::GetInDisplayPictureFrame $win].showpic -row 0 -column 1 -padx 0 -pady 0 -rowspan 2
		#Change here to change the icon, instead of text
		$dpframe.showpic configure -image [::skin::loadPixmap imgshow]
		bind $dpframe.showpic <Enter> "$dpframe.showpic configure -image [::skin::loadPixmap imgshow_hover]"
		bind $dpframe.showpic <Leave> "$dpframe.showpic configure -image [::skin::loadPixmap imgshow]"

		change_balloon $dpframe.showpic [trans showdisplaypic]

		set width [expr {2 * [::skin::getKey chat_dp_border]+[image width [::skin::loadPixmap imgshow]]}]
		if {[winfo exists $f.voip.volume] && $width <100} {
			set width 100
		}
		[winfo parent $f] configure -width $width
	}

	proc ShowOrHidePicture { } {
		set chatids [::ChatWindow::getAllChatIds]
		# Loop through the chats
		foreach chat $chatids {
			set win [::ChatWindow::For $chat]
			
			if { $win != 0 } {
				if { [::config::getKey showdisplaypic 1] == 1} {
					if {[winfo exists [::ChatWindow::GetOutDisplayPicturesFrame $win].dps] } {
						::amsn::ChangePicture $win displaypicture_std_self [trans mypic]
					} else {
						::amsn::ChangePicture $win [[::ChatWindow::GetInDisplayPictureFrame $win].pic.image cget -image] ""
					}
				} else {
					::amsn::HidePicture $win
				}
			}
		}
	}

	proc ToggleShowTopPicture { } {
		if {[::config::getKey ShowTopPicture 0] == 1 } {
			::config::setKey ShowTopPicture 0
		} else {
			::config::setKey ShowTopPicture 1
		}
		ShowOrHideTopPicture
	}

	proc ShowOrHideTopPicture { } {
		set chatids [::ChatWindow::getAllChatIds]
		# Loop through the chats
		foreach chat $chatids {
			set win [::ChatWindow::For $chat]
		
			if { $win != 0 } {
				if { [winfo exists [::ChatWindow::GetOutDisplayPicturesFrame $win].dps] } {
					if { [::config::getKey ShowTopPicture 1] == 1} {
						ShowTopPicture $win
					} else {
						HideTopPicture $win
					}
				}
			}
		}
	}



	proc ShowTopPicture {win } {
		set f [::ChatWindow::GetOutDisplayPicturesFrame $win]
		set frame $f.dps
		set scrolling [::ChatWindow::getScrolling [::ChatWindow::GetOutText $win]]
		pack $frame.imgs -side left -expand false -anchor ne

		$frame.showpic configure -image [::skin::loadPixmap imghide]
		bind $frame.showpic <Enter> [list $frame.showpic configure -image [::skin::loadPixmap imghide_hover]]
		bind $frame.showpic <Leave> [list $frame.showpic configure -image [::skin::loadPixmap imghide]]
		change_balloon $frame.showpic [trans hidedisplaypic]
		
		#UGLY:
		set width [expr {96 + (2 * [::skin::getKey chat_dp_border]+[image width [::skin::loadPixmap imghide]])}]
		if {[winfo exists $f.voip.volume] && $width <100} {
			set width 100
		}
		[winfo parent $f] configure -width $width

		if { $scrolling } {
			update idletasks
			::ChatWindow::Scroll [::ChatWindow::GetOutText $win]
		}
	}

	proc HideTopPicture { win } {
		set f [::ChatWindow::GetOutDisplayPicturesFrame $win]
		set frame $f.dps
		pack forget $frame.imgs



		#Change here to change the icon, instead of text
		$frame.showpic configure -image [::skin::loadPixmap imgshow]
		bind $frame.showpic <Enter> [list $frame.showpic configure -image [::skin::loadPixmap imgshow_hover]]
		bind $frame.showpic <Leave> [list $frame.showpic configure -image [::skin::loadPixmap imgshow]]

		change_balloon $frame.showpic [trans showdisplaypic]

		set width [expr {2 * [::skin::getKey chat_dp_border]+[image width [::skin::loadPixmap imgshow]]}]
		if {[winfo exists $f.voip.volume] && $width <100} {
			set width 100
		}
		[winfo parent $f] configure -width $width

	}
	#///////////////////////////////////////////////////////////////////////////////

	proc ShowUserList {title command {show_offlines 0} {show_nonim 0}} {
		
		#Replace for"::amsn::ChooseList \"[trans sendmsg]\" online ::amsn::chatUser 1 0"

		set userlist [list]

		foreach user_login [::MSN::sortedContactList] {
			if { [lsearch [::abook::getContactData $user_login lists] "EL"] != -1 } {
				continue
			}
			set user_state_code [::abook::getVolatileData $user_login state FLN]
			if { $user_state_code == "NLN" } {
				lappend userlist [list "[::abook::getDisplayNick $user_login] ($user_login)" $user_login]
			} elseif { $user_state_code != "FLN" || $show_offlines == 1 } {
				lappend userlist [list "[::abook::getDisplayNick $user_login] ($user_login) - ([trans [::MSN::stateToDescription $user_state_code]])" $user_login]
			}
		}

		if {$show_nonim} {
		# TODO
		#	lappend userlist [list "[::abook::getDisplayNick $user_login] ($user_login)" $user_login]
		}
		::amsn::listChoose $title $userlist $command 1 1
	}


	proc ShowAddList {title win_name command} {
		set userlist [list]
		set chatusers [::MSN::usersInChat [::ChatWindow::Name $win_name]]

		foreach user_login $chatusers {
			set user_state_code [::abook::getVolatileData $user_login state FLN]

			if { [lsearch [::abook::getLists $user_login] FL] == -1 } {
				if { $user_state_code != "NLN" } {
					lappend userlist [list "[::abook::getDisplayNick $user_login] ($user_login) - ([trans [::MSN::stateToDescription $user_state_code]])" $user_login]
				} else {
					lappend userlist [list "[::abook::getDisplayNick $user_login] ($user_login)" $user_login]
				}
			}
		}

		if { [llength $userlist] > 0 } {
			::amsn::listChoose $title $userlist $command 1 1
		} else {
			msg_box "[trans useralreadyonlist]"
		}
	}


	proc ShowInviteList { title win_name } {

		set userlist [list]
		set chatusers [::MSN::usersInChat [::ChatWindow::Name $win_name]]

		foreach user_login [::MSN::sortedContactList] {
			set user_state_code [::abook::getVolatileData $user_login state FLN]
			set user_state_no [::MSN::stateToNumber $user_state_code]

			if {($user_state_no < 7) && ([lsearch $chatusers $user_login] == -1)} {
				if { $user_state_code != "NLN" } {
					lappend userlist [list "[::abook::getDisplayNick $user_login] ($user_login) - ([trans [::MSN::stateToDescription $user_state_code]])" $user_login]
				} else {
					lappend userlist [list "[::abook::getDisplayNick $user_login] ($user_login)" $user_login]
				}
			}
		}

		set chatid [::ChatWindow::Name $win_name]

		if { [llength $userlist] > 0 } {
			::amsn::listChoose $title $userlist "::amsn::queueinviteUser [::ChatWindow::Name $win_name]" 1 0
		} else {
			cmsn_draw_otherwindow $title "::amsn::queueinviteUser [::ChatWindow::Name $win_name]"
		}
	}

	proc ShowInviteMenu { win_name x y } {
		set menulength 0
		set chatid [::ChatWindow::Name $win_name]
		set chatusers [::MSN::usersInChat $chatid]

		foreach user_login [::MSN::sortedContactList] {
			set user_state_code [::abook::getVolatileData $user_login state FLN]
			set user_state_no [::MSN::stateToNumber $user_state_code]
			if {($user_state_no < 7) && ([lsearch $chatusers $user_login] == -1)} {
				incr menulength 1
			}
		}

		if { $menulength > 20 } {
			::amsn::ShowInviteList "[trans invite]" $win_name
		} elseif { $menulength == 0 } {
			cmsn_draw_otherwindow [trans invite] "::amsn::queueinviteUser [::ChatWindow::Name $win_name]"
		} else {
			.menu_invite delete 0 end
			foreach user_login [::MSN::sortedContactList] {
				set user_state_code [::abook::getVolatileData $user_login state FLN]
				set user_state_no [::MSN::stateToNumber $user_state_code]

				if {($user_state_no < 7) && ([lsearch $chatusers $user_login] == -1)} {
					if { $user_state_code != "NLN" } {
						.menu_invite add command -label [trunc "[::abook::getDisplayNick $user_login] ([trans [::MSN::stateToDescription $user_state_code]])" "" 50] -command "::amsn::queueinviteUser $chatid $user_login"
					} else {
						.menu_invite add command -label [trunc "[::abook::getDisplayNick $user_login]" "" 50] -command "::amsn::queueinviteUser $chatid $user_login"
					}
				}
			}

			.menu_invite add separator
			.menu_invite add command -label "[trans other]..." -command [list cmsn_draw_otherwindow [trans invite] "::amsn::queueinviteUser [::ChatWindow::Name $win_name]"]
			tk_popup .menu_invite $x $y
		}

	}


	proc queueinviteUser { chatid user } {
		::MSN::ChatQueue $chatid [list ::MSN::inviteUser $chatid $user]
	}

	proc ShowChatList {title win_name command} {
		set userlist [list]
		set chatusers [::MSN::usersInChat [::ChatWindow::Name $win_name]]
		if { [llength $chatusers] == 0 } {
			#No SB yet. Check if chatid is a valid user
			#example: opened chat while appearing offline
			set chatid [::ChatWindow::Name $win_name]
			if { [lsearch [::abook::getAllContacts] $chatid] != -1 } {
				set chatusers $chatid
			}
		}

		foreach user_login $chatusers {
			set user_state_code [::abook::getVolatileData $user_login state FLN]

			if { $user_state_code != "NLN" } {
				lappend userlist [list "[::abook::getDisplayNick $user_login] ($user_login) - ([trans [::MSN::stateToDescription $user_state_code]]) " $user_login]
			} else {
				lappend userlist [list "[::abook::getDisplayNick $user_login] ($user_login)" $user_login]
			}
		}

		if { [llength $userlist] > 0 } {
			::amsn::listChoose $title $userlist $command 0 1
		} else {
			status_log "ShowChatList: No users\n"
		}

	}


	proc listChoose {title itemlist command {other 0} {skip 1}} {
		global userchoose_req
		set itemcount [llength $itemlist]
		variable itemlist_var $itemlist
		
		#If just 1 user, and $skip flag set to one, just run command on that user
		if { $itemcount == 1 && $skip == 1 && $other == 0} {
			eval $command [lindex [lindex $itemlist 0] 1]
			return 0
		}

		if { [focus] == ""  || [focus] =="." } {
			set w "._listchoose"
		} else {
			set w "[focus]._listchoose"
		}
		
		if { [catch {toplevel $w -borderwidth 0 -highlightthickness 0 } res ] } {
			raise $w
			focus $w
			return 0
		} else {
			set wname $res
		}

		wm title $w $title
		
		#No ugly blue frame on Mac OS X, system already use a border around window
		if { [OnMac] } {
			frame $w.blueframe -background [::skin::getKey topcontactlistbg]
		} else {
			frame $w.blueframe
		}
		
		wm geometry $w =350x400

		set canv $w.canv

		frame $canv -background white
		
		canvas $canv.ca -width 100 -height 200 -bg white -yscrollcommand "$canv.ys set"
		scrollbar $canv.ys -orient vertical -command "$canv.ca yview"

		frame $w.searchbar -bg white -borderwidth 1 -highlightthickness 0
		entry $w.searchbar.entry -relief flat -bg white -font splainf -selectbackground #b7d1ff -fg grey \
			-highlightcolor #aaaaaa -highlightthickness 2

		pack $canv.ys -side right -fill y
		pack $canv.ca -side left -fill both -expand true
		pack $canv -side top -fill both -expand true

		draw_listChoose $canv.ca $w $itemlist $command

		frame $w.buttons
		button  $w.buttons.ok -text "[trans ok]" -command [list ::amsn::listChooseOk $w "" $command 1]
		button  $w.buttons.cancel -text "[trans cancel]" -command [list destroy $wname]
		
		if { $other == 1 } {
			button  $w.buttons.other -text "[trans other]..." -command [list ::amsn::listChooseOther $w $title $command]
			pack $w.buttons.ok -padx 5 -side right
			pack $w.buttons.cancel -padx 5 -side right
			pack $w.buttons.other -padx 5 -side left
		} else {
			pack $w.buttons.ok -padx 5 -side right
			pack $w.buttons.cancel -padx 5 -side right
		}
		
		pack $w.buttons -side bottom -fill x -pady 3

		pack $w.searchbar.entry -fill x -side bottom
		pack $w.searchbar -fill x -side bottom
		
		catch {
			raise $w
			focus $w.buttons.ok
		}

		bind $w.searchbar.entry <KeyRelease> \
			"after cancel [list ::amsn::listChooseSearchBar $w $canv.ca $command]; \
			after 500 [list ::amsn::listChooseSearchBar $w $canv.ca $command]"
		bind $w <<Escape>> [list destroy $w]
		bind $w <Return> [list ::amsn::listChooseOk $w $itemlist $command 0]
		moveinscreen $w 30
		
	}


	proc draw_listChoose { w window itemlist command} {

		$w dchars list_choose 0 end
		$w delete list_choose bg un ov

		foreach element $itemlist {
			set user_login [lindex $element 1]
			set tag $user_login
			set lst [list ]
			lappend lst [list tag list_choose]
			set lst [concat $lst [::abook::getDisplayNick $user_login 1]]
			set user_state_code [::abook::getVolatileData $user_login state FLN]
			if { $user_state_code != "NLN" } {
				lappend lst [list text " ($user_login) - ([trans [::MSN::stateToDescription $user_state_code]])"]
			} else {
				lappend lst [list text " ($user_login)"]
			}
			lappend lst [list tag -list_choose]
			::guiContactList::renderContact $w $tag 1000 $lst
			$w bind $tag <Button-1> [list ::amsn::listChooseSelect $tag]
			$w bind $tag <Double-Button-1> [list ::amsn::listChooseOk $window $tag $command 0]
		}
		
		set y 0
		
		foreach element $itemlist {
			set tag [lindex $element 1]
			set pos [$w bbox $tag] ;#x1 y1 x2 y2
			incr y [expr {[lindex $pos 1] * -1}]
			$w move $tag 0 $y
		}

		$w configure -scrollregion [list 0 0 0 $y]


		pack $w
	}

	proc listChooseOk { wname user command fromlist} {
		variable listchooseselect
		if {$fromlist} {
			if {[catch {set user $listchooseselect}]} {
				return
			}
		}
		catch {unset listchooseselect}
		eval "$command $user"
		destroy $wname
	}

	proc listChooseSelect {tag} {
		variable listchooseselect $tag
	}

	proc listChooseSearchBar {w wcanv command} {
		variable itemlist_var
		variable original_itemlist
		
		if {![info exists original_itemlist]} {
			set original_itemlist $itemlist_var
		} else {
			set itemlist_var $original_itemlist
		}
		
		set key [string tolower [$w.searchbar.entry get]]

		if {$key eq ""} {
			set itemlist_var $original_itemlist
		} else {
			set itemlist_temp [list]
			foreach item $itemlist_var {
				if {[string first $key [string tolower [lindex $item 0]]] != -1} {
					lappend itemlist_temp $item
				}
			}
		}
		draw_listChoose $wcanv $w $itemlist_var $command
	}


	proc listChooseOther { wname title command } {
		destroy $wname
		cmsn_draw_otherwindow $title $command
		variable itemlist_var
		variable original_itemlist
		unset itemlist_var
		if { [info exists original_itemlist] } {
			unset original_itemlist
		}
	}

	#///////////////////////////////////////////////////////////////////////////////
	# TypingNotification (win_name inputbox)
	# Called by a window when the user types something into the text box. It tells
	# the protocol layer to send a typing notification to the chat that the window
	# 'win_name' is connected to
	proc TypingNotification { win_name inputbox} {
		global skipthistime

		set chatid [::ChatWindow::Name $win_name]

		if { $chatid == 0 } {
			status_log "VERY BAD ERROR in ::amsn::TypingNotification!!!\n" red
			return 0
		}

		if { $skipthistime } {
			set skipthistime 0
		} else {
			if { [string length [$inputbox get 0.0 end-1c]] == 0 } {
				CharsTyped $chatid ""
			} else {
				CharsTyped $chatid [string length [$inputbox get 0.0 end-1c]]
			}
		}

		#Works for tcl/tk 8.4 only...
		catch {
			bind $inputbox <<Modified>> ""
			$inputbox edit modified false
			bind $inputbox <<Modified>> "::amsn::TypingNotification ${win_name} $inputbox"
		}

		if { [::MSNMobile::IsMobile $chatid] == 1} {
			status_log "MOBILE CHAT\n" red
			return 0
		}
		#no typing notification for OIM
		#AIM: Try to send it, so status is rechecked
		#TODO: Maybe should try to send it only for users 
		#not in contact list
		#if {[::OIM_GUI::IsOIM $chatid] == 1 } {
		#	return 0
		#}


		#Don't queue unless chat is ready, but try to reconnect
		if { [::MSN::chatReady $chatid] } {
			if { [::config::getKey notifytyping] } {
				sb_change $chatid
			}
		} else {
			::MSN::chatTo $chatid
		}
	}
	#///////////////////////////////////////////////////////////////////////////////



	#///////////////////////////////////////////////////////////////////////////////
	# DeleteKeyPressed (win_name inputbox)
	# Called by a window when the user uses the delete key in a text box. It updates
	# the number of characters typed to be correct
	proc DeleteKeyPressed { win_name inputbox key} {
		global skipthistime

		set skipthistime 1

		set totallength [string length [$inputbox get 0.0 end-1c]]
		set x [$inputbox tag nextrange sel 0.0]
		if { $x != "" } {
			set y [string length [$inputbox get [lindex $x 0] [lindex $x 1]]]
		} elseif { $key == "Delete" && [string length [$inputbox get 0.0 insert]] == $totallength \
				|| $key == "BackSpace" && [string length [$inputbox get 0.0 insert]] == 0 } {
			set y 0
			set skipthistime 0
		} else {
			set y 1
		}
		set newlength [expr {$totallength - $y}]

		set chatid [::ChatWindow::Name $win_name]
		if { [string length [$inputbox get 0.0 end-1c]] == 0 } {
			CharsTyped $chatid ""
		} else {
			CharsTyped $chatid $newlength
		}
	}
	#///////////////////////////////////////////////////////////////////////////////



	#///////////////////////////////////////////////////////////////////////////////
	# UpKeyPressed (inputbox)
	# Called by a window when the user uses the up key in a text box. It returns
	# the index of the character 1 line above the insertion cursor
	proc UpKeyPressed { inputbox } {
		$inputbox see insert

		set bbox [$inputbox bbox insert]
		set xpos [expr {[lindex $bbox 0]+[lindex $bbox 2]/2}]
		set ypos [lindex $bbox 1]
		set height [lindex $bbox 3]
		if { $ypos > $height } {
			return [$inputbox index "@$xpos,[expr {$ypos-$height}]"]
		} else {
			$inputbox yview scroll -1 units

			update

			set ypos [lindex [$inputbox bbox insert] 1]
			set height [lindex [$inputbox bbox insert] 3]
			if { $ypos > $height } {
				return [$inputbox index "@$xpos,[expr {$ypos-$height}]"]
			}
		}
		return [$inputbox index insert]
	}
	#///////////////////////////////////////////////////////////////////////////////


	#///////////////////////////////////////////////////////////////////////////////
	# DownKeyPressed (inputbox)
	# Called by a window when the user uses the down key in a text box. It returns
	# the index of the character 1 line below the insertion cursor
	proc DownKeyPressed { inputbox } {
		$inputbox see insert

		set bbox [$inputbox bbox insert]
		set xpos [expr {[lindex $bbox 0]+[lindex $bbox 2]/2}]
		set ypos [lindex $bbox 1]
		set height [lindex $bbox 3]
		set inputboxheight [lindex [$inputbox configure -height] end]
		if { [expr {$ypos+$height}] < [expr {$inputboxheight*$height}] } {
			return [$inputbox index "@$xpos,[expr {$ypos+$height}]"]
		} else {
			$inputbox yview scroll +1 units

			update

			set ypos [lindex [$inputbox bbox insert] 1]
			set height [lindex [$inputbox bbox insert] 3]
			set inputboxheight [lindex [$inputbox configure -height] end]
			if { [expr {$ypos+$height}] < [expr {$inputboxheight*$height}] } {
				return [$inputbox index "@$xpos,[expr {$ypos+$height}]"]
			}
		}
		return [$inputbox index insert]
	}
	#///////////////////////////////////////////////////////////////////////////////



	#///////////////////////////////////////////////////////////////////////////////
	# MessageSend (win_name,input)
	# Called from a window the the user enters a message to send to the chat. It will
	# just queue the message to send in the chat associated with 'win_name', and set
	# a timeout for the message
	proc MessageSend { win_name input {custom_msg ""} {friendlyname ""}} {
		set chatid [::ChatWindow::Name $win_name]

		if { $chatid == 0 } {
			status_log "::amsn::MessageSend: TOO BAD!!! Got no chatid!\n" red
			return 0
		}

		if { $custom_msg != "" } {
			set msg $custom_msg
		} else {
			# Catch in case that $input is not a "text" control (ie: automessage).
			if { [catch { set msg [$input get 0.0 end-1c] }] } {
				set msg ""
			}
		}

		#Blank message
		if {[string length $msg] < 1} { return 0 }

		if { $input != 0 } {
			$input delete 0.0 end
			focus ${input}
		}

		set fontfamily [lindex [::config::getKey mychatfont] 0]
		set fontstyle [lindex [::config::getKey mychatfont] 1]
		set fontcolor [lindex [::config::getKey mychatfont] 2]

		if { $friendlyname != "" } {
			set nick $friendlyname
			set p4c 1
		} elseif { [::abook::getContactData [::ChatWindow::Name $win_name] cust_p4c_name] != ""} {
			set friendlyname [::abook::parseCustomNick [::abook::getContactData [::ChatWindow::Name $win_name] cust_p4c_name] [::abook::getPersonal MFN] [::abook::getPersonal login] "" [::abook::getpsmmedia]]
			set nick $friendlyname
			set p4c 1
		} elseif { [::config::getKey p4c_name] != ""} {
			set nick [::config::getKey p4c_name]
			set p4c 1
		} else {
			set nick [::abook::getPersonal MFN]
			set p4c 0
		}
		
		#Postevent when we send a message
		set evPar(nick) nick
		set evPar(msg) msg
		set evPar(chatid) chatid
		set evPar(win_name) win_name
		set evPar(fontfamily) fontfamily
		set evPar(fontstyle) fontstyle
		set evPar(fontcolor) fontcolor
		::plugins::PostEvent chat_msg_send evPar

		if {![string equal $msg ""]} {
			set supports_actions 1
			
			foreach user [::MSN::usersInChat $chatid] {
				set clientid [::abook::getContactData $user clientid]
				if { $clientid == "" } { set clientid 0 }
				set msnc [expr 0xF0000000]
				if { ($clientid & $msnc) < 6 } {
					set supports_actions 0
					break
				}
			}

			if {$supports_actions &&
			    ![::MSNMobile::IsMobile $chatid] &&
			    ![::OIM_GUI::IsOIM $chatid] &&
			    [string first "/action " $msg] == 0 } {

				set action "[string range $msg 8 end]"

				::amsn::WinWrite $chatid "\n" gray
				::amsn::WinWriteIcon $chatid greyline 3
				::amsn::WinWrite $chatid "\n" gray
				::amsn::WinWrite $chatid $action gray
				::amsn::WinWrite $chatid "\n" gray
				::amsn::WinWriteIcon $chatid greyline 3
				::amsn::WinWrite $chatid "\n" gray

				set first 0
				while { [expr {$first + 1480}] <= [string length $action] } {
					set msgchunk [string range $action $first [expr {$first + 1479}]]
					incr first 1480
					::MSN::SendAction $chatid $msgchunk
				}
				
				set msgchunk [string range $action $first end]
				if {$msgchunk != "" } {
					::MSN::SendAction $chatid $msgchunk
				}
				CharsTyped $chatid ""
				
			} elseif {$supports_actions &&
				  ![::MSNMobile::IsMobile $chatid] &&
				  ![::OIM_GUI::IsOIM $chatid] &&
				  [string first "/me " $msg] == 0 } {
				
				set action "$nick [string range $msg 4 end]"

				::amsn::WinWrite $chatid "\n" gray
				::amsn::WinWriteIcon $chatid greyline 3
				::amsn::WinWrite $chatid "\n" gray
				::amsn::WinWrite $chatid $action gray
				::amsn::WinWrite $chatid "\n" gray
				::amsn::WinWriteIcon $chatid greyline 3
				::amsn::WinWrite $chatid "\n" gray

				set first 0
				while { [expr {$first + 1480}] <= [string length $action] } {
					set msgchunk [string range $action $first [expr {$first + 1479}]]
					incr first 1480
					::MSN::SendAction $chatid $msgchunk
				}
				
				set msgchunk [string range $action $first end]
				if {$msgchunk != "" } {
					::MSN::SendAction $chatid $msgchunk
				}
				CharsTyped $chatid ""
			} else {
				set limit 1380
				incr limit -[string length $friendlyname]
				set first 0
				while { [expr {$first + $limit}] <= [string length $msg] } {
					set msgchunk [string range $msg $first [expr {$first + $limit - 1}]]
					if {[::MSNMobile::IsMobile $chatid] == 0 && [::OIM_GUI::IsOIM $chatid] == 0} {
						set ackid [after 60000 [list ::amsn::DeliveryFailed $chatid $msgchunk]]
					} else {
						set ackid 0
					}
					::MSN::messageTo $chatid "$msgchunk" $ackid $friendlyname
					incr first $limit
				}
				
				set msgchunk [string range $msg $first end]
				
				if {[::MSNMobile::IsMobile $chatid] == 0 && [::OIM_GUI::IsOIM $chatid] == 0} {
					set ackid [after 60000 [list ::amsn::DeliveryFailed $chatid $msgchunk]]
				} else {
					set ackid 0
				}
				
				set message [Message create %AUTO%]
				$message setBody $msg
				#TODO: where is the best place to put this code?
				
				set color "000000$fontcolor"
				set color "[string range $color end-1 end][string range $color end-3 end-2][string range $color end-5 end-4]"
				
				set style ""
				
				if { [string first "bold" $fontstyle] >= 0 } { set style "${style}B" }
				if { [string first "italic" $fontstyle] >= 0 } { set style "${style}I" }
				if { [string first "overstrike" $fontstyle] >= 0 } { set style "${style}S" }
				if { [string first "underline" $fontstyle] >= 0 } { set style "${style}U" }
				
				set format ""
				set format "{$format}FN=[urlencode $fontfamily]; "
				set format "{$format}EF=$style; "
				set format "{$format}CO=$color; "
				set format "{$format}CS=0; "
				set format "{$format}PF=22"
				$message setHeader [list X-MMS-IM-Format "$format"]
				
				#Draw our own message
				messageFrom $chatid [::abook::getPersonal login] $nick $message user $p4c
				
				#This object isn't used anymore: destroy it
				$message destroy
				::MSN::messageTo $chatid "$msgchunk" $ackid $friendlyname
				
				CharsTyped $chatid ""
				
				::plugins::PostEvent chat_msg_sent evPar
			}
		}
	}
	#///////////////////////////////////////////////////////////////////////////////



	#///////////////////////////////////////////////////////////////////////////////
	# ackMessage (ackid)
	# Called from the protocol layer when ACK for a message is received. It Cancels
	# the timer for time outing the message 'ackid'.
	proc ackMessage { ackid } {
		after cancel $ackid
	}
	#///////////////////////////////////////////////////////////////////////////////


	#///////////////////////////////////////////////////////////////////////////////
	# nackMessage (ackid)
	# Called from the protocol layer when NACK for a message is received. It just
	# writes the delivery error message without waiting for the message to timeout,
	# and cancels the timer.
	proc nackMessage { ackid } {
		if {![catch {after info $ackid} command]} {
			set command [lindex $command 0]
			after cancel $ackid
			eval $command
		}
	}
	#///////////////////////////////////////////////////////////////////////////////



	#///////////////////////////////////////////////////////////////////////////////
	# DeliveryFailed (chatid,msg)
	# Writes the delivery error message along with the timeouted 'msg' into the
	# window related to 'chatid'
	proc DeliveryFailed { chatid msg } {

		set win_name [::ChatWindow::For $chatid]

		if { [::ChatWindow::For $chatid] == 0} {
			chatUser $chatid
		}

		update idletasks
		
		SendMessageFIFO [list ::amsn::WinWriteFail $chatid $msg] "::amsn::messages_stack($chatid)" "::amsn::messages_flushing($chatid)"

	}
	proc WinWriteFail {chatid msg} {
		WinWrite $chatid "\n[timestamp] [trans deliverfail]:\n" red
		WinWrite $chatid "$msg" gray "" 1 [::config::getKey login]
		if {[::config::getKey keep_logs]} {
			::log::PutLog $chatid [trans deliverfail] $msg "" 1
		}

	}

	#///////////////////////////////////////////////////////////////////////////////


	#///////////////////////////////////////////////////////////////////////////////
	# PutMessage (chatid,user,msg,type,fontformat)
	# Writes a message into the window related to 'chatid'
	# - 'user' is the user login.
	# - 'msg' is the message itself to be displayed.
	# - 'type' can be red, gray... or any tag defined for the textbox when the window
	#   was created, or just "user" to use the fontformat parameter
	# - 'fontformat' is a list containing font style and color
	proc PutMessage { chatid user nick msg type fontformat {p4c ""}} {
		#Run it in mutual exclusion
		SendMessageFIFO [list ::amsn::PutMessageWrapped $chatid $user $nick $msg $type $fontformat $p4c] "::amsn::messages_stack($chatid)" "::amsn::messages_flushing($chatid)"
	}

	proc PutMessageWrapped { chatid user nick msg type fontformat {p4c 0 }} {
		variable lastchatwith
		
		set chatstyle [::config::getKey chatstyle]
		
		if { [::config::getKey showtimestamps] } {
			set tstamp [timestamp]
		} else {
			set tstamp ""
		}
		
		set lastchat 0
		if {[info exists lastchatwith($chatid)]} {
			if {$user eq $lastchatwith($chatid)} {
				if {$chatstyle eq "compact"} {
					set nick ""
					set lastchat 1
				}
			} else {
				array set lastchatwith [list $chatid $user]
			}
		} else {
			array set lastchatwith [list $chatid $user]
		}

		switch $chatstyle {
			msn {
				::config::setKey customchatstyle "\$tstamp [trans says \$nick]: \$newline"
			}
			irc {
				::config::setKey customchatstyle "\$tstamp <\$nick> "
			}
			compact {
				::config::setKey customchatstyle "[trans says \$nick]: \$newline \$tstamp"
			}
			- {
			}
		}

		#By default, quote backslashes and variables
		set customchat [string map {"\\" "\\\\" "\$" "\\\$" "\(" "\\\(" } [::config::getKey customchatstyle]]
		#Now, let's unquote the variables we want to replace
		set customchat [string map { "\\\$nick" "\${nick}" "\\\$tstamp" "\${tstamp}" "\\\$newline" "\n" } $customchat]

		if { [::abook::getContactData $user customcolor] != "" } {
			set color [string trim [::abook::getContactData $user customcolor] "#"]
		} else {
			set color 404040
		}

		if { $p4c == 1 } {
			if { $color == 404040 } { set color 000000 }
			set style [list "bold" "italic"]
		} else {
			set style {}
		}

		set font [lindex [::config::getGlobalKey basefont] 0]
		if { $font == "" } { set font "Helvetica"}

		set customfont [list $font $style $color]

		if {[::config::getKey truncatenicks]} {
			set oldnick $nick
			set nick ""
			set says [subst -nocommands $customchat]

			set measurefont [list $font [lindex [::config::getGlobalKey basefont] 1] $style]

			set win_name [::ChatWindow::For $chatid]
			set maxw [winfo width [::ChatWindow::GetOutText $win_name]]
			#status_log "Custom font is $customfont\n" red
			incr maxw [expr {-10-[font measure $measurefont -displayof $win_name "$says"]}]
			set nick [trunc $oldnick $win_name $maxw splainf]
		}

		#Return the custom nick, replacing backslashses and variables
		set customchat [subst -nocommands $customchat]

		upvar #0 [string map {: _} ${chatid} ]_smileys emotions
		if { [info exists emotions] } {
	 		set emoticons_for_this_chatid [array get emotions]
 			unset emotions 
 		}

		if {[::config::getKey colored_text_in_cw] == 1} {
			if {$lastchat} {
			} elseif {$p4c} {
				set original_nick [::smiley::parseMessageToList [list [ list "text" "$nick" ]]]
				set evpar(variable) original_nick
				set evpar(login) $user
				::plugins::PostEvent parse_contact evpar
			} elseif {[::abook::getPersonal login] ne $user} {
				set original_nick [::abook::getNick $user 1]
			} else {
				set original_nick [::abook::getVolatileData myself parsed_mfn]
			}

			if {$chatstyle eq "msn"} {
				set str [trans says __@__]
				set pos [string first __@__ $str]
				incr pos -1
				set part1 [list text [string range $str 0 $pos]]
				incr pos 6
				set part2 [list text [string range $str $pos end]]
				set parsing [list [list text "\n$tstamp "] $part1]
				set parsing [concat $parsing $original_nick]
				lappend parsing $part2 [list text ":\n"]
			} elseif {$chatstyle eq "irc"} {
				set parsing $original_nick
				set parsing [linsert $parsing 0 [list text "\n$tstamp <"]]
				lappend parsing [list text "> "]
			} elseif {$chatstyle eq "compact" } {
				if {!$lastchat} {
					set str [trans says __@__]
					set pos [string first __@__ $str]
					incr pos -1
					set part1 [list text "\n\n[string range $str 0 $pos]"]
					incr pos 6
					set part2 [list text [string range $str $pos end]]
					set parsing [list $part1]
					set parsing [concat $parsing $original_nick]
					lappend parsing $part2 [list text ":\n$tstamp "]
				} else {
					set parsing [list [list text "\n$tstamp "]]
				}
			} elseif {$chatstyle eq "custom"} {
				set customchatstyle__ [::config::getKey customchatstyle]
				
				set style [string map {"\\" "\\\\" "\$" "\\\$" "\(" "\\\(" " " " \\__fr33s@p4ce-_ "} $customchatstyle__]
				set parsing [list]
				lappend parsing [list text "\n"]
				
				foreach x $style {
					if {$x eq "\$nick"} {
						set parsing [concat $parsing $original_nick]
					} elseif { $x eq "\$tstamp"}  {
						lappend parsing [list text $tstamp]
					} elseif {$x eq "\$newline"} {
						lappend parsing [list text "\n"]
					} elseif {$x eq "\__fr33s@p4ce-_"} {
						lappend parsing [list text " "]
					} else {
						lappend parsing [list text "$x"]
					}
				}
			}
			WinWrite $chatid "" "says" $customfont 1 "" $parsing
			
	      } else {
		    WinWrite $chatid "\n$customchat" "says" $customfont
	      }

	 	if { [info exists emoticons_for_this_chatid] } {
 			array set emotions $emoticons_for_this_chatid
 			unset emoticons_for_this_chatid
 		}
		
		#Postevent for chat_msg_receive
		set evPar(user) user
		set evPar(msg) msg
		set evPar(chatid) chatid
		set evPar(fontformat) $fontformat
		set message $msg
		set evPar(message) message
		::plugins::PostEvent chat_msg_receive evPar

		if {![string equal $msg ""]} {
			if {[::config::getKey colored_text_in_cw] == 1} {
				set msg_parsing [::smiley::parseMessageToList [list [ list "text" "$message" ]]]
				set evpar(variable) msg_parsing
				set evpar(login) $user
				::plugins::PostEvent parse_contact evpar
				WinWrite $chatid "$message" $type $fontformat 1 $user $msg_parsing
			} else {
				WinWrite $chatid "$message" $type $fontformat 1 $user
			}
			
			if {[::config::getKey keep_logs]} {
				::log::PutLog $chatid $nick $msg $fontformat
			}
		}

		if { [info exists emotions] } {
			unset emotions
		}

		::plugins::PostEvent chat_msg_received evPar
	}
	#///////////////////////////////////////////////////////////////////////////////


	#///////////////////////////////////////////////////////////////////////////////
	# chatStatus (chatid,msg,[icon])
	# Called by the protocol layer to show some information about the chat, that
	# should be shown in the status bar. It parameter "ready" is different from "",
	# then it will only show it if the chat is not
	# ready, as most information is about connections/reconnections, and we don't
	# mind in case we have a "chat ready to chat".
	proc chatStatus {chatid msg {icon ""} {ready ""}} {
		if { $chatid == 0} {
			return 0
		} elseif { [::ChatWindow::For $chatid] == 0} {
			return 0
		} elseif { "$ready" != "" && [::MSN::chatReady $chatid] != 0 } {
			return 0
		} else {
			::ChatWindow::Status [::ChatWindow::For $chatid] $msg $icon
		}
	}
	#///////////////////////////////////////////////////////////////////////////////

	proc chatDisabled {chatid} {
		chatStatus $chatid ""
	}

	#///////////////////////////////////////////////////////////////////////////////
	# CharsTyped (chatid,msg)
	# Writes the message 'msg' (number of characters typed) in the window 'win_name' status bar.
	proc CharsTyped { chatid msg } {
		if { $chatid == 0} {
			return 0
		} elseif { [::ChatWindow::For $chatid] == 0} {
			return 0
		} else {
			set win_name [::ChatWindow::For $chatid]

			set msg [string map {"\n" " "} $msg]

			[::ChatWindow::GetStatusCharsTypedText ${win_name}] configure -state normal
			[::ChatWindow::GetStatusCharsTypedText ${win_name}] delete 0.0 end
			[::ChatWindow::GetStatusCharsTypedText ${win_name}] insert end $msg center
			[::ChatWindow::GetStatusCharsTypedText ${win_name}] configure -state disabled
		}
	}
	#///////////////////////////////////////////////////////////////////////////////


	#///////////////////////////////////////////////////////////////////////////////
	# chatUser (user, [oim])
	# Opens a chat for user 'user'. If a window for that user already exists, it will
	# use it and reconnect if necessary (will call to the protocol function chatUser),
	# and raise and focus that window. If the window doesn't exist it will open a new
	# one. 'user' is the mail address of the user to chat with.
	# oim is 1 when we're opening this CW in order to put an OIM
	#returns the name of the window
	proc chatUser { user {oim 0}} {
#		set lowuser [string tolower $user]
		set lowuser $user		
		set win_name [::ChatWindow::For $lowuser]
		set creating_window 0

		if { $win_name == 0 } {
			set creating_window 1
			if { [::ChatWindow::UseContainer] == 0 } {
				set win_name [::ChatWindow::Open]
				::ChatWindow::SetFor $lowuser $win_name
			} else {
				set container [::ChatWindow::GetContainerFor $user]
				set win_name [::ChatWindow::Open $container]
				::ChatWindow::SetFor $lowuser $win_name
			}

			set ::ChatWindow::first_message($win_name) 0
			
			status_log "win_name=$win_name" blue
			
			#TODO: This check shouldn't be there
			#Have a look at proc IsOIM (gui.tcl)
			if {[::OIM_GUI::IsOIM $user] == 0 && $oim == 0} {
				set chatid [::MSN::chatTo $lowuser]
			} else {
				#doing OIM
				set chatid $lowuser
			}

			# PostEvent 'new_conversation' to notify plugins that the window was created
			set evPar(chatid) $chatid
			set evPar(usr_name) $user
			::plugins::PostEvent new_conversation evPar

			if { [winfo exists [::ChatWindow::GetOutDisplayPicturesFrame $win_name].dps] } {
				::amsn::ShowOrHidePicture
				::amsn::ShowOrHideTopPicture
				::amsn::UpdatePictures $win_name
			} else {
				if { [::config::getKey showdisplaypic] && $user != ""} {
					::amsn::ChangePicture $win_name [::skin::getDisplayPicture $user] [trans showuserpic $user]
				} else {
					::amsn::ChangePicture $win_name [::skin::getDisplayPicture $user] [trans showuserpic $user] nopack
				}
			}

		}

		#TODO: This check shouldn't be there
		#Have a look at proc IsOIM (gui.tcl, ~2540)
		if {[::OIM_GUI::IsOIM $user] == 0 && $oim == 0 } {
			set chatid [::MSN::chatTo $lowuser]
		} else {
			#doing OIM
			set chatid $lowuser
		}

		if { [::ChatWindow::UseContainer] != 0 && $creating_window == 1} {
			::ChatWindow::NameTabButton $win_name $chatid
			set_balloon $::ChatWindow::win2tab($win_name) "--command--::ChatWindow::SetNickText $chatid"
		}

		if { "$chatid" != "${lowuser}" } {
			status_log "Error in ::amsn::chatUser, expected same chatid as user, but was different\n" red
			return 0
		}

		set top_win [winfo toplevel $win_name]

		if { [winfo exists .bossmode] } {
			set ::BossMode(${top_win}) "normal"
			wm state ${top_win} withdraw
		} else {
			if { [::config::getKey winmaximized 0] == 1 } {
				wm state ${top_win} zoomed
			} else {
				wm state ${top_win} normal
			}
		}

		wm deiconify ${top_win}
		update idletasks

		if { [OnMac] } { ::ChatWindow::MacPosition ${top_win} }

		::ChatWindow::TopUpdate $chatid

		#We have a window for that chatid, raise it
		raise ${top_win}

		set container [::ChatWindow::GetContainerFromWindow $win_name]
		if { $container != "" } { ::ChatWindow::SwitchToTab $container $win_name }

		# while receiving oims, with no tabbed chatting,
		# since many windows could open at the same time, and each of them were asking for the focus
		# here is an ugly workaround
		if {!$oim } {
			focus [::ChatWindow::GetInputText ${win_name}]
		}

		return $win_name
	}
	#///////////////////////////////////////////////////////////////////////////////

	proc  SelectUrl {textw urlname } {
		if { [focus] != "${textw}.inner" || [llength [$textw tag ranges sel]] == 0} {
			# If we were focusing on the text widget (user didn't explicitely just selected text with his mouse)
			# We need to free up the selection to avoid having multiple ranges selected
			if { [llength [$textw tag ranges sel]] > 0 } {
				eval [list $textw] tag remove sel [$textw tag ranges sel]
			}
			# We force the focus on the inner frame, this way the selection will appear, otherwise, we won't see anything..
			catch {focus -force ${textw}.inner}
			eval [list $textw] tag add sel [$textw tag ranges $urlname] 
		}
	}

	#///////////////////////////////////////////////////////////////////////////////
	# WinWrite (chatid,txt,tagid,[format])
	# Writes 'txt' into the window related to 'chatid'
	# It will use 'tagname' as style tag, unless 'tagname'=="user", where it will use
	# 'fontname', 'fontstyle' and 'fontcolor' as from fontformat, or 'tagname'=="says"
	# where it will use the same format as "user" but size 11.
	# The parameter "user" is used for smiley substitution.
	# If lst value is empty the txt value is considered and it will be converted in lst
	proc WinWrite {chatid txt tagname {fontformat ""} {flicker 1} {user ""} {lst ""}} {
		set win_name [::ChatWindow::For $chatid]

		if { $win_name == 0} {
			return 0
		}
		
		#Avoid problems if the windows was closed
		if {![winfo exists $win_name]} {
			return
		}
		
		
		set textw [::ChatWindow::GetOutText ${win_name}]
		set scrolling [::ChatWindow::getScrolling $textw]

		set fontname [lindex $fontformat 0]
		set fontstyle [lindex $fontformat 1]
		set fontcolor [lindex $fontformat 2]
		set fontbg ""

		$textw configure -font bplainf -foreground black

		#Store position for later smiley and URL replacement
		# use end-1c because text widgets always have \n at the end, and it's better than getting the
		# previous line as we did before (creates bug when we use a custom chat style that fits in one line).
		set text_start [$textw index end-1c]

		#Ugly hack for elided search, but at least it works!...
		if { [info tclversion] == 8.4 && $tagname == "user" } {
			if { [$textw get end-2c]!= "\n" } {
				set all_chars 0
				$textw search -elide -regexp -count all_chars .* end-1l end-1c
				#Remove line below and aMSN Plus causes bug report
				set visible_chars $all_chars
				$textw search -regexp -count visible_chars .* end-1l end-1c
				set elided_chars [expr {$all_chars - $visible_chars + 1}]
				set text_start $text_start-${elided_chars}c
			}
		}

		#Check if this is first line in the text, then ignore the \n
		#at the beginning of the line
		if { [$textw get 1.0 2.0] == "\n" } {
			if {$lst == ""} {
				if {[string index $txt 0] == "\n"} {
					set txt [string range $txt 1 end]
				}
			} else {
				set txtelement [lindex [lindex $lst 0] 1]
				set txtelement [string range $txtelement 1 end]
				set lst [lreplace $lst 0 0 [list text "$txtelement"]]
			}
		}

		set fontcolor_original $fontcolor
		if {$lst == ""} {
			set lst [list ]
			lappend lst [list text "$txt"]
			set check_always_smiley 1
		} else {
			set check_always_smiley 0
		}
		
		set evPar(tagname) tagname
		set evPar(winname) {win_name}
		
		set textw [::ChatWindow::GetOutText ${win_name}]
 
		foreach unit $lst {
			switch [lindex $unit 0] {
				"text"   { set txt "[lindex $unit 1]"}
				"smiley" { set txt "[lindex $unit 2]"}
				"colour" { 
					  if {[lindex $unit 1] ne "reset"} {
						set fontcolor [string range [lindex $unit 1] 1 end]
					  } else {
						set fontcolor $fontcolor_original
					  }
					  continue
				}
				"bg" { 
					  if {[lindex $unit 1] ne "reset"} {
						set fontbg [lindex $unit 1]
					  } else {
						set fontbg ""
					  }
					  continue
				}
				"newline" {
					set txt "\n"
				}
				default { continue }
			}

		#By default tagid=tagname unless we generate a new one
		set tagid $tagname

		if { $tagid == "user" || $tagid == "yours" || $tagid == "says" } {

			if { $tagid == "says" && [::config::getKey strictfonts] == 0 } {
				set size [lindex [::config::getGlobalKey basefont] 1]
			} else {
				set size [expr {[lindex [::config::getGlobalKey basefont] 1]+[::config::getKey textsize]}]
			}

			# We'd rather avoid letting the system use 'fixed' whenever the font is not available, because it's THE ugliest...
			# 7:44 <@azbridge> <Cameron> So, in the short term, you're rather stuck with [font families].  Maybe you can help make a better answer for a future release of Tk, though.
			if { $tagid == "user" } {
				set fontname [urldecode $fontname]
				set font "bplainf"
				foreach listed_font [string trim [split $fontname ","]] {
					if { [info exists ::allfonts([string tolower $listed_font])] } {
						#status_log "font $listed_font found!"
						set font "\"$listed_font\" $size $fontstyle"
						break
					}
				}
			} else {
				set font "\"$fontname\" $size $fontstyle"
			}
			set tagid [::md5::md5 "$font$fontcolor"]

			if { ([string length $fontname] < 3 )
					|| ([catch {$textw tag configure $tagid -foreground #$fontcolor -background $fontbg -font $font} res])} {
				status_log "Font $font or color $fontcolor wrong. Using default\n" red
				$textw tag configure $tagid -foreground black -font bplainf
			}
		}

		set evPar(msg) txt
		::plugins::PostEvent WinWrite evPar
		
		$textw roinsert end "$txt" $tagid
		
		if {$tagname ne "says"} {
		#TODO: Make an url_subst procedure, and improve this using regular expressions
		variable urlcount
		variable urlstarts

		set endpos $text_start
		foreach url $urlstarts {
			while { $endpos != [$textw index end] && [set pos [$textw search -forward -exact -nocase \
				$url $endpos end]] != "" } {

				set urltext [$textw get $pos end]

				set final 0
				set caracter [string range $urltext $final $final]
				while { $caracter != " " && $caracter != "\n" } {
					set final [expr {$final+1}]
					set caracter [string range $urltext $final $final]
				}

				set urltext [string range $urltext 0 [expr {$final-1}]]

				set posyx [split $pos "."]
				set endpos "[lindex $posyx 0].[expr {[lindex $posyx 1] + $final}]"

				set urlcount "[expr {$urlcount+1}]"
				set urlname "url_$urlcount"

				$textw tag configure $urlname \
				-foreground #000080 -font splainf -underline true
				$textw tag bind $urlname <Enter> \
				"$textw tag conf $urlname -underline false;\
				$textw conf -cursor hand2"
				$textw tag bind $urlname <Leave> \
				"$textw tag conf $urlname -underline true;\
				$textw conf -cursor xterm"
				$textw tag bind $urlname <<Button1>> \
				"$textw conf -cursor watch; launch_browser [string map {% %%} [list $urltext]]"
				$textw tag bind $urlname <<Button3>> [list ::amsn::SelectUrl $textw $urlname]

				$textw rodelete $pos $endpos
				$textw roinsert $pos "$urltext" $urlname

				#Don't replace smileys in URLs
				$textw tag add dont_replace_smileys ${urlname}.first ${urlname}.last
			}
		}
		}
		
		#Avoid problems if the windows was closed in the middle...
		if {![winfo exists $win_name]} { return }

		if {[::config::getKey chatsmileys]} {
			if {($tagname ne "says") && ([::config::getKey customsmileys] && [::abook::getContactData $user showcustomsmileys] != 0) } {
				custom_smile_subst $chatid $textw $text_start end
			}
			
			#we need to call those procs only if the "txt" value is not empty (it means that we are writing in chatwindow in the old method, and so we need to parse all the "txt" value) or if the "unit 0" value is smiley (new method).
			if {$check_always_smiley || $user == [string tolower [::config::getKey login]] ||([lindex $unit 0] eq "smiley") } {
				#Replace smileys... if you're sending custom ones, replace them too (last parameter)
				if { $user == [string tolower [::config::getKey login]] } {
					::smiley::substSmileys $textw $text_start end 0 1
					#::smiley::substYourSmileys [::ChatWindow::GetOutText ${win_name}] $text_start end 0
				} else {
					::smiley::substSmileys $textw $text_start end 0 0
				}
			}
			
		}

		} ;#end of foreach

		if { $scrolling } { ::ChatWindow::Scroll $textw }
		
		if { $flicker } {
			::ChatWindow::Flicker $chatid
		}

		after cancel [list set ::ChatWindow::recent_message($win_name) 0]
		set ::ChatWindow::recent_message(${win_name}) 1
		after 2000 [list set ::ChatWindow::recent_message($win_name) 0]

		::plugins::PostEvent WinWritten evPar
	}
	#///////////////////////////////////////////////////////////////////////////////


	proc WinWriteIcon { chatid imagename {padx 0} {pady 0}} {
		set win_name [::ChatWindow::For $chatid]

		if { [::ChatWindow::For $chatid] == 0} {
			return 0
		}

		set scrolling [::ChatWindow::getScrolling [::ChatWindow::GetOutText ${win_name}]]

		[::ChatWindow::GetOutText ${win_name}] image create end -image [::skin::loadPixmap $imagename] -pady $pady -padx $pady

		if { $scrolling } { ::ChatWindow::Scroll [::ChatWindow::GetOutText ${win_name}] }
	}

	proc WinWriteClickable { chatid txt command {tagid ""}} {
		set win_name [::ChatWindow::For $chatid]

		if { [::ChatWindow::For $chatid] == 0} {
			return 0
		}

		set scrolling [::ChatWindow::getScrolling [::ChatWindow::GetOutText ${win_name}]]


		if { $tagid == "" } {
			set tagid [getUniqueValue]
		}

		[::ChatWindow::GetOutText ${win_name}] tag configure $tagid \
		-foreground #000080 -font bboldf -underline false
		[::ChatWindow::GetOutText ${win_name}] tag bind $tagid <Enter> \
		"[::ChatWindow::GetOutText ${win_name}] tag conf $tagid -underline true;\
		[::ChatWindow::GetOutText ${win_name}] conf -cursor hand2"
		[::ChatWindow::GetOutText ${win_name}] tag bind $tagid <Leave> \
		"[::ChatWindow::GetOutText ${win_name}] tag conf $tagid -underline false;\
		[::ChatWindow::GetOutText ${win_name}] conf -cursor xterm"
		[::ChatWindow::GetOutText ${win_name}] tag bind $tagid <<Button1>> "$command"
		[::ChatWindow::GetOutText ${win_name}] roinsert end "$txt" $tagid

		if { $scrolling } { ::ChatWindow::Scroll [::ChatWindow::GetOutText ${win_name}] }
	}

	if { $initialize_amsn == 1 } {
		variable NotifID 0
		variable NotifPos [list]
	}

	proc closeAmsnMac {} {
		set answer [::amsn::messageBox [trans exitamsn] yesno question [trans title]]
		if { $answer == "yes"} { exit }
	}

	###
	### $closingdocks: 0 / unexistant = ask
	###                1 = dock
	###                2 = close
	proc closeOrDock { closingdocks } {
		global rememberdock
		set rememberdock 0

		if {$closingdocks == 1} {
			closeOrDockDock
		} elseif { $closingdocks == 2} {
			exit
		} else {
			set w .closeordock

			if { [winfo exists $w] } {
				raise $w
				return
			}

			toplevel $w -bg [::skin::getKey extrastdwindowcolor]
			wm title $w "[trans title]"
			wm group $w .
			wm resizable $w 0 0
			
			#Create the 2 frames
			frame $w.top
			frame $w.buttons
			
			#Create the picture of warning (at left)
			label $w.top.bitmap -image [::skin::loadPixmap warning]
			pack $w.top.bitmap -side left -pady 0 -padx [list 0 12 ]
			
			label $w.top.question -text "[trans closeordock]" -wraplength 400 -justify left
			pack $w.top.question -pady 0 -padx 0 -side top
			
			checkbutton $w.top.remember -text [trans remembersetting] -variable rememberdock -anchor w
			pack $w.top.remember -pady 5 -padx 10 -side bottom -fill x
			
			#Create the buttons
			button $w.buttons.quit -text "[trans quit]" -command "::amsn::closeOrDockClose"
			button $w.buttons.dock -text "[trans minimize]" -command "::amsn::closeOrDockDock"
			button $w.buttons.cancel -text "[trans cancel]" -command "destroy $w"
			pack $w.buttons.quit -pady 0 -padx 0 -side right
			pack $w.buttons.cancel -pady 0 -padx [list 0 6 ] -side right
			pack $w.buttons.dock -pady 0 -padx 6 -side right
			
			#Pack frames
			pack $w.top -pady 12 -padx 12 -side top
			pack $w.buttons -pady 12 -padx 12 -fill x
			bind $w <<Escape>> "destroy $w"

			moveinscreen $w 30
		}
	}
	
	proc closeOrDockDock {} {
		global systemtray_exist statusicon ishidden rememberdock

		if {$rememberdock} {
			::config::setKey closingdocks 1
		}
		wm iconify .
		if { $systemtray_exist == 1 && $statusicon != 0 } {
			status_log "Hiding\n" white
			wm state . withdrawn
			set ishidden 1
		}	
		destroy .closeordock
		unset rememberdock
	}

	proc closeOrDockClose {} {
		global rememberdock

		if {$rememberdock} {
			::config::setKey closingdocks 2
		}

		destroy .closeordock
		unset rememberdock
		exit
	}
	


	#Adds a message to the notify, that executes "command" when clicked, and
	#plays "sound"
	proc notifyAdd { msg command {sound ""} {type other} {user ""} {lst 0}} {
		#no notifications in bossmode or if disabled
		if { [winfo exists .bossmode] || [::config::getKey shownotify] == 0} {
			return
		}

		#if we gota sound, play it
		if { $sound != ""} {
			play_sound ${sound}.wav
		}

		global automessage
		#Maybe we want to block the notification windows but not the sounds!
		if { [info exists automessage] && $automessage != -1 && [lindex $automessage 7] == 1} { return }
		
		# Check if we only want to play the sound notification
		if { [::config::getKey notifyonlysound] == 0 } {
			#have a unique name
			variable NotifID
			#the position, always incremented with height
			variable NotifPos

			#New name for the window
			set w .notif$NotifID
			incr NotifID

			#the window will be stretched by the canvas anyways
			toplevel $w -width 1 -height 1 -borderwidth 0
			wm group $w .
			#no wm borders
			wm state $w withdrawn

			#To put the notify window in front of all
			#Some verions of tk don't support this
			catch { wm attributes $w -topmost 1 }
			

			set xpos [::config::getKey notifyXoffset]
			set ypos [::config::getKey notifyYoffset]

			if { $xpos < 0 } { set xpos 0 }
			if { $ypos < 0 } { set ypos 0 }

			set height [::skin::getKey notifheight]

			#Search for a free notify window position
			while { [lsearch -exact $NotifPos $ypos] >=0 } {
				incr ypos $height
			}
			lappend NotifPos $ypos

			canvas $w.c -bg #EEEEFF -width [::skin::getKey notifwidth] -height [::skin::getKey notifheight] \
				-relief ridge -borderwidth 0 -highlightthickness 0
			pack $w.c

			#set the background picture
			switch $type {
				online { $w.c create image 0 0 -anchor nw -image [::skin::loadPixmap notifyonline] -tag bg }
				offline { $w.c create image 0 0 -anchor nw -image [::skin::loadPixmap notifyoffline] -tag bg }
				state { $w.c create image 0 0 -anchor nw -image [::skin::loadPixmap notifystate] -tag bg }
				plugins { $w.c create image 0 0 -anchor nw -image [::skin::loadPixmap notifyplugins] -tag bg }
				message { $w.c create image 0 0 -anchor nw -image [::skin::loadPixmap notifymsg] -tag bg }
				email { $w.c create image 0 0 -anchor nw -image [::skin::loadPixmap notifyemail] -tag bg }
				default { $w.c create image 0 0 -anchor nw -image [::skin::loadPixmap notifyonline] -tag bg }
			}

			#----------convert msg in a list--------------;#
			if {!$lst} {                                  ;#
				set msg [string map { "\n" " "} $msg] ;#
				set msg [list $msg]                   ;#
				set msg [list "text $msg"]            ;#
			}					      ;#
			#---------------------------------------------;#

			#If it's a notification about a user (user var given) and there is an image (the creation results 1) and we have the config set to show the image, show the display-picture
			if {$user != "" && [getpicturefornotification $user] && [::config::getKey showpicnotify]} {
				#Put the image on the canvas
				$w.c create image [::skin::getKey x_notifydp] [::skin::getKey y_notifydp] -anchor nw\
					-image displaypicture_not_$user -tag bg

				set x [::skin::getKey x_notifytext]
				set y [::skin::getKey y_notifytext]
				set maxw [::skin::getKey width_notifytext]

			#else, just show the text, using all the space
			} else {
	#			set notify_id [$w.c create text [expr {[::skin::getKey notifwidth]/2}] [expr {[::skin::getKey notifheight]/2}] \
	#				-font [::skin::getKey notify_font] -justify left\
	#				-width [expr {[::skin::getKey notifwidth]-20}] -anchor center\
	#				-text "$msg" -tag bg -fill [::skin::getKey notifyfg]]

#				set x [::skin::getKey notifwidth]
#				set x [expr {[::skin::getKey notifwidth]/2}]
#				set y [expr {[::skin::getKey notifheight]/2}]
				set x [::skin::getKey x_notifydp]
				set y [::skin::getKey y_notifytext]
				set maxw [expr {[::skin::getKey notifwidth]-20}]
			}

			set default_x $x
			set default_y $y
			set default_maxw $maxw
			set default_colour [::skin::getKey notifyfg]
			set default_font [::skin::getKey notify_font]

#			set lines 0 ;# not used
			set colour $default_colour
			set font_attr [font configure $default_font]
			set incr_y [font metrics $font_attr -displayof $w.c -linespace]
			set default_incr_y $incr_y
			set bg_x ""
			set bg_cl ""

			foreach unit $msg {
				switch [lindex $unit 0] {
					"text" {
						set textpart [lindex $unit 1]
						set textwidth [font measure $font_attr $textpart]

						if {$textwidth > $maxw} {
							set l [string length $textpart]
							for {set i 0} {$i < $l} {incr i} {
								if { [ font measure $font_attr -displayof $w.c "[string range $textpart 0 $i]" ] > $maxw} {
									set txt "[string range $textpart 0 [expr {$i-1}]]"
									$w.c create text $x $y -text $txt \
									-anchor nw -fill $colour -font $font_attr -tags {bg text2} -justify left

									if {$bg_x ne ""} {
										incr x [font measure $font_attr -displayof $w.c $txt]
										$w.c create rect $bg_x $y $x [expr {$y + $incr_y}] -fill $bg_cl -outline "" -tag bgtext
			
										foreach tag [list "text2" "img"] {
											$w.c lower bgtext $tag
										}
			
										set bg_x $default_x
									}

									set textpart [string range $textpart $i end]
									if {$textpart ne " "} {
										set i 0
										set l [string length $textpart]
										set textwidth [font measure $font_attr $textpart]
									} else {
										set l 0
										set textwidth 0
									}
									set x $default_x
									set y [expr $y + $incr_y]
									set maxw $default_maxw
									set incr_y $default_incr_y
								}
							}
						}
						$w.c create text $x $y -text $textpart \
						-anchor nw -fill $colour -font $font_attr -tags {bg text2} -justify left
						incr x $textwidth
						set maxw [expr {$maxw - $textwidth}]
					}
					"smiley" {
						set img [lindex $unit 1]
						set width [image width $img]
 
						if {[image height $img] > $incr_y} {
							set incr_y [image height $img]
						}

						if {$width > $maxw} {
 							set x $default_x
 							set y [expr $y + $incr_y]
 							set maxw $default_maxw
 						}

						$w.c create image $x $y -image $img -anchor nw -state normal -tags {bg img}
						set maxw [expr {$maxw - $width}]
						incr x $width
					}
					"colour" {
						if {[lindex $unit 1] eq "reset"} {
							set colour $default_colour
						} else {
							set colour [lindex $unit 1]
						}
					}
					"bg" {
						if {$bg_x eq ""} {
							if {[lindex $unit 1] ne "reset"} {
								set bg_x $x
								set bg_cl [lindex $unit 1]
							}
						} else {
							$w.c create rect $bg_x $y $x [expr {$y + $incr_y}] -fill $bg_cl -outline "" -tag bgtext

							foreach tag [list "text2" "img"] {
								$w.c lower bgtext $tag
							}

							set bg_x $x
							set bg_cl [lindex $unit 1]
							if {$bg_cl eq "reset"} {
								set bg_x ""
							}
						}
					}
					"font" {
						if { [llength [lindex $unit 1]] == 1 } {
							if { [lindex $unit 1] == "reset" } {
								set font_attr [font configure $default_font]
							} else {
								set font_attr [font configure [lindex $unit 1]]
							}
							array set current_format $font_attr
						} else {
							array set current_format $font_attr
							array set modifications [lindex $unit 1]
							foreach key [array names modifications] {
								set current_format($key) [set modifications($key)]
								if { [set current_format($key)] == "reset" } {
									set current_format($key) \
										[font configure $default_font $key]
								}
							}
							set font_attr [array get current_format]
						}
					}
					"newline" {
						if {$x != $default_x} {
							set x $default_x
							set y [expr $y + $incr_y]
							set maxw $default_maxw
						}
						set incr_y $default_incr_y
					}
				}
			}

			#add the close button
			$w.c create image [::skin::getKey x_notifyclose] [::skin::getKey y_notifyclose] -anchor nw -image [::skin::loadPixmap notifclose] -tag close

			::amsn::leaveNotify $w $ypos $command

			wm overrideredirect $w 1

			#now show it
			wm state $w normal

			if { [OnMac] } {
				#Raise $w to correct a bug in "wm geometry" in AquaTK (Mac OS X)
				lower $w
			}

			#Disable Grownotify for Mac OS X Aqua/tk users
			if {![::config::getKey animatenotify] || [OnMac] } {
				wm geometry $w -$xpos-$ypos
			} else {
				wm geometry $w -$xpos-[expr {$ypos-100}]
				after 50 "::amsn::growNotify $w $xpos [expr {$ypos-100}] $ypos"
			}
		}
	}

	proc enterNotify { w after_id } {
		$w.c configure -cursor hand2
		after cancel $after_id
	}

	proc leaveNotify { w ypos command } {
		$w.c configure -cursor left_ptr
		set after_id [after [::config::getKey notifytimeout] [list ::amsn::KillNotify $w $ypos]]

		$w.c bind bg <Enter> [list ::amsn::enterNotify $w $after_id]
		$w.c bind bg <Leave> [list ::amsn::leaveNotify $w $ypos $command]
		$w.c bind bg <ButtonRelease-1> "after cancel $after_id; [list ::amsn::KillNotify $w $ypos $command]"
		$w.c bind bg <ButtonRelease-3> "after cancel $after_id; [list ::amsn::KillNotify $w $ypos]"
		$w.c bind close <Enter> [list ::amsn::enterNotify $w $after_id]
		$w.c bind close <Leave> [list ::amsn::leaveNotify $w $ypos $command]
		$w.c bind close <ButtonRelease-1> "after cancel $after_id; ::amsn::KillNotify $w $ypos"	
	}

	proc growNotify { w xpos currenty finaly } {
		if { [winfo exists $w] == 0 } { return 0}

		if { $currenty>$finaly} {
			wm geometry $w -$xpos-$finaly
			raise $w
			return 0
		}
		wm geometry $w -$xpos-$currenty
		after 75 "::amsn::growNotify $w $xpos [expr {$currenty+15}] $finaly"
	}

	proc KillNotify { w ypos {command ""}} {
		variable NotifPos

		
		if { $command != "" } {
			catch {eval $command}
			set timer 500
		} else {
			set timer 0
		}

		# We need to wait before making this disappear because we need the window to be created
		# BEFORE the notify disappears, otherwise in windows, the focus is lost from amsn and returns to the
		# previous application who had the focus, so we don't get the chat window focus.
		after $timer [list destroy $w]

		#remove this position from the list
		set lpos [lsearch -exact $NotifPos $ypos]
		set NotifPos [lreplace $NotifPos $lpos $lpos]
	}
}

proc create_places_menu { wmenu } {
	# Destroy if already existing
	if {[winfo exists $wmenu]} {
		destroy $wmenu
	}

  	# User status menu
	menu $wmenu -tearoff 0 -type normal

	$wmenu add command -label [trans signouthere [::config::getKey epname aMSN]] -command "::MSN::logout"
	foreach ep [::abook::getEndPoints] {
		if {![string equal -nocase $ep [::config::getGlobalKey machineguid]] } {
			$wmenu add command -label [trans signoutep [::abook::getEndPointName $ep]] -command [list ::MSN::logoutEP $ep]
		}
	}
	$wmenu add command -label [trans signouteverywhere] -command "::MSN::logoutGtfo"
	$wmenu add separator	
	$wmenu add command -label [trans renameep [::config::getKey epname aMSN]] -command "Preferences"
	
}

proc create_states_menu { wmenu } {
	# Destroy if already existing
	if {[winfo exists $wmenu]} {
		destroy $wmenu
	}

  	# User status menu
	menu $wmenu -tearoff 0 -type normal

	$wmenu add command -label [trans online] -command "ChCustomState NLN"
	$wmenu add command -label [trans noactivity] -command "ChCustomState IDL"
	$wmenu add command -label [trans busy] -command "ChCustomState BSY"
	$wmenu add command -label [trans rightback] -command "ChCustomState BRB"
	$wmenu add command -label [trans away] -command "ChCustomState AWY"
	$wmenu add command -label [trans onphone] -command "ChCustomState PHN"
	$wmenu add command -label [trans gonelunch] -command "ChCustomState LUN"
	$wmenu add command -label [trans appearoff] -command "ChCustomState HDN"
	$wmenu add command -label [trans logout] -command "::MSN::logout"

	set modifier [GetPlatformModifier]
	bind all <$modifier-Key-0> {catch {ChCustomState HDN}}
	bind all <$modifier-Key-1> {catch {ChCustomState NLN}}
	bind all <$modifier-Key-2> {catch {ChCustomState IDL}}
	bind all <$modifier-Key-3> {catch {ChCustomState BSY}}
	bind all <$modifier-Key-4> {catch {ChCustomState BRB}}
	bind all <$modifier-Key-5> {catch {ChCustomState AWY}}
	bind all <$modifier-Key-6> {catch {ChCustomState PHN}}
	bind all <$modifier-Key-7> {catch {ChCustomState LUN}}
	bind all <$modifier-Key-8> {catch {ChCustomState HDN}}
	
	# Add the personal states to this menu
	CreateStatesMenu $wmenu states_only
}
proc create_other_menus {umenu imenu} {
	# Destroy if already existing
	if {[winfo exists $umenu]} { destroy $umenu }
	if {[winfo exists $imenu]} { destroy $imenu }

	# User menu
	menu $umenu -tearoff 0 -type normal
	menu $umenu.move_group_menu -tearoff 0 -type normal
	menu $umenu.copy_group_menu -tearoff 0 -type normal
	menu $imenu -tearoff 0 -type normal

}

proc create_apple_menu { wmenu } {
	set appmenu $wmenu.apple
	$wmenu add cascade -label "aMSN" -menu $appmenu
	menu $appmenu -tearoff 0 -type normal
	$appmenu add command -label "[trans about] aMSN" \
		-command ::amsn::aboutWindow
	$appmenu add separator
	$appmenu add command -label "[trans skinselector]" \
	  -command ::skinsGUI::SelectSkin -accelerator "Command-Shift-S"
	$appmenu add command -label "[trans pluginselector]" \
	  -command ::plugins::PluginGui -accelerator "Command-Shift-P"
	# Since Tk 8.4.14 the Preferences AppleMenu item is hardcoded by TkAqua.
	# When the menu item is pressed, it calls ::tk::mac::ShowPreferences.
	if { [version_vcompare [info patchlevel] 8.4.14] < 0 } {
		$appmenu add separator
		$appmenu add command -label "[trans preferences]..." \
			-command Preferences -accelerator "Command-,"
	}
	$appmenu add separator	
}

proc create_main_menu {wmenu} {
	global password 

	# Destroy if already existing
	if {[winfo exists .main_menu]} { destroy $wmenu }

	#Main menu
	if {[package provide pixmapmenu] != "" && \
		[info commands pixmapmenu_isEnabled] != "" && [pixmapmenu_isEnabled]} {
		pack [menubar .main_menu] -before .main -fill x -side top
	} else {
		menu .main_menu -tearoff 0 -type menubar -borderwidth 0 -activeborderwidth -0
	}

	######################################################
	# Add the menus in the menubar                       #
	######################################################

	#For apple, the first menu is the "App menu"
	if { [OnMac] } { create_apple_menu .main_menu }
	
	.main_menu add cascade -label "[trans account]" -menu .main_menu.account
	.main_menu add cascade -label "[trans view]" -menu .main_menu.view
	.main_menu add cascade -label "[trans actions]" -menu .main_menu.actions
	.main_menu add cascade -label "[trans contacts]" -menu .main_menu.contacts
	.main_menu add cascade -label "[trans help]" -menu .main_menu.helpmenu
		

	###########################
	#Account menu
	###########################
	set accnt .main_menu.account
	
	#Temporary fix for (probably Mac-only) bug where states menu refuses to appear
	if { [OnMac] } {
		#I think this might create another bug, that's why I keep it Mac-only for now
		#This way things stay good on other platforms, and on Mac we get a smaller bug.
		#(menu does not update if new custom status is added, instead of not posting at all)
		#TODO: Of course, this needs a real fix sometime.
		menu $accnt -tearoff 0 -type normal
		create_states_menu $accnt.my_menu
	} else {
		menu $accnt -tearoff 0 -type normal -postcommand "create_states_menu $accnt.my_menu"
	}
	
	#Note: One might think we should always have both entries (login and login_as)
	#in the menu with "login" (with profile) greyed out if it's not available.
	#Though, this makes us have 2 entries that are allmost the same, definitely
	#in the translated string. As this menu doesn't swap all the time and only
	#does so when once this option is set to have a profile, I don't think there's
	#a problem of having this entry not be there when there is no profile.
	#It's like, when you load a plugin for a new action it can add an item but that
	#item wasn't there before and greyed out.
	
	#Log in with default profile
	if { [string length [::config::getKey login]] > 0 && $password != ""} {
		#$accnt add command -label "[trans login] ([::config::getKey login])" -command ::MSN::connect -state normal
	}
	#log in with another profile
	#$accnt add command -label "[trans loginas]..." -command cmsn_draw_login -state normal
	#log out
	$accnt add command -label "[trans logout]" -command [list preLogout ::MSN::logout] -state disabled
	#-------------------
	$accnt add separator
	#change status submenu
	$accnt add cascade -label "[trans changestatus]" -menu $accnt.my_menu -state disabled
	#change nick
	$accnt add command -label "[trans changenick]..." -command [list cmsn_change_name] -state disabled
	#change psm
	$accnt add command -label "[trans changepsm]..." -command [list cmsn_change_name] -state disabled
	#change dp
	$accnt add command -label "[trans changedisplaypic]..." -command [list dpBrowser] -state disabled
	#-------------------
	$accnt add separator
	#go to inbox
	$accnt add command -label "[trans gotoinbox]" -command [list ::hotmail::hotmail_login] -state disabled
	#go to my profile
	$accnt add command -label "[trans editmyprofile]" -command [list ::hotmail::hotmail_profile] -state disabled
	#-------------------
	$accnt add separator
	#edit global alarm settings
	$accnt add command -label "[trans cfgalarmall]..." -command [list ::alarms::configDialog all] -state disabled
	#-------------------
	$accnt add separator
	#received files
	$accnt add command -label "[trans openreceived]" -command [list launch_filemanager [::config::getKey receiveddir]]
	#events history
	$accnt add  command -label "[trans eventhistory]" -command [list ::log::OpenLogWin eventlog] -state disabled
	
	#On mac these are in the app menu instead of here, except for minimize, which doesn't exist on mac.
	if {![OnMac]} {
		#-------------------
		$accnt add separator
#		$accnt add checkbutton -label "[trans sound]" -onvalue 1 -offvalue 0 -variable [::config::getVar sound]u
		$accnt add command -label "[trans skinselector]" -command [list ::skinsGUI::SelectSkin]
		$accnt add command -label "[trans pluginselector]" -command [list ::plugins::PluginGui]
		$accnt add command -label "[trans preferences]" -command Preferences -accelerator "Ctrl-P"
		#-------------------
		$accnt add separator
		#Minimize to tray
		$accnt add command -label "[trans minimize]" -command [list ::amsn::closeOrDock 1]
		#Terminate aMSN
		$accnt add command -label "[trans quit]" -command [list ::amsn::closeOrDock 2] -accelerator "Ctrl-Q"
	}

	###########################
	#View menu
	###########################
	set view .main_menu.view
	menu $view -tearoff 0 -type normal

	#Add the "view by" radio buttons
	$view add cascade -label "[trans sortcontactsby]" -menu $view.sortcontacts -state disabled

	menu $view.sortcontacts -tearoff 0 -type normal

	$view.sortcontacts add radio -label "[trans sortcontactstatus]" -value 0 \
	    -variable [::config::getVar orderbygroup] -command [list ::Event::fireEvent changedSorting gui]
	$view.sortcontacts add radio -label "[trans sortcontactgroup]" -value 1 \
	    -variable [::config::getVar orderbygroup] -command [list ::Event::fireEvent changedSorting gui]
	$view.sortcontacts add radio -label "[trans sortcontacthybrid]" -value 2 \
	    -variable [::config::getVar orderbygroup] -command [list ::Event::fireEvent changedSorting gui]
	$view.sortcontacts add separator
	$view.sortcontacts add radio -label "[trans sortcontactsasc]" -value 1 \
	    -variable [::config::getVar orderusersincreasing] -command [list ::Event::fireEvent changedSorting gui]
	$view.sortcontacts add radio -label "[trans sortcontactsdesc]" -value 0 \
	    -variable [::config::getVar orderusersincreasing] -command [list ::Event::fireEvent changedSorting gui]
	$view.sortcontacts add separator
	$view.sortcontacts add checkbutton -label "[trans sortcontactsbylogsize]"  -onvalue 1 -offvalue 0 \
	    -variable [::config::getVar orderusersbylogsize] -command [list ::Event::fireEvent changedSorting gui]
	$view.sortcontacts add separator
	$view.sortcontacts add checkbutton -label "[trans groupcontactsbystatus]" -onvalue 1 -offvalue 0 \
	    -variable [::config::getVar orderusersbystatus] -command [list ::Event::fireEvent changedSorting gui]
	$view.sortcontacts add checkbutton -label "[trans groupnonim]" -onvalue 1 -offvalue 0 \
	    -variable [::config::getVar groupnonim] -command [list ::Event::fireEvent changedSorting gui]
	#-------------------
	$view add separator	
	$view add radio -label "[trans showcontactnick]" -value 0 \
	    -variable [::config::getVar emailsincontactlist] -command "::Event::fireEvent changedNickDisplay gui; ::Event::fireEvent changedSorting gui" -state disabled
	$view add radio -label "[trans showcontactemail]" -value 1 \
		-variable [::config::getVar emailsincontactlist] -command "::Event::fireEvent changedNickDisplay gui; ::Event::fireEvent changedSorting gui" -state disabled
	#-------------------
	$view add separator
	$view add command -label "[trans changeglobnick]..." -command [list ::abookGui::SetGlobalNick]
	#-------------------
	$view add separator
	$view add radio -label "[trans sortgroupsasc]" -value 1 \
		-variable [::config::getVar ordergroupsbynormal] -command [list ::Event::fireEvent changedSorting gui] -state disabled
	$view add radio -label "[trans sortgroupsdesc]" -value 0 \
		-variable [::config::getVar ordergroupsbynormal] -command [list ::Event::fireEvent changedSorting gui] -state disabled
	#-------------------
	$view add separator
	$view add checkbutton -label "[trans showdetailedview]" -onvalue 1 -offvalue 0 -state disabled \
	    -variable [::config::getVar show_detailed_view] -command [list ::guiContactList::DetailedView]
	#-------------------
	$view add separator
	$view add checkbutton -label "[trans shownonim]" -onvalue 1 -offvalue 0 -state disabled \
	    -variable [::config::getVar shownonim] -command [list ::Event::fireEvent changedSorting gui]
	$view add checkbutton -label "[trans showspaces]" -onvalue 1 -offvalue 0  -state disabled \
	    -variable [::config::getVar showspaces] -command [list ::Event::fireEvent changedSorting gui]
	$view add checkbutton -label "[trans showofflinegroup]" -onvalue 1 -offvalue 0  -state disabled \
	    -variable [::config::getVar showOfflineGroup] -command [list ::Event::fireEvent changedSorting gui]

	###########################
	#Actions menu
	###########################
	set actions .main_menu.actions
	menu $actions -tearoff 0 -type normal

	#Send msg
	$actions add command -label "[trans sendmsg]..." -command [list ::amsn::ShowUserList [trans sendmsg] ::amsn::chatUser 1] -state disabled
	#Send SMS
	$actions add command -label "[trans sendmobmsg]..." -command [list ::amsn::ShowUserList [trans sendmobmsg] ::MSNMobile::OpenMobileWindow] -state disabled
	#Send e-mail
	$actions add command -label "[trans sendmail]..." -command [list ::amsn::ShowUserList [trans sendmail] launch_mailer 1 1] -state disabled
	#-------------------
	$actions add separator
	#Send File
	$actions add command -label "[trans sendfile]..." -command [list ::amsn::ShowUserList [trans sendfile] ::amsn::FileTransferSend] -state disabled	
	#Send Webcam
	$actions add command -label "[trans sendcam]..." -command "" -command [list ::amsn::ShowUserList [trans sendcam] ::MSNCAM::SendInviteQueue] -state disabled
	#Ask Webcam
	$actions add command -label "[trans askcam]..." -command "" -command [list ::amsn::ShowUserList [trans askcam] ::MSNCAM::AskWebcamQueue] -state disabled
	#-------------------
	$actions add separator
	#Play game
	$actions add cascade -label "[trans playgame]" -menu [::MSNGamesGUI::buildMenu $actions] -state disabled
	
	###########################
	#Contacts menu
	###########################
	set conts .main_menu.contacts
	menu $conts -tearoff 0 -type normal

	#add contact
	$conts add command -label "[trans addacontact]..." -command cmsn_draw_addcontact -state disabled
	#remove contact
	$conts add command -label "[trans delete]..." -command [list ::amsn::ShowUserList [trans delete] ::amsn::deleteUser 1] -state disabled
	#contact properties
	$conts add command -label "[trans properties]..." -command [list ::amsn::ShowUserList [trans properties] ::abookGui::showUserProperties] -state disabled
	#-------------------
	$conts add separator
	#Add group
	$conts add command -label "[trans groupadd]..." -state disabled -command [list ::groups::dlgAddGroup]
	#remove group
	$conts add cascade -label "[trans groupdelete]" -state disabled -menu $conts.group_list_delete
	#rename group
	$conts add cascade -label "[trans grouprename]"  -state disabled -menu $conts.group_list_rename
	::groups::Init $conts
	#-------------------
	$conts add separator
	#chat history
	$conts add command -label "[trans history]" -command [list ::log::OpenLogWin] -state disabled
	#webcam history
	$conts add command -label "[trans webcamhistory]" -command [list ::log::OpenCamLogWin] -state disabled
	#-------------------
	$conts add separator
	$conts add command -label "[trans savecontacts]" \
		-command [list saveContacts] -state disabled
	$conts add command -label "[trans loadcontacts]" \
		 -command [list ::abook::importContact] -state disabled	

	###########################
	#Help menu
	###########################
	set help .main_menu.helpmenu
	menu $help -tearoff 0 -type normal

	if {[OnMac]} {
		# The help menu on a mac should be given the Command-? accelerator.
		$help add command -label "[trans onlinehelp]" \
			-command [list launch_browser $::weburl/wiki/Main_Page] \
			-accelerator "Command-?"
	} else {
		$help add command -label "[trans onlinehelp]" \
			-command [list launch_browser $::weburl/wiki/Main_Page] \
	}

	set lang [::config::getGlobalKey language]
	$help add command -label "[trans faq]" \
	    -command [list launch_browser "$::weburl/faq.php?lang=$lang"]
	$help add separator
	$help add command -label "[trans msnstatus]" \
	    -command [list launch_browser http://messenger.msn.com/Status.aspx]
	$help add command -label "[trans sendfeedback]" -command [list launch_browser "$::weburl/forums/index.php"]

	# About is in the app menu on Mac
	if {![OnMac]} {
		$help add separator
		$help add command -label "[trans about]" -command [list ::amsn::aboutWindow]
	}

	#add a postevent to modify the main menu
	set evPar(menu) .main_menu
	::plugins::PostEvent mainmenu evPar	

	# Show the menubar if config allows it (or we're on Mac)
	if { [OnMac] || [::config::getKey showmainmenu -1] } { . conf -menu .main_menu }	
}

proc preLogout {postCommand {force 0}} {
	if {[::ChatWindow::CloseAllWindows $force] == 1} {
		eval $postCommand
	}
}

#///////////////////////////////////////////////////////////////////////
proc cmsn_draw_main {} {
	global pgBuddy pgBuddyTop pgNews argv0 argv

	create_states_menu .my_menu
	create_other_menus .user_menu .menu_invite
	create_main_menu .main_menu

	wm title . "[trans title] - [trans offline]"
	wm command . [concat $argv0 $argv]
	wm group . .
	
	if { [OnMac] } {
		# Set the window style (brushed/aqua) for the CL.
		::macWindowStyle::setBrushed .
		
		frame .fake ;#Create the frame for play_Sound_Mac
	}

	#Put the color, size and style of the border around the contact list (from the skin)
	frame .main -relief [::skin::getKey mainwindowrelief "flat"] \
		-borderwidth [::skin::getKey mainwindowbd "1"] \
		-background [::skin::getKey mainwindowbg "white"]

	frame .main.f -relief flat -background [::skin::getKey mainwindowbg "white"] -borderwidth 0
	pack .main -fill both -expand true
	pack .main.f -expand true -fill both -padx [::skin::getKey buddylistpad] -pady [::skin::getKey buddylistpad] -side top

	if {[::config::getKey withnotebook]} {
		# Create the Notebook and initialize the page paths. These
		# page paths must be used for adding new widgets to the
		# notebook tabs. (This is disabled by default)
		NoteBook .main.f.nb -background white
		.main.f.nb insert end buddies -text "Buddies"
		.main.f.nb insert end news -text "News"
		set pgBuddy [.main.f.nb getframe buddies]
		set pgNews  [.main.f.nb getframe news]
		.main.f.nb raise buddies
		.main.f.nb compute_size
		pack .main.f.nb -fill both -expand true -side top
	} else {
		# Set what's necessary to make it work without the notebook
		set pgBuddy .main.f
		set pgNews  ""
	}

	# Set default pixmap names
	::skin::SetPixmapNames

	set pgBuddyTop $pgBuddy.top
	frame $pgBuddyTop -background [::skin::getKey topcontactlistbg] -width 30 -height 30 -cursor left_ptr \
		-borderwidth 0 -relief flat
	
	$pgBuddyTop configure -padx 0 -pady 0

	set pgBuddy [::guiContactList::createCLWindowEmbeded $pgBuddy]
	pack $pgBuddy -expand true -fill both

	# Initialize the event history
	frame .main.eventmenu
	combobox::combobox .main.eventmenu.list -editable false -highlightthickness 0 -width 22 -exportselection false

	#Display the amsn banner if it is enabled
	label .main.banner -borderwidth 0 -relief flat -background [::skin::getKey bannerbg]
	pack .main.banner -side bottom -fill x
	resetBanner

	#delete F10 binding that crashes amsn
	bind all <F10> ""
	
	set modifier [GetPlatformModifier]
	#Status log
	bind . <$modifier-s> toggle_status
	#Console
	bind . <$modifier-Shift-C> "load_console; console show"
	#Quit
	bind all <$modifier-q> "exit"
	bind all <$modifier-Q> "exit"
	
	#Set key bindings which are different on Mac.
	if { [OnMac] } {
		#Skin selector
		bind all <$modifier-S> ::skinsGUI::SelectSkin
		#Plugin selector
		bind all <$modifier-P> ::plugins::PluginGui
		#Preferences
		bind all <$modifier-,> Preferences
		#BossMode (Command Alt space is used as a global key combo since Mac OS X 10.4.)
		bind . <$modifier-Shift-space> BossMode
		#Plugins log
		bind . <$modifier-p> ::pluginslog::toggle

		#Online Help
		bind all <$modifier-/> "launch_browser $::weburl/wiki/Main_Page"
		bind all <$modifier-?> "launch_browser $::weburl/wiki/Main_Page"

		bind all <$modifier-m> "catch {wm state %W normal; carbon::processHICommand mini %W}"
		bind all <$modifier-M> "catch {wm state %W normal; carbon::processHICommand mini %W}"
		bind all <$modifier-quoteleft> "catch {carbon::processHICommand rotw %W}"
		bind all <$modifier-asciitilde> "catch {carbon::processHICommand rotb %W}"
		# Webcam bindings
	} else {
		#Plugins log
		bind . <Alt-p> ::pluginslog::toggle
		#Preferences
		bind . <$modifier-p> Preferences
		#Boss mode
		bind . <$modifier-Alt-space> BossMode
		# Show/hide menu binding with toggle == 1
		bind . <$modifier-m> "Showhidemenu 1"
		bind . <$modifier-n> "::AVAssistant::AVAssistant"
	}

	#Set the wm close button action
	if { [OnMac] } {
		wm protocol . WM_DELETE_WINDOW { ::amsn::closeAmsnMac }
	} else {
		wm protocol . WM_DELETE_WINDOW {::amsn::closeOrDock [::config::getKey closingdocks]}
	}

	#Draw main window contents
	cmsn_draw_status
	cmsn_draw_offline
	#iconphoto is bugged under windows so I disable it for now : that should be removed when it will be fixed in Tk
	# See Tk bug #1467997
	if { ![OnWin] && [version_vcompare [info patchlevel] 8.4.8] >= 0 } {
		set use_old_method 0
		if { [catch {wm iconphoto . -default [::skin::loadPixmap amsnicon]}] } {
			set use_old_method 1
		}
	} else {
		set use_old_method 1
	}
	if { $use_old_method == 1 } {
		# above doesn't exist on 8.4.7 and older, so we try the old way
		if { [OnWin] } {
			catch {wm iconbitmap . [::skin::GetSkinFile winicons msn.ico]}
			catch {wm iconbitmap . -default [::skin::GetSkinFile winicons msn.ico]}
		} else {
			catch {wm iconbitmap . @[::skin::GetSkinFile pixmaps amsn.xbm]}
			catch {wm iconmask . @[::skin::GetSkinFile pixmaps amsnmask.xbm]}
		}
	}

	#allow for display updates so window size is correct
	update
	#update idletasks
	
	#Set the position on the screen and the size for the contact list, from config
	#Check if the geometry is available :
	set geometry [::config::getKey wingeometry]
	set width 0
	set height 0
	set x 0
	set y 0
	set modified 0
	regexp {=?(\d+)x(\d+)[+\-](-?\d+)[+\-](-?\d+)} $geometry -> width height x y
	
	# Now make sure that the window will be onscreen. Checking each edge (top, right, bottom, left)
	# The minimum values are in pixels from each edge.
	set t_min 0
	set r_min 0
	set b_min 0
	set l_min 0
	
	if {[OnMac]} {
		# There is a menu bar running accross the top of the screen that is 22px high..
		set t_min 22
	}
	
	# Check the top.
	if {[expr {$y}] < $t_min} {
		set modified 1
		set y $t_min
	}
	
	# Check the right.
	if {[expr {$x + $width}] > [expr {[winfo screenwidth .] - $r_min}]} {
		set modified 1
		set x [expr {[winfo screenwidth .] - $width - $r_min}]
	}
	
	# Check the bottom.
	if {[expr {$y + $height}] > [expr {[winfo screenheight .] - $b_min}]} {
		set modified 1
		set y [expr {[winfo screenheight .] - $height - $b_min}]
	}
	
	# Check the left.
	if {[expr {$x}] < $l_min} {
		set modified 1
		set x $l_min
	}

	if {$modified == 1} {
		set geometry ${width}x${height}+${x}+${y}
		::config::setKey wingeometry $geometry
	}
	catch {wm geometry . $geometry}
	update idletasks
	
	#Unhide main window now that it has finished being created
	wm state . normal
}
#///////////////////////////////////////////////////////////////////////




proc loggedInGuiConf { event } {
	################################################################
	# Enable menu entries that are greyed out when not logged in
	################################################################
	proc enable { menu entry {state 1}} {
		if { $state == 1 } {
			$menu entryconfigure $entry -state normal
		} else {
			$menu entryconfigure $entry -state disabled			
		}
	}
	
	proc enableEntries {menu entrieslist {state 1}} {
		foreach index $entrieslist {
			enable $menu $index $state
		}
	}
	
	set menu .main_menu.account
	
	enable $menu 0 0
	set lo 1

	# Entries to enable in the Account menu
	set logout_idx [$menu index "[trans logout]"]
	set status_idx [$menu index "[trans changestatus]"]
	set nick_idx [$menu index "[trans changenick]..."]
	set psm_idx [$menu index "[trans changepsm]..."]
	set dp_idx [$menu index "[trans changedisplaypic]..."]
	set inbox_idx [$menu index "[trans gotoinbox]"]
	set msn_profile_idx [$menu index "[trans editmyprofile]"]
	set global_alarm_idx [$menu index "[trans cfgalarmall]..."]
	set event_hist_idx [$menu index "[trans eventhistory]"]
	enableEntries $menu [list $logout_idx $status_idx $nick_idx $psm_idx $dp_idx $inbox_idx $msn_profile_idx $global_alarm_idx $event_hist_idx]

	# View menu
	set menu .main_menu.view
	set contact_sorting_idx [$menu index "[trans sortcontactsby]"]
	set email_idx [$menu index "[trans showcontactemail]"]
	set nick_idx [$menu index "[trans showcontactnick]"]
	set asc_idx [$menu index "[trans sortgroupsasc]"]
	set desc_idx [$menu index "[trans sortgroupsdesc]"]
	set detview_idx [$menu index "[trans showdetailedview]"]
	set nonim_idx [$menu index "[trans shownonim]"]
	set spaces_idx [$menu index "[trans showspaces]"]
	set offline_idx [$menu index "[trans showofflinegroup]"]
	enableEntries $menu [list $contact_sorting_idx $email_idx $nick_idx $asc_idx $desc_idx $detview_idx $nonim_idx $spaces_idx $offline_idx]
	
	# Actions menu
	set menu .main_menu.actions
	set msg_idx [$menu index "[trans sendmsg]..."]
	set mobile_idx [$menu index "[trans sendmobmsg]..."]
	set email_idx [$menu index "[trans sendmail]..."]
	set file_idx [$menu index "[trans sendfile]..."]
	set send_cam_idx [$menu index "[trans sendcam]..."]
	set ask_cam_idx [$menu index "[trans askcam]..."]
	set play_game_idx [$menu index "[trans playgame]"]
	enableEntries $menu [list $msg_idx $mobile_idx $email_idx $file_idx $send_cam_idx $ask_cam_idx $play_game_idx]
	
	# Contacts menu
	set menu .main_menu.contacts
	set add_idx [$menu index "[trans addacontact]..."]
	set del_idx [$menu index "[trans delete]..."]
	set prop_idx [$menu index "[trans properties]..."]
	set grp_add_idx [$menu index "[trans groupadd]..."]
	set grp_del_idx [$menu index "[trans grouprename]"]
	set grp_ren_idx [$menu index "[trans groupdelete]"]
	set hist_idx [$menu index "[trans history]"]
	set cam_idx [$menu index "[trans webcamhistory]"]
	set save_idx [$menu index "[trans savecontacts]"]
	set load_idx [$menu index "[trans loadcontacts]"]
	enableEntries $menu [list $add_idx $del_idx $prop_idx $grp_add_idx $grp_del_idx $grp_ren_idx $hist_idx $cam_idx $save_idx $load_idx]

	################################################################
	# Create the groups menus
	################################################################
	::groups::updateMenu menu .main_menu.contacts.group_list_delete ::groups::menuCmdDelete
	::groups::updateMenu menu .main_menu.contacts.group_list_rename ::groups::menuCmdRename
}

proc loggedOutGuiConf { event } {
	################################################################
	# Enable menu entries that are greyed out when not logged in
	################################################################
	proc enable { menu entry {state 1} } {
		if { $state == 1 } {
			$menu entryconfigure $entry -state normal
		} else {
			$menu entryconfigure $entry -state disabled			
		}
		
	}
	
	proc enableEntries {menu entrieslist {state 1}} {
		foreach index $entrieslist {
			enable $menu $index $state
		}
	}
			
	set menu .main_menu.account
	
	enable $menu 0 1
	set lo 1
	# Entries to disable in the Account menu
	set logout_idx [$menu index "[trans logout]"]
	set status_idx [$menu index "[trans changestatus]"]
	set nick_idx [$menu index "[trans changenick]..."]
	set psm_idx [$menu index "[trans changepsm]..."]
	set dp_idx [$menu index "[trans changedisplaypic]..."]
	set inbox_idx [$menu index "[trans gotoinbox]"]
	set msn_profile_idx [$menu index "[trans editmyprofile]"]
	set global_alarm_idx [$menu index "[trans cfgalarmall]..."]
	set event_hist_idx [$menu index "[trans eventhistory]"]
	enableEntries $menu [list $logout_idx $status_idx $nick_idx $psm_idx $dp_idx $inbox_idx $msn_profile_idx $global_alarm_idx $event_hist_idx] 0

	# View menu
	set menu .main_menu.view
	set contact_sorting_idx [$menu index "[trans sortcontactsby]"]
	set email_idx [$menu index "[trans showcontactemail]"]
	set nick_idx [$menu index "[trans showcontactnick]"]
	set asc_idx [$menu index "[trans sortgroupsasc]"]
	set desc_idx [$menu index "[trans sortgroupsdesc]"]
	set detview_idx [$menu index "[trans showdetailedview]"]
	set nonim_idx [$menu index "[trans shownonim]"]
	set spaces_idx [$menu index "[trans showspaces]"]
	set offline_idx [$menu index "[trans showofflinegroup]"]
	enableEntries $menu [list $contact_sorting_idx $email_idx $nick_idx $asc_idx $desc_idx $detview_idx $nonim_idx $spaces_idx $offline_idx] 0
	
	# Actions menu
	set menu .main_menu.actions
	set msg_idx [$menu index "[trans sendmsg]..."]
	set mobile_idx [$menu index "[trans sendmobmsg]..."]
	set email_idx [$menu index "[trans sendmail]..."]
	set file_idx [$menu index "[trans sendfile]..."]
	set send_cam_idx [$menu index "[trans sendcam]..."]
	set ask_cam_idx [$menu index "[trans askcam]..."]
	set play_game_idx [$menu index "[trans playgame]"]
	enableEntries $menu [list $msg_idx $mobile_idx $email_idx $file_idx $send_cam_idx $ask_cam_idx $play_game_idx] 0
	
	# Contacts menu
	set menu .main_menu.contacts
	set add_idx [$menu index "[trans addacontact]..."]
	set del_idx [$menu index "[trans delete]..."]
	set prop_idx [$menu index "[trans properties]..."]
	set grp_add_idx [$menu index "[trans groupadd]..."]
	set grp_del_idx [$menu index "[trans grouprename]"]
	set grp_ren_idx [$menu index "[trans groupdelete]"]
	set hist_idx [$menu index "[trans history]"]
	set cam_idx [$menu index "[trans webcamhistory]"]
	set save_idx [$menu index "[trans savecontacts]"]
	set load_idx [$menu index "[trans loadcontacts]"]
	enableEntries $menu [list $add_idx $del_idx $prop_idx $grp_add_idx $grp_del_idx $grp_ren_idx $hist_idx $cam_idx $save_idx $load_idx] 0

	# hide event box
	pack forget .main.eventmenu
}

proc ShowFirstTimeMenuHidingFeature { parent } {
	#TODO : customMessageBox with askRememberAnswer
    return [expr [::amsn::messageBox [trans hidemenumessage] yesno warning [trans hidemenu] $parent ] == yes]
}

proc Showhidemenu { {toggle 0} } {
    if {$toggle} { 
	if { [::config::getKey showmainmenu -1] == -1 } {
	    if { [ShowFirstTimeMenuHidingFeature .] == 0 } {
		return
	    }
	}
	::config::setKey showmainmenu [expr ![::config::getKey showmainmenu -1]] 
    } 

    if { [::config::getKey showmainmenu -1]} {
	. configure -menu .main_menu
    } else {
	. configure -menu ""
    }
}



proc resetBanner {} {
	if {[::config::getKey enablebanner]} {
		# This one is not a banner but a branding. When adverts are enabled
		# they share this space with the branding image. The branding image
		# is cycled in between adverts.
		.main.banner configure -background [::skin::getKey bannerbg] -image [::skin::loadPixmap logolinmsn]
	} else {
		.main.banner configure -background [::skin::getKey mainwindowbg] -image [::skin::loadPixmap nullimage]
	}
}
#///////////////////////////////////////////////////////////////////////


proc choose_font { parent title {initialfont ""} {initialcolor ""}} {
	if { [winfo exists .fontsel] } {
		raise .fontsel
		return
	}

	set selected_font [SelectFont .fontsel -parent $parent -title $title -font $initialfont -initialcolor $initialcolor]
	return $selected_font
}


#///////////////////////////////////////////////////////////////////////
# change_font
# Opens a font selector and changes the config key given by $key to the font selected
proc change_font {win_name key} {
	#puts "change $key"
	set basesize [lindex [::config::getGlobalKey basefont] 1]

	#Get current font configuration
	set fontname [lindex [::config::getKey $key] 0]
	set fontsize [expr {$basesize + [::config::getKey textsize]}]
	set fontstyle [lindex [::config::getKey $key] 1]
	set fontcolor [lindex [::config::getKey $key] 2]

	if { $fontname	== "" } { set fontname helvetica }
	if { $fontcolor	== "" } { set fontcolor 000000 }
	set selfont_and_color [choose_font .${win_name} [trans choosebasefont] [list $fontname $fontsize $fontstyle] "#$fontcolor"]

	set selfont [lindex $selfont_and_color 0]
	set selcolor [lindex $selfont_and_color 1]

	if { $selfont == "" || $fontname == $selfont && $fontcolor == $selcolor } {
		return
	}

	set sel_fontfamily [lindex $selfont 0]
	set sel_fontsize [lindex $selfont 1]
	set sel_fontstyle [lrange $selfont 2 end]

	# Fix a weird bug occuring with 8.4.16 on mac.
	if { ![info exists sel_fontstyle] } { set sel_fontstyle [list] }

	if { $selcolor == "" } {
		set selcolor $fontcolor
	} else {
		set selcolor [string range $selcolor 1 end]
	}

	::config::setKey $key [list $sel_fontfamily $sel_fontstyle $selcolor]

	change_myfontsize [expr {$sel_fontsize - $basesize}]
}
#///////////////////////////////////////////////////////////////////////

proc change_myfontsize { size {windows ""}} {
	set basesize [lindex [::config::getGlobalKey basefont] 1]

	#Get current font configuration
	set fontfamily [lindex [::config::getKey mychatfont] 0]
	set fontsize [expr {$basesize + $size} ]
	set fontstyle [lindex [::config::getKey mychatfont] 1]
	set fontcolor [lindex [::config::getKey mychatfont] 2]
	if { $fontcolor == "" } { set fontcolor "000000" }

	if { $windows == "" } {
		set windows $::ChatWindow::windows
	}

	foreach w  $windows {
		catch {
		[::ChatWindow::GetOutText $w] tag configure yours -font [list $fontfamily $fontsize $fontstyle]
		[::ChatWindow::GetInputText $w] configure -font [list $fontfamily $fontsize $fontstyle]
		[::ChatWindow::GetInputText $w] configure -foreground "#$fontcolor"
	}
		#Get old user font and replace its size
		catch {
			set font [lreplace [[::ChatWindow::GetOutText $w] tag cget user -font] 1 1 $fontsize]
			[::ChatWindow::GetOutText $w] tag configure user -font $font
		} res
	}

	::config::setKey textsize $size
}


#///////////////////////////////////////////////////////////////////////
proc cmsn_msgwin_sendmail {name} {
	upvar #0 [sb name $name users] users_list
	set win_name "msg_[string tolower ${name}]"

	if {[llength $users_list]} {
		set recipient ""
		foreach usrinfo $users_list {
			if { $recipient != "" } {
				set recipient "${recipient}, "
			}
			set user_login [lindex $usrinfo 0]
			set recipient "${recipient}${user_login}"
		}
	} else {
		set recipient "recipient@somewhere.com"
	}

	launch_mailer $recipient
}
#///////////////////////////////////////////////////////////////////////


#///////////////////////////////////////////////////////////////////////
proc show_encodingchoose {} {
	set encodings [encoding names]
	set encodings [lsort $encodings]
	set enclist [list]
	foreach enc $encodings {
		if { $enc != "unicode" } {
			lappend enclist [list $enc $enc]
		}
	}
	set enclist [linsert $enclist 0 [list "Automatic" auto]]
	::amsn::listChoose "[trans encoding]" $enclist set_encoding 0 1
}
#///////////////////////////////////////////////////////////////////////



#///////////////////////////////////////////////////////////////////////
proc set_encoding {enc} {
	if {[catch {encoding system $enc} res]} {
		if { $enc != "auto" } {
			msg_box "Selected encoding not available, setting back to automatic"
		} else {
			catch {encoding system $::auto_encoding }
		}
		::config::setKey encoding auto
	} else {
		::config::setKey encoding $enc
	}
}
#///////////////////////////////////////////////////////////////////////



#///////////////////////////////////////////////////////////////////////
proc cmsn_draw_status {} {
	global followtext_status queued_status
	set w .status
	
	if { [winfo exists $w] } {return}
	toplevel $w
	wm group $w .
	wm state $w withdrawn
	wm title $w "Status Log - [trans title]"

	set followtext_status 1

	text $w.info -width 60 -height 30 -wrap word \
		-yscrollcommand "$w.ys set" -font splainf
	scrollbar $w.ys -command "$w.info yview"
	entry $w.enter
	checkbutton $w.follow -text "[trans followtext]" -onvalue 1 -offvalue 0 -variable followtext_status -font sboldf

	frame $w.bot -relief sunken -borderwidth 1
	button $w.bot.save -text [trans savetofile] -command status_save
	button $w.bot.clear  -text [trans clear] \
		-command "$w.info delete 0.0 end"
	button $w.bot.close -text [trans close] -command toggle_status
	pack $w.bot.save $w.bot.close $w.bot.clear -side left

	pack $w.bot $w.enter $w.follow -side bottom
	pack $w.enter  -fill x
	pack $w.ys -side right -fill y
	pack $w.info -expand true -fill both

	$w.info tag configure green -foreground darkgreen
	$w.info tag configure red -foreground red
	$w.info tag configure white -foreground white -background black
	$w.info tag configure white_highl -foreground white -background [$w.info tag cget sel -background]
	$w.info tag configure blue -foreground blue
	$w.info tag configure error -foreground white -background black
	$w.info tag configure error_highl -foreground white -background [$w.info tag cget sel -background]

	bind $w.info <<Selection>> "highlight_selected_tags %W \{white white_highl error error_highl\}"

	bind $w.enter <Return> "window_history add %W; ns_enter"
	bind $w.enter <Key-Up> "window_history previous %W"
	bind $w.enter <Key-Down> "window_history next %W"
	wm protocol $w WM_DELETE_WINDOW { toggle_status }
	
	set modifier [GetPlatformModifier]
	bind $w <$modifier-w> toggle_status
	
	if { [info exists queued_status] && [llength $queued_status] > 0 } {
		foreach item $queued_status {
			status_log [lindex $item 0] [lindex $item 1]
		}
		unset queued_status
	}
}

proc status_save { } {
	set w .status_save

	toplevel $w
	wm title $w [trans savetofile]
	label $w.msg -justify center -text [trans enterfilename]
	pack $w.msg -side top

	frame $w.buttons
	pack $w.buttons -side bottom -fill x -pady 2m
	button $w.buttons.dismiss -text [trans cancel] -command "destroy $w"
	button $w.buttons.save -text [trans save] -command "status_save_file $w.filename.entry; destroy $w"
	pack $w.buttons.save $w.buttons.dismiss -side left -expand 1

	frame $w.filename -bd 2
	entry $w.filename.entry -relief sunken -width 40
	label $w.filename.label -text "[trans filename]:"
	pack $w.filename.entry -side right
	pack $w.filename.label -side left
	pack $w.msg $w.filename -side top -fill x
	focus $w.filename.entry

	chooseFileDialog "status_log.txt" "" $w $w.filename.entry save

	catch {grab $w}
}

proc status_save_file { filename } {
	set fd [open [${filename} get] a+]
	fconfigure $fd -encoding utf-8
	puts $fd "[.status.info get 0.0 end]"
	close $fd
}
#///////////////////////////////////////////////////////////////////////



#///////////////////////////////////////////////////////////////////////
proc cmsn_draw_offline {} {

	::Event::fireEvent show_login_screen gui
}
#///////////////////////////////////////////////////////////////////////

proc ms_to_timer { ms } {
	set ts [expr {$ms / 1000}]
	set m [expr {$ts / 60}]
	set s [expr {$ts % 60}]

	if {$m < 10} {
		set sm "0${m}"
	} else {
		set sm $m
	}
	if {$s < 10} {
		set ss "0${s}"
	} else {
		set ss $s
	}

	return "${sm}:${ss}"
}
proc cmsn_update_reconnect_timer { } {
	global reconnect_timer reconnect_timer_remaining

	# Now we get a lock on the contact list
	set clcanvas [set ::guiContactList::clcanvas]

	if {$reconnect_timer > 0 &&
	    [$clcanvas type reconnect_timer] == "text"} {
		$clcanvas itemconfigure reconnect_timer -text "[ms_to_timer $::reconnect_timer_remaining]" 
		incr reconnect_timer_remaining -1000
		after 1000 cmsn_update_reconnect_timer
	}

}

#///////////////////////////////////////////////////////////////////////
proc cmsn_draw_reconnect { error_msg } {
	bind . <Configure> ""

	global pgBuddyTop

	# TODO : this is a hack to allow the login screen to get unpacked when we reconnect...
	::Event::fireEvent reconnecting gui

	# Now we get a lock on the contact list
	set clcanvas [::guiContactList::lockContactList]

	if { $clcanvas == "" } { return }

	pack forget $pgBuddyTop
	#pack forget .main.loginscreen
	#pack .main.f -expand true -fill both

	set loganim [::skin::loadPixmap loganim]

	$clcanvas create image 0 90 -image $loganim -anchor n -tags [list loganim centerx]

	$clcanvas create text 0 [expr 120 + [image height $loganim]] -text "$error_msg" -font splainf \
		-fill [::skin::getKey loginfg]  -justify center -tags [list errormsg centerx]

	$clcanvas create text 0 [expr 190 + [image height $loganim]] -text "[trans reconnecting]..." -font sboldf \
		-fill [::skin::getKey loginfg]  -tags [list signin centerx]

	$clcanvas create text 0 [expr 220 + [image height $loganim]] -text "" -font sboldf \
		-fill [::skin::getKey loginfg]  -tags [list reconnect_timer centerx]

	$clcanvas create text 0 [expr 260 + [image height $loganim]] -text "[trans reconnectnow]" -font splainf \
		-fill [::skin::getKey loginurlfg] -tags [list reconnect_now centerx]

	$clcanvas create text 0 [expr 320 + [image height $loganim]] -text "[trans cancel]" -font splainf \
		-fill [::skin::getKey loginurlfg] -tags [list cancel_reconnect centerx]

	$clcanvas bind cancel_reconnect <Enter> \
		"$clcanvas itemconfigure cancel_reconnect -fill [::skin::getKey loginurlfghover] -font sunderf;\
		$clcanvas configure -cursor hand2"
	$clcanvas bind cancel_reconnect <Leave> \
		"$clcanvas itemconfigure cancel_reconnect -fill [::skin::getKey loginurlfg] -font splainf;\
		$clcanvas configure -cursor left_ptr"
	$clcanvas bind cancel_reconnect <<Button1>> \
		"preLogout \"::MSN::cancelReconnect\""

	$clcanvas bind reconnect_now <Enter> \
		"$clcanvas itemconfigure reconnect_now -fill [::skin::getKey loginurlfghover] -font sunderf;\
		$clcanvas configure -cursor hand2"
	$clcanvas bind reconnect_now <Leave> \
		"$clcanvas itemconfigure reconnect_now -fill [::skin::getKey loginurlfg] -font splainf;\
		$clcanvas configure -cursor left_ptr"
	$clcanvas bind reconnect_now <<Button1>> {
		after cancel ::MSN::connect
		::MSN::connect
	}

	::guiContactList::centerItems $clcanvas

	set bbox [$clcanvas bbox cancel_reconnect signin errormsg loganim]
	$clcanvas configure -scrollregion [list 0 0 [lindex $bbox 2] [lindex $bbox 3]]

	::guiContactList::semiUnlockContactList

	cmsn_update_reconnect_timer
}
#///////////////////////////////////////////////////////////////////////



#///////////////////////////////////////////////////////////////////////
proc cmsn_draw_signin {} {
	bind . <Configure> ""

	global pgBuddyTop eventdisconnected

	set eventdisconnected 1

	wm title . "[trans title] - [::config::getKey login]"


	# Now we get a lock on the contact list
	set clcanvas [::guiContactList::lockContactList]

	if { $clcanvas == "" } { return }

	pack forget $pgBuddyTop
	#pack forget .main.loginscreen
	#pack .main.f -expand true -fill both

	set loganim [::skin::loadPixmap loganim]

	$clcanvas create image 0 90 -image $loganim -anchor n -tags [list loganim centerx]

	$clcanvas create text 0 [expr 120 + [image height $loganim]] -text "[trans loggingin]..." -font sboldf \
		-fill [::skin::getKey loginfg] -tags [list signin centerx]

	$clcanvas create text 0 [expr 190 + [image height $loganim]] -text "[trans cancel]" -font splainf \
		-fill [::skin::getKey loginurlfg] -tags [list cancel_reconnect centerx]

	$clcanvas bind cancel_reconnect <Enter> \
		"$clcanvas itemconfigure cancel_reconnect -fill [::skin::getKey loginurlfghover] -font sunderf;\
		$clcanvas configure -cursor hand2"
	$clcanvas bind cancel_reconnect <Leave> \
		"$clcanvas itemconfigure cancel_reconnect -fill [::skin::getKey loginurlfg] -font splainf;\
		$clcanvas configure -cursor left_ptr"
	$clcanvas bind cancel_reconnect <<Button1>> \
		"preLogout \"::MSN::cancelReconnect\""

	::guiContactList::centerItems $clcanvas

	set bbox [$clcanvas bbox cancel_reconnect signin loganim]
	$clcanvas configure -scrollregion [list 0 0 [lindex $bbox 2] [lindex $bbox 3]]

	::guiContactList::semiUnlockContactList
}
#///////////////////////////////////////////////////////////////////////


#///////////////////////////////////////////////////////////////////////
proc login_ok {} {
	global password loginmode

	if { $loginmode == 0 } {
		::config::setKey login [string tolower [.login.main.loginentry get]]
		set password [.login.main.passentry get]
	} else {
		if { $password != [.login.main.passentry2 get] } {
			set password [.login.main.passentry2 get]
		}
	}

	catch {grab release .login}
	destroy .login

	if { $password != "" && [::config::getKey login] != "" } {
		::MSN::connect $password
	} else {
		cmsn_draw_login
	}
}
#///////////////////////////////////////////////////////////////////////

proc SSLToggled {} {
	if {[::config::getKey nossl] == 1 } {
		::amsn::infoMsg "[trans sslwarning]"
	}
}



#///////////////////////////////////////////////////////////////////////
# Main login window, separated profiled or default logins
# cmsn_draw_login {}
#
proc cmsn_draw_login {} {
	global password loginmode HOME HOME2 protocol

	if {[winfo exists .login]} {
		raise .login
		return 0
	}

	LoadLoginList 1

	toplevel .login
	wm group .login .
	wm title .login "[trans login] - [trans title]"
	ShowTransient .login
	set mainframe [labelframe .login.main -text [trans login] -font splainf]

	radiobutton $mainframe.button -text [trans defaultloginradio] -value 0 -variable loginmode -command "RefreshLogin $mainframe"
	label $mainframe.loginlabel -text "[trans user]: " -font sboldf
	entry $mainframe.loginentry -width 25
	if { [::config::getGlobalKey disableprofiles]!=1} { 
		grid $mainframe.button -row 1 -column 1 -columnspan 2 -sticky w -padx 10 
	}
	grid $mainframe.loginlabel -row 2 -column 1 -sticky e -padx 10
	grid $mainframe.loginentry -row 2 -column 2 -sticky w -padx 10

	radiobutton $mainframe.button2 -text [trans profileloginradio] -value 1 -variable loginmode -command "RefreshLogin $mainframe"
	combobox::combobox $mainframe.box -editable false -width 25 -command ConfigChange
	if { [::config::getGlobalKey disableprofiles]!=1} {
		grid $mainframe.button2 -row 1 -column 3 -sticky w
		grid $mainframe.box -row 2 -column 3 -sticky w
	}

	label $mainframe.passlabel -text "[trans pass]: " -font sboldf
	entry $mainframe.passentry -width 25 -show "*" -vcmd {expr {[string length %P]<=16} } -validate key
	entry $mainframe.passentry2 -width 25 -show "*" -vcmd {expr {[string length %P]<=16} } -validate key
	checkbutton $mainframe.remember -variable [::config::getVar save_password] \
		-text "[trans rememberpass]" -pady 5 -padx 10

	#Combobox to choose our state on connect
	label $mainframe.statetext -text "[trans signinstatus]" -font splainf
	combobox::combobox $mainframe.statelist -editable false -width 15 -command remember_state_list \
		-bg [::skin::getKey extrastdbgcolor]
	$mainframe.statelist list delete 0 end
	set i 0
	while {$i < 8} {
		set statecode "[::MSN::numberToState $i]"
		set description "[trans [::MSN::stateToDescription $statecode]]"
		$mainframe.statelist list insert end $description
		incr i
	}
	# Add custom states to list
	AddStatesToList $mainframe.statelist

	$mainframe.statelist select [get_state_list_idx [::config::getKey connectas]]
	label $mainframe.example -text "[trans examples] :\ncopypastel@hotmail.com\nelbarney@msn.com\nexample@passport.com" -font examplef -padx 10

	set buttonframe [frame .login.buttons]
	button $buttonframe.cancel -text [trans cancel] -command "ButtonCancelLogin .login"
	button $buttonframe.ok -text [trans ok] -command login_ok -default active
	button $buttonframe.addprofile -text [trans addprofile] -command AddProfileWin
	if { [::config::getGlobalKey disableprofiles]!=1} {
		pack $buttonframe.ok $buttonframe.cancel $buttonframe.addprofile -side right -padx 10
	} else {
		pack $buttonframe.ok $buttonframe.cancel -side right -padx 10
	}

	grid $mainframe.passlabel -row 3 -column 1 -sticky e -padx 10
	grid $mainframe.passentry -row 3 -column 2 -sticky w -padx 10
	if { [::config::getGlobalKey disableprofiles]!=1} {
		grid $mainframe.passentry2 -row 3 -column 3 -sticky w
	}
	grid $mainframe.remember -row 5 -column 2 -sticky wn
	grid $mainframe.statetext -row 6 -column 1 -sticky wn
	grid $mainframe.statelist -row 6 -column 2 -sticky wn
	grid $mainframe.example -row 1 -column 4 -rowspan 4

	pack .login.main .login.buttons -side top -anchor n -expand true -fill both -padx 10 -pady 10

	# Lets fill our combobox
	#$mainframe.box insert 0 [::config::getKey login]
	set idx 0
	set tmp_list ""
	while { [LoginList get $idx] != 0 } {
		lappend tmp_list [LoginList get $idx]
		incr idx
	}
	eval $mainframe.box list insert end $tmp_list
	unset idx
	unset tmp_list

	# Select appropriate radio button
	if { $HOME == $HOME2 } {
		set loginmode 0
	} else {
		set loginmode 1
	}

	if { [::config::getGlobalKey disableprofiles]==1} {
		set loginmode 0
	}

	RefreshLogin $mainframe

	bind .login <Return> "login_ok"
	bind .login <KP_Enter> "login_ok"
	bind .login <<Escape>> "ButtonCancelLogin .login"

	#tkwait visibility .login
	catch {grab .login}

	moveinscreen .login 30
}

proc remember_state_list {w value} {
	set idx [get_state_list_idx $value]
	if {$idx >= 8} {
		::config::setKey connectas $value
	} else {
		::config::setKey connectas [::MSN::numberToState $idx]
	}
}

proc get_state_list_idx { value } {
	set i 0
	while {$i < 8} {
		set statecode "[::MSN::numberToState $i]"
		set description "[trans [::MSN::stateToDescription $statecode]]"
		
		if {$description == $value || $statecode == $value} {
			return $i
		}
		incr i
	}
	
	for {set idx 0} {$idx < [StateList size] } { incr idx } {
		if {"** [lindex [StateList get $idx] 0] **" == $value} {
			return [expr {8 + $idx}]
		}
	}

	status_log "Variable connectas is not valid $value\n" red
	return 0
}

proc is_connectas_custom_state { value } {
	return [expr [get_state_list_idx $value] >= 8]
}


proc get_custom_state_idx { value } {
	for {set idx 0} {$idx < [StateList size] } { incr idx } {
		if { "** [lindex [StateList get $idx] 0] **" == $value} {
			return $idx
		}
	}
}

#///////////////////////////////////////////////////////////////////////
# proc RefreshLogin { mainframe }
# Called after pressing a radio button in the Login screen to enable/disable
# the appropriate entries
proc RefreshLogin { mainframe {extra 0} } {
	global loginmode

	if { $extra == 0 } {
		SwitchProfileMode $loginmode
	}

	if { $loginmode == 0 } {
		$mainframe.box configure -state disabled
		$mainframe.passentry2 configure -state disabled
		$mainframe.loginentry configure -state normal
		$mainframe.passentry configure -state normal
		$mainframe.remember configure -state disabled
		focus $mainframe.loginentry
		bind $mainframe.loginentry <Tab> "focus $mainframe.passentry; break"
	} elseif { $loginmode == 1 } {
		$mainframe.box configure -state normal
		$mainframe.passentry2 configure -state normal
		$mainframe.loginentry configure -state disabled
		$mainframe.passentry configure -state disabled
		$mainframe.remember configure -state normal
		focus $mainframe.passentry2
	}
}


#///////////////////////////////////////////////////////////////////////////////
# ButtonCancelLogin ()
# Function thats releases grab on .login and destroys it
proc ButtonCancelLogin { window {email ""} } {
	catch {grab release $window}
	destroy $window
	cmsn_draw_offline
}


#////////////////////////////////////////////////////////////////////// /////////
# AddProfileWin ()
# Small dialog window with entry to create new profile
proc AddProfileWin {} {
	if {[winfo exists .add_profile]} {
		raise .add_profile
			return 0
	}

	toplevel .add_profile
	wm group .add_profile .login

	wm title .add_profile "[trans addprofile]"

	ShowTransient .add_profile .login

	set mainframe [labelframe .add_profile.main -text [trans  addprofile] -font splainf]
	label $mainframe.desc -text "[trans addprofiledesc]" -font splainf  -justify left
	entry $mainframe.login -bd 1 -font splainf  -highlightthickness 0 -width 35
	label $mainframe.example -text "[trans examples]  :\ncopypastel@hotmail.com\nelbarney@msn.com\nexample@passport.com"  -font examplef -padx 10
	grid $mainframe.desc -row 1 -column 1 -sticky w -columnspan 2 -padx 5  -pady 5
	grid $mainframe.login -row 2 -column 1 -padx 5 -pady 5
	grid $mainframe.example -row 2 -column 2 -sticky e

	set buttonframe [frame .add_profile.buttons]
	button $buttonframe.cancel -text [trans cancel] -command "grab release  .add_profile; destroy .add_profile"
	button $buttonframe.ok -text [trans ok] -command "AddProfileOk  $mainframe"

	AddProfileOk $mainframe

	pack  $buttonframe.cancel $buttonframe.ok -side right -padx 10

	bind .add_profile <Return> "AddProfileOk $mainframe"
	#Virtual binding for destroying the window
	bind .add_profile <<Escape>> "grab release .add_profile; destroy  .add_profile"

	pack .add_profile.main .add_profile.buttons -side top -anchor n -expand  true -fill both -padx 10 -pady 10
	catch {grab .add_profile}
	focus $mainframe.login
}

#////////////////////////////////////////////////////////////////////// /////////
# AddProfileOk (mainframe)
#
proc AddProfileOk {mainframe} {
	#In case someone destroy .login
	catch {wm group .add_profile .login}
	set login [string tolower [$mainframe.login get]]
	if { $login == "" } {
		return
	}

	if { [CreateProfile $login] != -1 } {
		catch {grab release .add_profile}
		destroy .add_profile
	}
}

#///////////////////////////////////////////////////////////////////////
proc toggleGroup {tw name image id {padx 0} {pady 0}} {
	set imgIdx [$tw image create end -image [::skin::loadPixmap $image] -padx $padx -pady $pady]
	$tw tag add $name $imgIdx
	$tw tag bind $name <Enter> "$tw image configure $imgIdx -image [::skin::loadPixmap ${image}_hover]; $tw conf -cursor hand2"
	$tw tag bind $name <Leave> "$tw image configure $imgIdx -image [::skin::loadPixmap $image]; $tw conf -cursor left_ptr"
	$tw tag bind $name <<Button1>> "status_log \"$id\"; ::groups::ToggleStatus $id"
}
#///////////////////////////////////////////////////////////////////////

#///////////////////////////////////////////////////////////////////////
proc clickableImage {tw name image command {padx 0} {pady 0}} {
	set imgIdx [$tw image create end -image [::skin::loadPixmap $image] -padx $padx -pady $pady -align center]
	$tw tag add $tw.$name $imgIdx

	$tw tag bind $tw.$name <<Button1>> $command
	$tw tag bind $tw.$name <Enter> "$tw configure -cursor hand2"
	$tw tag bind $tw.$name <Leave> "$tw configure -cursor left_ptr"
}

#Clickable display picture in the contact list
proc clickableDisplayPicture {tw type name command {padx 0} {pady 0}} {

	#Create the clickable display picture
	canvas $tw.$name -width [image width [::skin::loadPixmap mystatus_bg]] \
	    -height [image height [::skin::loadPixmap mystatus_bg]] \
	    -bg [::skin::getKey topcontactlistbg] -highlightthickness 0 \
	    -cursor hand2 -borderwidth 0
	
	$tw.$name create image [::skin::getKey x_dp_top] [::skin::getKey y_dp_top] -anchor nw -image displaypicture_not_self
	$tw.$name create image 0 0 -anchor nw -image [::skin::loadPixmap mystatus_bg] -tag mystatus_bg
	
	if {[::skin::getKey mydp_hoverimage 0] == 1} {
		$tw.$name bind mystatus_bg <Enter> [list $tw.$name itemconfigure mystatus_bg -image [::skin::loadPixmap mystatus_bg_hover]]
		$tw.$name bind mystatus_bg <Leave> [list $tw.$name itemconfigure mystatus_bg -image [::skin::loadPixmap mystatus_bg]]
	}

	bind $tw.$name <<Button1>> $command
	# Drag and Drop setting DP
	if {[catch {::dnd bindtarget $tw.$name Files <Drop> "fileDropHandler %D setdp self"} res]} {
		status_log "dnd error: $res"
	}

	return $tw.$name
}

proc fileDropHandler { data action {target "self"}} {
	set data [string map {\r "" \n "" \x00 ""} $data]
	set data [urldecode $data]

	#this is for windows
	if { [string index $data 0] == "{" && [string index $data end] == "}" } {
		set data [string range $data 1 end-1]
	}

#TODO	#(VFS pseudo-)protocol: if we can't acces the file, display an error
	foreach type [list smb http https ftp sftp floppy cdrom dvd] {
		if {[string first $type $data] == 0} { 
			status_log "file can't be accessed: $data"
		}
	}

	#If the data begins with "file://", strip this off
	if { [string range $data 0 6] == "file://" } {
		set data [string range $data 7 [string length $data]]
	} 

	status_log "File dropped: $data"
		
	switch $action {
		setdp {
#			if { $target != "self" } {
#				global customdp_$target
#				set customdp_$target [::abook::getContactData $target customdp ""]
#			}

			after 0 dpBrowser $target
			setDPFromFile $target $data

#			if { $target != "self" } {
#				tkwait window .dpbrowser
#				catch {image delete customdp_img_$target}
#				image create photo customdp_img_$target -file [set customdp_$target]
#				::skin::getDisplayPicture $target 1
#				::skin::getLittleDisplayPicture $target 1
#				catch {image delete customdp_img_$target}
#
#
#			}

		}
		sendfile {
			if {$target == "self"} {
				status_log "This ain't right ... should I send a file to window 'self'?"
			} else {
	        		::amsn::FileTransferSend $target $data
			}
		}
		default {
			status_log "Dunnow what to do with the file ... what's $action ?"
		}
	}
}


# The same as the previous one, but this proc works on a list.
proc trunc_list {str {window ""} {maxw 0 } {font ""}} {
	if { $window == "" || $font == "" } {
		return $str
	}

	set buffer [list ]
	foreach elt $str  {
		switch [lindex $elt 0] {
		text {
				set txt [lindex $elt 1] 
				set slen [string length $txt]
				for {set idx 0} { $idx <= $slen} {incr idx} {
					if { [font measure $font -displayof $window "[string range $txt 0 $idx]..."] > $maxw } {
						set txt "[string range $txt 0 [expr {$idx-1}]]"
						lappend buffer [list text $txt] [list colour reset] [list bg reset] [list font reset] [list text "..."]
						return $buffer
					}
				}
				set maxw [expr {$maxw - [font measure $font -displayof $window $txt]}]
				lappend buffer $elt
		}
		smiley {
				set maxw [expr {$maxw - [image width [lindex $elt 1]]}]
				if {$maxw <= 0 } {
					lappend buffer [list colour reset] [list bg reset] [list font reset] [list text "..."]
					return $buffer
				}
				lappend buffer $elt
		}
		#what should we do in that case ??? 	
		newline {}
		default {
				lappend buffer $elt
		}
		}
	}
	return $str
}



proc getpicturefornotification {email} {
	#we'll only create it if it's not yet there
	if { ![ImageExists displaypicture_not_$email] } {
		#create the blank image
		image create photo displaypicture_not_$email -format cximage

		#Verify that we can copy user_pic, if there's an error it means user_pic doesn't exist
		if {![catch {displaypicture_not_$email copy [::skin::getDisplayPicture $email]} ] } {
			if {[image width displaypicture_not_$email] > 50 && [image height displaypicture_not_$email] > 50} {
				::picture::ResizeWithRatio displaypicture_not_$email 50 50
			}
			return 1
		} else {
			image delete displaypicture_not_$email
			#we have no small version, report as error
			return 0
		}
	} else {
		#we already have an image
		return 1
	}
}

#///////////////////////////////////////////////////////////////////////

#TODO: This really shouldn't be here
if { $initialize_amsn == 1 } {
	init_ticket draw_online
}

#///////////////////////////////////////////////////////////////////////
# TODO: move into ::amsn namespace, and maybe improve it
# topbottom: 1 = top only, 2 = bottom only, 3 = top and bottom
proc cmsn_draw_online { {delay 0} {topbottom 3} } {
	#Delay not forced redrawing (to avoid too many redraws)
	if { $delay } {
		if { $topbottom & 1 } {
			after cancel "cmsn_draw_online 0 1"
			after 500 "cmsn_draw_online 0 1"
		}
		if { $topbottom & 2 } {
			after cancel "cmsn_draw_online 0 2"
			after 500 "cmsn_draw_online 0 2"
		}
		return
	}

	#Run this procedure in mutual exclusion, to avoid procedure
	#calls due to events while still drawing. This fixes some bugs
	if { $topbottom & 1 } { run_exclusive cmsn_draw_buildtop_wrapped draw_online }
	if { $topbottom & 2 } { run_exclusive cmsn_draw_online_wrapped draw_online }
}

proc cmsn_draw_buildtop_wrapped {} {
	global login password pgBuddy pgBuddyTop automessage emailBList

	set my_image_type [::MSN::stateToBigImage [::MSN::myStatusIs]]
	set my_mobilegroup [::config::getKey showMobileGroup]
	
	#Clear the children of top to avoid memory leaks:
	foreach child [winfo children $pgBuddyTop] {
		destroy $child
	}

	pack $pgBuddyTop -expand false -fill x -before $pgBuddy
	
	# Display MSN logo with user's handle. Make it clickable so
	# that the user can change his/her status that way
	# Verify if the skinner wants to replace the status picture for the display picture
	$pgBuddyTop configure -background [::skin::getKey topcontactlistbg]
	if { ![::skin::getKey showdisplaycontactlist] } {
		label $pgBuddyTop.bigstate -background [::skin::getKey topcontactlistbg] -border 0 -cursor hand2 -borderwidth 0 \
					-image [::skin::loadPixmap $my_image_type] \
					-width [image width [::skin::loadPixmap $my_image_type]] \
					-height [image height [::skin::loadPixmap $my_image_type]]
		bind $pgBuddyTop.bigstate <<Button1>> {kill_balloon; tk_popup .my_menu %X %Y}
		set disppic $pgBuddyTop.bigstate
	} else { 
		set disppic [clickableDisplayPicture $pgBuddyTop mystatus bigstate {kill_balloon; tk_popup .my_menu %X %Y} [::skin::getKey bigstate_xpad] [::skin::getKey bigstate_ypad]]
	}

	set pic_name displaypicture_std_self
	bind $pgBuddyTop.bigstate <<Button3>> {kill_balloon; tk_popup .my_menu %X %Y} 
	pack $disppic -side left -padx [::skin::getKey bigstate_xpad] -pady [::skin::getKey bigstate_ypad]

	canvas $pgBuddyTop.mystatus -background [::skin::getKey topcontactlistbg] -borderwidth 0 \
		-cursor left_ptr -relief flat
	pack $pgBuddyTop.mystatus -expand true -fill both -side left -padx 10 -pady 10

	drawNick

	set balloon_message [list "[string map {"%" "%%"} [::abook::removeStyles [::abook::getVolatileData myself parsed_MFN]]]" \
		"[string map {"%" "%%"} [::abook::getpsmmedia]]" \
		"[::config::getKey login]" "[trans status]: [trans [::MSN::stateToDescription [::MSN::myStatusIs]]]"]
	set fonts [list "sboldf" "sitalf" "splainf" "splainf"]

	bind $pgBuddyTop.bigstate <Enter> +[list balloon_enter %W %X %Y $balloon_message $pic_name $fonts complex]
	bind $pgBuddyTop.bigstate <Leave> "+set Bulle(first) 0; kill_balloon;"
	bind $pgBuddyTop.bigstate <Motion> +[list balloon_motion %W %X %Y $balloon_message $pic_name $fonts complex]
	
	set colorbar $pgBuddyTop.colorbar
	label $colorbar -image [::skin::getColorBar] -background [::skin::getKey topcontactlistbg] -borderwidth 0
	pack $colorbar -before $disppic -side bottom

	set evpar(colorbar) $colorbar
	set evpar(text) $pgBuddyTop
	::plugins::PostEvent ContactListColourBarDrawn evpar
	
	if { [::config::getKey checkemail] } {
		# Show Mail Notification status
		text $pgBuddyTop.mail -height 1 -background [::skin::getKey topcontactlistbg] -borderwidth 0 -wrap none -cursor left_ptr \
			-relief flat -highlightthickness 0 -selectbackground [::skin::getKey topcontactlistbg] -selectborderwidth 0 \
			-exportselection 0 -relief flat -highlightthickness 0 -borderwidth 0 -padx 0 -pady 0
		if {[::skin::getKey emailabovecolorbar]} {
			pack $pgBuddyTop.mail -expand true -fill x -after $colorbar -side bottom -padx 0 -pady 0
		} else {
			pack $pgBuddyTop.mail -expand true -fill x -before $colorbar -side bottom -padx 0 -pady 0
		}
	
		$pgBuddyTop.mail configure -state normal
	
		#Set up TAGS for mail notification
		$pgBuddyTop.mail tag conf mail -fore [::skin::getKey emailfg] -underline false -font splainf
		$pgBuddyTop.mail tag bind mail <<Button1>> "$pgBuddyTop.mail conf -cursor watch; ::hotmail::hotmail_login"
		$pgBuddyTop.mail tag bind mail <Enter> "$pgBuddyTop.mail tag conf mail -under true -fore [::skin::getKey emailhover] -background [::skin::getKey emailhoverbg];$pgBuddyTop.mail conf -cursor hand2"
		$pgBuddyTop.mail tag bind mail <Leave> "$pgBuddyTop.mail tag conf mail -under false -fore [::skin::getKey emailfg] -background [::skin::getKey topcontactlistbg];$pgBuddyTop.mail conf -cursor left_ptr"
	
		set unread [::hotmail::unreadMessages]
		set froms [::hotmail::getFroms]
		set fromsText ""
		foreach {from frommail} $froms {
			append fromsText "\n[trans newmailfrom $from $frommail]"
		}
	
		if {$unread == 0} {
			set mailmsg "[trans nonewmail]"
			set balloon_message "[trans nonewmail]"
			set mail_img mailbox
		} elseif {$unread == 1} {
			set mailmsg "[trans onenewmail]"
			set balloon_message "[trans onenewmail]\n$fromsText"
			set mail_img mailbox_new
		} elseif {$unread == 2} {
			set mailmsg "[trans twonewmail 2]"
			set balloon_message "[trans twonewmail 2]\n$fromsText"
			set mail_img mailbox_new
		} else {
			set mailmsg "[trans newmail $unread]"
			set balloon_message "[trans newmail $unread]\n$fromsText"
			set mail_img mailbox_new
		}

		clickableImage $pgBuddyTop.mail mailbox $mail_img "::hotmail::hotmail_login" [::skin::getKey mailbox_xpad] [::skin::getKey mailbox_ypad]
		set mailheight [expr {[image height [::skin::loadPixmap mailbox]]+(2*[::skin::getKey mailbox_ypad])}]
		#in windows need an extra -2 is to include the extra 1 pixel above and below in a font
		if { [OnWin] || [OnMac] } {
			incr mailheight -2
		}
		set textheight [font metrics splainf -linespace]
		if { $mailheight < $textheight } {
			set mailheight $textheight
		}
		$pgBuddyTop.mail configure -font "{} -$mailheight"

		$pgBuddyTop.mail tag bind mail <Enter> +[list balloon_enter %W %X %Y $balloon_message]
		$pgBuddyTop.mail tag bind mail <Leave> "+set ::Bulle(first) 0; kill_balloon;"
		$pgBuddyTop.mail tag bind mail <Motion> +[list balloon_motion %W %X %Y $balloon_message]
	
		set evpar(text) pgBuddyTop.mail
		set evpar(msg) mailmsg
		::plugins::PostEvent ContactListEmailsDraw evpar
	
		set maxw [expr {[winfo width [winfo parent $pgBuddyTop]]-[image width [::skin::loadPixmap $mail_img]]-(2*[::skin::getKey mailbox_xpad])}]
		set short_mailmsg [trunc $mailmsg $pgBuddyTop.mail $maxw splainf]
		$pgBuddyTop.mail insert end "$short_mailmsg" {mail dont_replace_smileys}
	
		set evpar(text) pgBuddyTop.mail
		::plugins::PostEvent ContactListEmailsDrawn evpar
	
		$pgBuddyTop.mail configure -state disabled
	}
	
	#This lets the top part finish redrawing before the bottom part starts
	#otherwise, the top part stays disappeared until the bottom part
	#finishes redrawing... and we end up with pgBuddyTop disappearing
	#for 1 second with like 90 contacts
	update idletasks
}

#Called when $pgBuddyTop.mystatus is resized
proc RedrawNick {} {
	after cancel "drawNick"
	after 200 "drawNick"
}

proc drawNick { } {
	global pgBuddy pgBuddyTop automessage

	$pgBuddyTop.mystatus delete all

	set maxw [expr {[winfo width [winfo parent $pgBuddyTop]]-[$pgBuddyTop.bigstate cget -width]-(2*[::skin::getKey bigstate_xpad])}]
	set pic_name displaypicture_std_self

	set stylestring [list ]
	lappend stylestring [list "tag" "mystatuslabel"]
	lappend stylestring [list "colour" [::skin::getKey mystatus]]
	lappend stylestring [list "font" [::skin::getFont "mystatuslabel" "splainf"]]
	lappend stylestring [list "text" "[trans mystatus]: "]
	lappend stylestring [list "tag" "-mystatuslabel"]
	#$pgBuddyTop.mystatus insert end "[trans mystatus]: " mystatuslabel
	
	if { [info exists automessage] && $automessage != -1} {
		lappend stylestring [list "tag" "mystatuslabel2"]
		lappend stylestring [list "font" [::skin::getFont "mystatuslabel2" "bboldf"]]
		lappend stylestring [list "text" "[lindex $automessage 0]"]
		lappend stylestring [list "tag" "-mystatuslabel2"]
	}

	lappend stylestring [list "newline" "\n"]
	lappend stylestring [list "underline" "ul"]
	lappend stylestring [list "trunc" 1 "..."]

	#get the new 
	set my_state_desc [trans [::MSN::stateToDescription [::MSN::myStatusIs]]]
	set my_name [::abook::getVolatileData myself parsed_mfn]
	set my_colour [::MSN::stateToColor [::MSN::myStatusIs] "contact"]
	set my_colour_state [::MSN::stateToColor [::MSN::myStatusIs] "contact"]

	lappend stylestring [list "tag" "mystatus"]
	lappend stylestring [list "default" $my_colour [::skin::getFont "mystatus" "bboldf"]]
	lappend stylestring [list "colour" "reset"]
	lappend stylestring [list "font" "reset"]
	set stylestring [concat $stylestring $my_name]
	lappend stylestring [list "default" $my_colour_state [::skin::getFont "mystatus" "bboldf"]]
	lappend stylestring [list "colour" "reset"]
	lappend stylestring [list "font" "reset"]
	lappend stylestring [list "text" " ($my_state_desc)"]
	lappend stylestring [list "tag" "-mystatus"]

	set psmmedia ""
	if {[::config::getKey protocol] >= 11} {
		set psmmedia [::abook::getpsmmedia "" 1]

		lappend stylestring [list "newline" "\n"]
		lappend stylestring [list "tag" "mypsmmedia"]
		lappend stylestring [list "default" $my_colour [::skin::getFont "psmfont" "sbolditalf"]]
		lappend stylestring [list "colour" "reset"]
		lappend stylestring [list "font" "reset"]
		set stylestring [concat $stylestring $psmmedia]
		lappend stylestring [list "tag" "-mypsmmedia"]
	}

	lappend stylestring [list "underline" "reset"]

	if {[llength [::abook::getEndPoints]] > 1} {
		lappend stylestring [list "newline" "\n"]
		lappend stylestring [list "tag" "myplaceslabel"]
		lappend stylestring [list "colour" [::skin::getKey mystatus]]
		lappend stylestring [list "font" [::skin::getFont "mystatuslabel" "splainf"]]
		lappend stylestring [list "text" "[trans connectedat]"]
		lappend stylestring [list "tag" "-myplaceslabel"]
		lappend stylestring [list "tag" "myplaces"]
		lappend stylestring [list "default" $my_colour_state [::skin::getFont "mystatus" "bboldf"]]
		lappend stylestring [list "colour" "reset"]
		lappend stylestring [list "font" "reset"]
		lappend stylestring [list "underline" "pl"]
		lappend stylestring [list "text" "[trans xplaces [llength [::abook::getEndPoints]]]"]
		lappend stylestring [list "tag" "-myplaces"]
		
	}

	::guiContactList::trimInfo stylestring
	set renderInfo [::guiContactList::renderContact $pgBuddyTop.mystatus "all" $maxw $stylestring]
	array set underlinst $renderInfo
	
	set balloon_message [list "[string map {"%" "%%"} [::abook::removeStyles $my_name]]" \
		"[string map {"%" "%%"} [::abook::removeStyles $psmmedia]]" \
		"[::config::getKey login]" "[trans status]: $my_state_desc"]
	set fonts [list "sboldf" "sitalf" "splainf" "splainf"]

	$pgBuddyTop.mystatus bind mystatus <<Button3>> "kill_balloon; tk_popup .my_menu %X %Y"

	$pgBuddyTop.mystatus bind mystatus <Enter> \
		[list ::guiContactList::underlineList $pgBuddyTop.mystatus [set underlinst(ul)] "all"]
	$pgBuddyTop.mystatus bind mystatus <Leave> [list $pgBuddyTop.mystatus delete "uline_all"]
	$pgBuddyTop.mystatus bind mystatus <Enter> \
		+[list $pgBuddyTop.mystatus configure -cursor hand2]
	$pgBuddyTop.mystatus bind mystatus <Leave> +[list $pgBuddyTop.mystatus configure -cursor left_ptr]

	$pgBuddyTop.mystatus bind mystatus <<Button1>> "kill_balloon; tk_popup .my_menu %X %Y"
	$pgBuddyTop.mystatus bind mystatus <Enter> \
		+[list balloon_enter %W %X %Y $balloon_message $pic_name $fonts complex]
	$pgBuddyTop.mystatus bind mystatus <Leave> "+set Bulle(first) 0; kill_balloon"
	$pgBuddyTop.mystatus bind mystatus <Motion> \
		+[list balloon_motion %W %X %Y $balloon_message $pic_name $fonts complex]

        $pgBuddyTop.mystatus bind mypsmmedia <Enter> \
                [list ::guiContactList::underlineList $pgBuddyTop.mystatus [set underlinst(ul)] "all"]
        $pgBuddyTop.mystatus bind mypsmmedia <Leave> [list $pgBuddyTop.mystatus delete "uline_all"]
        $pgBuddyTop.mystatus bind mypsmmedia <Enter> \
                +[list $pgBuddyTop.mystatus configure -cursor hand2]
        $pgBuddyTop.mystatus bind mypsmmedia <Leave> +[list $pgBuddyTop.mystatus configure -cursor left_ptr]

        $pgBuddyTop.mystatus bind mypsmmedia <<Button1>> "kill_balloon; tk_popup .my_menu %X %Y"
        $pgBuddyTop.mystatus bind mypsmmedia <Enter> \
                +[list balloon_enter %W %X %Y $balloon_message $pic_name $fonts complex]
        $pgBuddyTop.mystatus bind mypsmmedia <Leave> "+set Bulle(first) 0; kill_balloon"
        $pgBuddyTop.mystatus bind mypsmmedia <Motion> \
                +[list balloon_motion %W %X %Y $balloon_message $pic_name $fonts complex]

	
	if {[llength [::abook::getEndPoints]] > 1} {

		create_places_menu .my_places_menu

		$pgBuddyTop.mystatus bind myplaces <<Button3>> "kill_balloon; tk_popup .my_places_menu %X %Y"

		set ep_balloon ""
		foreach ep [::abook::getEndPoints] {
			append ep_balloon "[::abook::getEndPointName $ep]\n"
		}
		
		$pgBuddyTop.mystatus bind myplaces <Enter> \
		    [list ::guiContactList::underlineList $pgBuddyTop.mystatus [set underlinst(pl)] "all"]
		$pgBuddyTop.mystatus bind myplaces <Leave> [list $pgBuddyTop.mystatus delete "uline_all"]
		$pgBuddyTop.mystatus bind myplaces <Enter> \
		    +[list $pgBuddyTop.mystatus configure -cursor hand2]
		$pgBuddyTop.mystatus bind myplaces <Leave> +[list $pgBuddyTop.mystatus configure -cursor left_ptr]
		
		$pgBuddyTop.mystatus bind myplaces <<Button1>> "kill_balloon; tk_popup .my_places_menu %X %Y"
		$pgBuddyTop.mystatus bind myplaces <Enter> \
		    +[list balloon_enter %W %X %Y $ep_balloon "" $fonts simple]
		$pgBuddyTop.mystatus bind myplaces <Leave> "+set Bulle(first) 0; kill_balloon"
		$pgBuddyTop.mystatus bind myplaces <Motion> \
		    +[list balloon_motion %W %X %Y $ep_balloon "" $fonts simple]

	}


	#Called when the window is resized
	# -> Refreshes the colorbar depending on the width of the window, and redraw the nickname, truncating as necessary
	bind $pgBuddyTop.mystatus <Configure> "::skin::getColorBar ; RedrawNick"
	
	set bbox [$pgBuddyTop.mystatus bbox all]

	#make sure we didn't get an empty string (because the status isn't visible anymore)
	if {[llength $bbox] == 4} {
		# We say +2 to let underline visible
		$pgBuddyTop.mystatus configure -width [lindex $bbox 2] -height [expr {[lindex $bbox 3]+2}]
	}
}

proc cmsn_draw_online_wrapped {} {
	variable lastLogin

	::guiContactList::unlockContactList
	#Pack what is necessary for event menu
	if { [::log::checkeventdisplay] } {
		pack configure .main.eventmenu.list -fill x -ipadx 10
		pack configure .main.eventmenu -side bottom -fill x
		pack configure .main.eventmenu -padx [list [::skin::getKey eventmenuleftpad "0"] [::skin::getKey eventmenurightpad "0"]]
		
		# clear events if login is a different account
		if {[info exists lastLogin] && $lastLogin!=[::config::getKey login]} {
			.main.eventmenu.list list delete 0 end
		}
		set lastLogin [::config::getKey login]
		
		::log::eventlogin
		.main.eventmenu.list select 0
	} else {
		pack forget .main.eventmenu
	}

}

#///////////////////////////////////////////////////////////////////////

proc configured_main_win {{w ""}} {
	global wingeom
	set w [winfo width .]
	set h [winfo height .]
	if { [lindex $wingeom 0] != $w  || [lindex $wingeom 1] != $h} {
		set wingeom [list $w $h]
		cmsn_draw_online 1 1
	}
}

proc getUniqueValue {} {
	global uniqueValue

	if {![info exists uniqueValue]} {
		set uniqueValue 0
	}
	incr uniqueValue
	return $uniqueValue
}

#///////////////////////////////////////////////////////////////////////

proc balloon_enter {window x y msg {pic ""} {fonts ""} {mode "simple"}} {
	global Bulle
	set Bulle(set) 0
	set Bulle(first) 1
	set Bulle(id) [after 1000 [list balloon ${window} ${msg} ${pic} $x $y ${fonts} ${mode}]]
}

proc balloon_motion {window x y msg {pic ""} {fonts ""} {mode "simple"}} {
	global Bulle
	if {[set Bulle(set)] == 0} {
		after cancel [set Bulle(id)]
		set Bulle(id) [after 1000 [list balloon ${window} ${msg} ${pic} $x $y ${fonts} ${mode}]]
	}
}

# trunc (str {window ""} {maxw 0 } {font ""})
#
# Truncates a string to at most nchars characters and places an ellipsis "..."
# at the end of it. nchars should include the three characters of the ellipsis.
# If the string is too short or nchars is too small, the ellipsis is not
# appended to the truncated string.
#
proc trunc {str {window ""} {maxw 0 } {font ""} {force 0}} {
	if { $window == "" || $font == "" || ([::config::getKey truncatenames]!=1 && !$force) } {
		return $str
	}

	#first check if whole message fits (increase speed)
	if { [font measure $font -displayof $window $str] < $maxw } {
		return $str
	}

	set slen [string length $str]
	for {set idx 0} { $idx <= $slen} {incr idx} {
		if { [font measure $font -displayof $window "[string range $str 0 $idx]..."] > $maxw } {
			if { [string index $str end] == "\n" } {
				return "[string range $str 0 [expr {$idx-1}]]...\n"
			} else {
				return "[string range $str 0 [expr {$idx-1}]]..."
			}
		}
	}
	return $str
}

# trunc_with_smileys (str {window ""} {maxw 0 } {font ""})
#
# The same as the previous one, but also take care of smileys
#
proc trunc_with_smileys {str {window ""} {maxw 0 } {font ""}} {
	if { $window == "" || $font == "" || [::config::getKey truncatenames]!=1} {
		return $str
	}

	#first check if whole message fits (increase speed)
	set str_list [::smiley::parseMessageToList [list [list "text" "$str"]] 1 0]
	if { [string equal [lindex [lindex $str_list 0 ] 1]  $str ]  &&\
		[font measure $font -displayof $window $str] < $maxw } {
		return $str
	}
	set indice 0
	foreach elt $str_list  {
		switch [lindex $elt 0] {
		text {
				set txt [lindex $elt 1] 
				set slen [string length $txt]
				for {set idx 0} { $idx <= $slen} {incr idx} {
					if { [font measure $font -displayof $window "[string range $txt 0 $idx]..."] > $maxw } {
						return "[string range $str 0 [expr {$indice+$idx-1}]]..."
					}
				}
				incr indice $slen
				set maxw [expr {$maxw - [font measure $font -displayof $window $txt]}]
		}
		smiley {
				set maxw [expr {$maxw - [image width [lindex $elt 1]]}]
				if {$maxw <= 0 } {
					return "[string range $str 0 [expr {$indice-1}]]..."
				}
				incr indice [string length [lindex $elt 2]]
		}
		#what should we do in that case ??? 	
		newline {}
		}
	}
	return $str
}


#returns text string to bind to a on mouse over event to trigger mouse pointer change
proc onMouseEnterHand { w } {
	if { ![info exists ::MouseLeave($w)] } {
		set ::MouseLeave($w) ""
	}
	return "+after cancel \$::MouseLeave($w); if \{\[$w cget -cursor\] != \"hand2\" \} \{$w conf -cursor hand2\}"
}

#returns text string to bind to a on mouse leave event to trigger mouse pointer change
proc onMouseLeaveHand { w } {
	if { ![info exists ::MouseLeave($w)] } {
		set ::MouseLeave($w) ""
	}
	return "+after cancel \$::MouseLeave($w); set ::MouseLeave($w) \[after 50 \"$w conf -cursor left_ptr\"\]"
}

proc tk_textCopy { w } {
	copy 0 $w
}

proc tk_textCut { w } {
	copy 1 $w
}

proc tk_textPaste { w } {
	paste $w
}


#///////////////////////////////////////////////////////////////////////
proc copy { cut w } {
	#Try this (for chat windows)
	if { [ catch {set window [::ChatWindow::GetInputText $w]} ]} { set window $w }

	set index [$window tag ranges sel]

	if { $index == "" } {
		set window [::ChatWindow::GetOutText $w]
		catch {set index [$window tag ranges sel]}
		if { $index == "" } {  return }
	}

	clipboard clear

	set dump [$window dump -text [lindex $index 0] [lindex $index 1]]

	#if { [OnLinux] } {
	#	foreach { text output index } $dump { clipboard append -type UTF8_STRING "$output" }
	#} else {
		foreach { text output index } $dump { clipboard append "$output" }
	#}
	if { $cut == "1" } { catch { $window delete sel.first sel.last } }
}
#///////////////////////////////////////////////////////////////////////



#///////////////////////////////////////////////////////////////////////
proc paste { window {middle 0} } {
	if { [catch {selection get} res] != 0 } {
		catch {
			if { [OnLinux] } {
				set contents [ selection get -type UTF8_STRING -selection CLIPBOARD ]
			} else {
				set contents [ selection get -selection CLIPBOARD ]
			}
			[::ChatWindow::GetInputText $window] insert insert $contents
		}
	} else {
		if { $middle == 0} {
			catch {
				if { [OnLinux] } {
                                	set contents [ selection get -type UTF8_STRING -selection CLIPBOARD ]
	                        } else {
        	                        set contents [ selection get -selection CLIPBOARD ]
                	        }
				[::ChatWindow::GetInputText $window] insert insert $contents
			}
		}
	}
}
#///////////////////////////////////////////////////////////////////////




#///////////////////////////////////////////////////////////////////////
proc cmsn_draw_addcontact {} {
	global lang pcc

	if {[winfo exists .addcontact]} {
		catch {
			raise .addcontact
			focus .addcontact.email
		}
		set pcc 0
		return 0
	}

	toplevel .addcontact
	wm group .addcontact .

	wm title .addcontact "[trans addacontact] - [trans title]"

	label .addcontact.l -font sboldf -text "[trans entercontactemail]:"
	entry .addcontact.email -width 50 -font splainf
	label .addcontact.example -font examplef -justify left \
		-text "[trans examples]:\ncopypastel@hotmail.com\nelbarney@msn.com\nexample@passport.com"

	frame .addcontact.group
	combobox::combobox .addcontact.group.list -editable false -highlightthickness 0 -width 22 -font splainf -exportselection false
	set groups [::groups::GetList]
	foreach gid $groups {
		.addcontact.group.list list insert end "[::groups::GetName $gid]"
	}
	.addcontact.group.list select 0
	label .addcontact.group.l -font sboldf -text "[trans group] : "
	pack .addcontact.group.l -side left
	pack .addcontact.group.list -side left

	frame .addcontact.b
	button .addcontact.b.next -text "[trans next]->" -command addcontact_next
	button .addcontact.b.cancel -text [trans cancel] \
		-command "set pcc 0; destroy .addcontact"
	bind .addcontact <<Escape>> "set pcc 0; destroy .addcontact"
	pack .addcontact.b.next .addcontact.b.cancel -side right -padx 5

	pack .addcontact.l -side top -anchor sw -padx 10 -pady 3
	pack .addcontact.email -side top -fill x -padx 10 -pady 3
	pack .addcontact.example -side top -anchor nw -padx 10 -pady 3
	pack .addcontact.group -side top -fill x -padx 10 -pady 3
	pack .addcontact.b -side top -pady 3 -expand true -fill x -anchor se

	bind .addcontact.email <Return> "addcontact_next"
	catch {
		raise .addcontact
		focus .addcontact.email
	}
}
#///////////////////////////////////////////////////////////////////////

#///////////////////////////////////////////////////////////////////////
# Check if the "add contact" window is open and then re-make the group list
proc cmsn_draw_grouplist {} {
	.addcontact.group.list list delete 0 end
	set groups [::groups::GetList]
	foreach gid $groups {
		.addcontact.group.list list insert end "[::groups::GetName $gid]"
	}
}
#///////////////////////////////////////////////////////////////////////


#///////////////////////////////////////////////////////////////////////
proc addcontact_next {} {
	set tmp_email [.addcontact.email get]
	if { $tmp_email != ""} {
		set group [.addcontact.group.list curselection]
		set gid [lindex [::groups::GetList] $group]
		::MSN::addUser "$tmp_email" "" $gid
		catch {grab release .addcontact}
		destroy .addcontact
	}
}
#///////////////////////////////////////////////////////////////////////



#///////////////////////////////////////////////////////////////////////
proc cmsn_draw_otherwindow { title command } {
	if {[winfo exists .otherwindow] } { destroy .otherwindow }
	
	toplevel .otherwindow
	wm group .otherwindow .
	wm title .otherwindow "$title"

	label .otherwindow.l -font sboldf -text "[trans entercontactemail]:"
	entry .otherwindow.email -width 50 -bd 1 \
		-font splainf

	frame .otherwindow.b
	button .otherwindow.b.ok -text "[trans ok]" \
		-command "run_command_otherwindow \"$command\""
	button .otherwindow.b.cancel -text [trans cancel]  \
		-command "grab release .otherwindow;destroy .otherwindow"

	pack .otherwindow.b.ok .otherwindow.b.cancel -side right -padx 5

	pack .otherwindow.l -side top -anchor sw -padx 10 -pady 3
	pack .otherwindow.email -side top -expand true -fill x -padx 10 -pady 3
	pack .otherwindow.b -side top -pady 3 -expand true -anchor se

	bind .otherwindow.email <Return> "run_command_otherwindow \"$command\""
	focus .otherwindow.email

	tkwait visibility .otherwindow
}
#///////////////////////////////////////////////////////////////////////


#///////////////////////////////////////////////////////////////////////
proc newcontact {new_login new_name} {
	set login [split $new_login "@ ."]
	set login [join $login "_"]
	set wname ".newc_$login"

	if { [catch {toplevel ${wname} } ] } {
		return 0
	}
	wm group ${wname} .

	wm geometry ${wname} -0+100
	wm title ${wname} "$new_name - [trans title]"

	global newc_add_to_list_${wname}
	if {[lsearch [::abook::getLists $new_login] FL] != -1} {
		set add_stat "disabled"
		set newc_add_to_list_${wname} 0
	} else {
		set add_stat "normal"
		set newc_add_to_list_${wname} 1
	}
	global newc_allow_block_${wname}
	set newc_allow_block_${wname} 1

	label ${wname}.l1 -font splainf -justify left -wraplength 300 \
		-text "[trans addedyou $new_name $new_login]"
	label ${wname}.l2 -font splainf -text "[trans youwant]:"
	radiobutton ${wname}.allow  -value "1" -variable newc_allow_block_${wname} \
		-text [trans allowseen] \
		-highlightthickness 0 \
		-activeforeground #FFFFFF -selectcolor #FFFFFF -font sboldf
	radiobutton ${wname}.block -value "0" -variable newc_allow_block_${wname} \
		-text [trans avoidseen] \
		-highlightthickness 0 \
		-activeforeground #FFFFFF -selectcolor #FFFFFF  -font sboldf
	checkbutton ${wname}.add -var newc_add_to_list_${wname} -state $add_stat \
		-text [trans addtoo] -font sboldf \
		-highlightthickness 0 -activeforeground #FFFFFF -selectcolor #FFFFFF

	frame ${wname}.b
	button ${wname}.b.ok -text [trans ok]  \
		-command [list newcontact_ok ${wname} $new_login $new_name]
	button ${wname}.b.cancel -text [trans cancel]\
		-command [list destroy ${wname}]
	pack ${wname}.b.ok ${wname}.b.cancel -side right -padx 5

	pack ${wname}.l1 -side top -pady 3 -padx 5 -anchor nw
	pack ${wname}.l2 -side top -pady 3 -padx 5 -anchor w
	pack ${wname}.allow -side top -pady 0 -padx 15 -anchor w
	pack ${wname}.block -side top -pady 0 -padx 15 -anchor w
	pack ${wname}.add -side top -pady 3 -padx 5 -anchor w
	pack ${wname}.b -side top -pady 3 -anchor se -expand true -fill x

	moveinscreen ${wname} 30
}
#///////////////////////////////////////////////////////////////////////

proc newcontact_ok { w x0 x1 } {
	global newc_allow_block_$w newc_add_to_list_$w
	set newc_allow_block [set newc_allow_block_$w]
	set newc_add_to_list [set newc_add_to_list_$w]

	if {[::config::getKey protocol] >= 13 } {
		if { [lsearch [::abook::getLists $x0] PL] != -1 } {
			::MSN::removeUserFromList $x0 PL
			::MSN::addUserToList $x0 RL
		}
		if {$newc_allow_block == "1"} {
			::MSN::unblockUser $x0
		} else {
			::MSN::blockUser $x0
		}
	} elseif { [::config::getKey protocol] == 11 } {
		if {$newc_allow_block == "1"} {
			::MSN::WriteSB ns "ADC" "AL N=$x0"
		} else {
			::MSN::WriteSB ns "ADC" "BL N=$x0"
		}
		if { [lsearch [::abook::getLists $x0] PL] != -1 } {
			#It is in the PL : move it to RL
			::MSN::WriteSB ns "ADC" "RL N=$x0"
			::MSN::WriteSB ns "REM" "PL $x0"
		}
	} else {
		if {$newc_allow_block == "1"} {
			::MSN::WriteSB ns "ADD" "AL $x0 [urlencode $x1]"
		} else {
			::MSN::WriteSB ns "ADD" "BL $x0 [urlencode $x1]"
		}
	}
	if {$newc_add_to_list} {
		::MSN::addUser $x0 [urlencode $x1]
	}

	destroy $w
}


#///////////////////////////////////////////////////////////////////////
proc cmsn_change_name {} {
	set w .change_name
	if {[winfo exists $w]} {
		raise $w
		return 0
	}

	toplevel $w
	wm group $w .
	wm title $w "[trans changenick] - [trans title]"

	frame $w.f
	label $w.f.nick_label -font sboldf -text "[trans enternick]:"
	entry $w.f.nick_entry -width 40 -font splainf
	label $w.f.nick_smiley -image [::skin::loadPixmap butsmile] -relief flat -padx 3 -highlightthickness 0
	label $w.f.nick_newline -image [::skin::loadPixmap butnewline] -relief flat -padx 3
	label $w.f.nick_textcounter -font sboldf

	label $w.f.psm_label -font sboldf -text "[trans enterpsm]:"
	entry $w.f.psm_entry -width 40 -font splainf
	label $w.f.psm_smiley -image [::skin::loadPixmap butsmile] -relief flat -padx 3 -highlightthickness 0
	label $w.f.psm_newline -image [::skin::loadPixmap butnewline] -relief flat -padx 3
	label $w.f.psm_textcounter -font sboldf

	label $w.f.p4c_label -font sboldf -text "[trans friendlyname]:"
	entry $w.f.p4c_entry -width 40 -font splainf
	label $w.f.p4c_smiley -image [::skin::loadPixmap butsmile] -relief flat -padx 3 -highlightthickness 0
	label $w.f.p4c_newline -image [::skin::loadPixmap butnewline] -relief flat -padx 3
	
	grid $w.f.nick_label -row 0 -column 0 -sticky w
	grid $w.f.nick_entry -row 0 -column 1 -sticky we
	grid $w.f.nick_smiley -row 0 -column 2
	grid $w.f.nick_newline -row 0 -column 3
	grid $w.f.nick_textcounter -row 0 -column 4
	
	if { [::config::getKey protocol] >= 11} {
		grid $w.f.psm_label -row 1 -column 0 -sticky w
		grid $w.f.psm_entry -row 1 -column 1 -sticky we
		grid $w.f.psm_smiley -row 1 -column 2
		grid $w.f.psm_newline -row 1 -column 3
		grid $w.f.psm_textcounter -row 1 -column 4
	}
	
	grid $w.f.p4c_label -row 2 -column 0 -sticky w
	grid $w.f.p4c_entry -row 2 -column 1 -sticky we
	grid $w.f.p4c_smiley -row 2 -column 2
	grid $w.f.p4c_newline -row 2 -column 3
	
	grid columnconfigure $w.f 1 -weight 1

	frame $w.fb
	button $w.fb.ok -text [trans ok] -command change_name_ok
	button $w.fb.cancel -text [trans cancel] -command [list destroy $w]
	pack $w.fb.cancel -side right -padx [list 5 0 ]
	pack $w.fb.ok -side right

	pack $w.f $w.fb -side top -fill x -expand true -padx 5
		
	bind $w <<Escape>> "destroy $w"
	bind $w.f.nick_entry <Return> "change_name_ok"
	bind $w.f.psm_entry <Return> "change_name_ok"
	bind $w.f.p4c_entry <Return> "change_name_ok"
	bind $w.f.nick_smiley <<Button1>> "focus $w.f.nick_entry; ::smiley::smileyMenu %X %Y $w.f.nick_entry"
	bind $w.f.psm_smiley <<Button1>> "focus $w.f.psm_entry; ::smiley::smileyMenu %X %Y $w.f.psm_entry"
	bind $w.f.p4c_smiley <<Button1>> "focus $w.f.p4c_entry; ::smiley::smileyMenu %X %Y $w.f.p4c_entry"
	bind $w.f.nick_newline <<Button1>> "$w.f.nick_entry insert end \"\n\""
	bind $w.f.psm_newline <<Button1>> "$w.f.psm_entry insert end \"\n\""
	bind $w.f.p4c_newline <<Button1>> "$w.f.p4c_entry insert end \"\n\""
	bind $w.f.nick_entry <Tab> "focus $w.f.psm_entry; break"
	bind $w.f.psm_entry <Tab> "focus $w.f.p4c_entry; break"
	bind $w.f.p4c_entry <Tab> "focus $w.f.nick_entry; break"

	bind $w.f.nick_entry <KeyRelease> "ChangeNameBarEdited $w nick"
	bind $w.f.psm_entry  <KeyRelease> "ChangeNameBarEdited $w psm"
	bind $w.f.nick_entry <<Button2>> "after 200 [list ::::ChangeNameBarEdited $w nick]"
	bind $w.f.psm_entry  <<Button2>> "after 200 [list ::::ChangeNameBarEdited $w psm]"

	# Make sure the smiley selector disappears with the window 
	bind $w <Destroy> { if {[winfo exists .smile_selector] } { wm state .smile_selector withdrawn }}

	set nick [::abook::getPersonal MFN]
	set psm [::abook::getPersonal PSM]
	$w.f.nick_entry insert 0 $nick
	$w.f.psm_entry insert 0 $psm
	$w.f.p4c_entry insert 0 [::config::getKey p4c_name]

	$w.f.nick_textcounter configure -text "[string length $nick]/130" -justify left
	$w.f.psm_textcounter configure -text "[string length $psm]/130" -justify left

	catch {
		raise $w
		focus -force $w.f.nick_entry
	}
	moveinscreen $w 30
}

#///////////////////////////////////////////////////////////////////////

proc ChangeNameBarEdited {w what} {
	if {$what == "nick"} {
		catch {$w.f.nick_textcounter configure -text "[string length [$w.f.nick_entry get]]/130"}
	} else {
		catch {$w.f.psm_textcounter configure -text "[string length [$w.f.psm_entry get]]/130"}
	}
}
#///////////////////////////////////////////////////////////////////////
proc change_name_ok {} {
	set nick_changed 0
	set psm_changed 0
	set new_name [.change_name.f.nick_entry get]
	if {$new_name != "" && [::abook::getContactData myself MFN] != $new_name} {
		if { [string length $new_name] > 130} {
			set answer [::amsn::messageBox [trans longnick] yesno question [trans confirm]]
			if { $answer == "no" } {
				return
			}
		}
		set nick_changed 1
	}

	if { [::config::getKey protocol] >= 11} {
		set new_psm [.change_name.f.psm_entry get]
		#TODO: how many chars in a Personal Message?
		if { [string length $new_psm] > 130} {
			set answer [::amsn::messageBox [trans longpsm] yesno question [trans confirm]]
			if { $answer == "no" } {
				return
			}
		}
		set psm_changed 1
	}
	if {$psm_changed } {
		::MSN::changePSM $new_psm [expr {!$nick_changed}]
	}
	if {$nick_changed } {
		::MSN::changeName $new_name
	}

	set friendly [.change_name.f.p4c_entry get]
	if { [string length $friendly] > 130} {
		set answer [::amsn::messageBox [trans longp4c [string range $friendly 0 129]] yesno question [trans confirm]]
		if { $answer == "no" } {
			return
		}
	}
	::config::setKey p4c_name $friendly

	destroy .change_name
}
#///////////////////////////////////////////////////////////////////////



#///////////////////////////////////////////////////////////////////////
proc Fill_users_list { path path2} {
	global emailBList

	if {![winfo exists $path] || ![winfo exists $path2]} { 
		return
	}
	# clearing the list boxes from there content
	$path.allowlist.box delete 0 end
	$path.blocklist.box delete 0 end
	$path2.contactlist.box delete 0 end
	$path2.reverselist.box delete 0 end

	foreach user [lsort [::MSN::getList AL]] {
		if {[lsearch [::abook::getLists $user] BL] == -1} {
			$path.allowlist.box insert end $user
 
			if {([lsearch [::abook::getLists $user] RL] == -1) && ([lsearch [::abook::getLists $user] FL] == -1)} {
				set colour [::skin::getKey extraprivacy_old_bg]
				set foreground [::skin::getKey extraprivacy_old_fg]
			} elseif {[lsearch [::abook::getLists $user] RL] == -1} {
				set colour [::skin::getKey extraprivacy_notrl_bg]
				set foreground [::skin::getKey extraprivacy_notrl_fg]
			} elseif {[lsearch [::abook::getLists $user] FL] == -1} {
				set colour [::skin::getKey extraprivacy_notfl_bg]
				set foreground [::skin::getKey extraprivacy_notfl_fg]
			} else {
				set colour [::skin::getKey extrastdbgcolor]
				set foreground [::skin::getKey extrastdtxtcolor]
			}
			$path.allowlist.box itemconfigure end -background $colour -foreground $foreground
		}
	}

	foreach user [lsort [::MSN::getList BL]] {
		$path.blocklist.box insert end $user

		if {([lsearch [::abook::getLists $user] RL] == -1) && ([lsearch [::abook::getLists $user] FL] == -1)} {
			set colour [::skin::getKey extraprivacy_old_bg]
			set foreground [::skin::getKey extraprivacy_old_fg]
		} elseif {[lsearch [::abook::getLists $user] RL] == -1} {
			set colour [::skin::getKey extraprivacy_notrl_bg]
			set foreground [::skin::getKey extraprivacy_notrl_fg]
		} elseif {[lsearch [::abook::getLists $user] FL] == -1} {
			set colour [::skin::getKey extraprivacy_notfl_bg]
			set foreground [::skin::getKey extraprivacy_notfl_fg]
		} else {
			set colour [::skin::getKey extrastdbgcolor]
			set foreground [::skin::getKey extrastdtxtcolor]
		}

		$path.blocklist.box itemconfigure end -background $colour -foreground $foreground
	}

	foreach user [lsort [::MSN::getList FL]] {
		$path2.contactlist.box insert end $user

		set foreground [::skin::getKey extrastdtxtcolor]

		if {[lsearch [::MSN::getList AL] $user] != -1} {
			set foreground [::skin::getKey extraprivacy_intoal_fg]
		} elseif {[lsearch [::MSN::getList BL] $user] != -1} {
			set foreground [::skin::getKey extraprivacy_intobl_fg]
		}

		if {[lsearch [::MSN::getList RL] $user] == -1} {
			set colour [::skin::getKey extraprivacy_notrl_bg]
		} else {
			set colour [::skin::getKey extrastdbgcolor]
		}

		$path2.contactlist.box itemconfigure end -background $colour -foreground $foreground
	}


	foreach user [lsort [::MSN::getList RL]] {
		$path2.reverselist.box insert end $user

		set foreground [::skin::getKey extrastdtxtcolor]

		if {[lsearch [::MSN::getList AL] $user] != -1} {
			set foreground [::skin::getKey extraprivacy_intoal_fg]
		} elseif {[lsearch [::MSN::getList BL] $user] != -1} {
			set foreground [::skin::getKey extraprivacy_intobl_fg]
		}

		if {[lsearch [::MSN::getList FL] $user] == -1} {
			set colour [::skin::getKey extraprivacy_notfl_bg]
		} else {
			set colour [::skin::getKey extrastdbgcolor]
		}
		$path2.reverselist.box itemconfigure end -background $colour -foreground $foreground
	}

}


proc create_users_list_popup { path list x y} {
	if { [$path.${list}list.box curselection] == "" } {
		$path.status configure -text "[trans choosecontact]"
	}  else {
		$path.status configure -text ""

		set user [$path.${list}list.box get active]
		set add "normal"
		set remove "normal"

		if { "$list" == "contact" } {
			set add "disabled"
		} elseif { "$list" == "reverse" } {
			set remove "disabled"
		} elseif { "$list" == "allow" } {
			# Other config to add ???
		} elseif { "$list" == "block" } {
			# Other config to add ???
		}

		if { [winfo exists $path.${list}popup] } {
			destroy $path.${list}popup
		}

		menu $path.${list}popup -tearoff 0 -type normal
		$path.${list}popup add command -label "$user" -command "clipboard clear;clipboard append $user"
		$path.${list}popup add separator
		$path.${list}popup add command -label "[trans addtocontacts]" -command "AddToContactList \"$user\" $path" -state $add
		$path.${list}popup add command -label "[trans removefromlist]" -command "Remove_from_list $list $user" -state $remove
		$path.${list}popup add command -label "[trans properties]" -command "::abookGui::showUserProperties $user"

		tk_popup $path.${list}popup $x $y
	}
}

proc AddToContactList { user path } {
	if { [NotInContactList "$user"] } {
		if {[::config::getKey protocol] >= 13 } {
			::MSN::addUser $user
		} elseif { [::config::getKey protocol] == 11 } {
			::MSN::WriteSB ns "ADC" "FL N=$user F=$user"
		} else {
			::MSN::WriteSB ns "ADD" "FL $user $user 0"
		}
	} else {
		$path.status configure -text "[trans useralreadyonlist]"
	}
}

proc Remove_from_list { list user } {
	if { "$list" == "contact" && [lsearch [::abook::getLists $user] FL] != -1 } {
		if {[::config::getKey protocol] >= 13 } {
			::MSN::deleteUser $user
		} else {
			set guid [::abook::getContactData $user contactguid]
			if { $guid != "" } {
				::MSN::WriteSB ns "REM" "FL $guid"
			}
		}
	} elseif { "$list" == "allow" && [lsearch [::abook::getLists $user] AL] != -1} {
		if {[::config::getKey protocol] >= 13 } {
			::MSN::removeUserFromList $user "AL"
		} else {
			::MSN::WriteSB ns "REM" "AL $user"
		}
	} elseif { "$list" == "block" && [lsearch [::abook::getLists $user] BL] != -1} {
		if {[::config::getKey protocol] >= 13 } {
			::MSN::removeUserFromList $user "BL"
		} else {
			::MSN::WriteSB ns "REM" "BL $user"
		}
	}
}

proc Add_To_List { path list } {
	set username [$path.adding.enter get]

	if { [string match "*@*" $username] == 0 } {
		set username [split $username "@"]
		set username "[lindex $username 0]@hotmail.com"
	}

	if { $list == "FL" } {
		AddToContactList "$username" "$path"
	} else {
		if { [::config::getKey protocol] >= 13 } {
			::MSN::addUserToList $username $list
		} elseif { [::config::getKey protocol] == 11 } {
			::MSN::WriteSB ns "ADC" "$list N=$username"
		} else {
			::MSN::WriteSB ns "ADD" "$list $username $username"
		}
	}
}

proc Reverse_to_Contact { path } {
	if { [VerifySelect $path "reverse"] } {
		$path.status configure -text ""
		set user [$path.reverselist.box get active]
		AddToContactList "$user" "$path"
	}
}

proc Remove_Contact { path } {
	if { [$path.contactlist.box curselection] == "" } {
		$path.status configure -text "[trans choosecontact]"
	}  else {
		$path.status configure -text ""
		set user [$path.contactlist.box get active]
		Remove_from_list "contact" $user
	}
}

proc Allow_to_Block { path } {
	if { [VerifySelect $path "allow"] } {
		$path.status configure -text ""
		set user [$path.allowlist.box get active]
		::MSN::blockUser "$user"
	}
}

proc Block_to_Allow  { path } {
	if { [VerifySelect $path "block"] } {
		$path.status configure -text ""
		set user [$path.blocklist.box get active]
		::MSN::unblockUser "$user"
	}
}


proc AllowAllUsers { state } {
	global list_BLP

	set list_BLP $state
	updateAllowAllUsers
}

proc updateAllowAllUsers { } {
	global list_BLP

	if { $list_BLP == 1 } {
		::MSN::WriteSB ns "BLP" "AL"
	} elseif { $list_BLP == 0} {
		::MSN::WriteSB ns "BLP" "BL"
	} else {
		return
	}
}

proc VerifySelect { path list } {
	if { [$path.${list}list.box curselection] == "" } {
		$path.status configure -text "[trans choosecontact]"
		return 0
	}  else {
		return 1
	}
}


proc NotInContactList { user } {
	if {[lsearch [::MSN::getList FL] $user] == -1} {
		return 1
	} else {
		return 0
	}
}

#saves the contactlist to a file
proc saveContacts { } {
	set w ".savecontacts"

	if { [winfo exists $w] } {
		raise $w
		return
	}

	toplevel $w
	wm title $w "[trans options]"

	frame $w.format
	radiobutton $w.format.ctt -text "[trans formatctt]" -value "ctt" -variable format
	radiobutton $w.format.csv -text "[trans formatcsv]" -value "csv" -variable format
	$w.format.ctt select
	pack configure $w.format.ctt -side top -fill x -expand true
	pack configure $w.format.csv -side top -fill x -expand true

	frame $w.button
	button $w.button.save -text "[trans save]" -command "saveContacts2"
	button $w.button.cancel -text "[trans cancel]" -command "destroy $w"
	pack configure $w.button.save -side right -padx 3 -pady 3
	pack configure $w.button.cancel -side right -padx 3 -pady 3

	pack configure $w.format -side top -fill both -expand true
	pack configure $w.button -side top -fill x -expand true
}


proc saveContacts2 { } {
	upvar 1 format format

	if { $format == "ctt" } {
		set types [list { {Messenger Contacts} {.ctt} }]
	} elseif { $format == "csv" } {
		set types [list { {Comma Seperated Values} {.csv} }]
	}
	set filename [tk_getSaveFile -filetypes $types -defaultextension ".$format" -initialfile "amsncontactlist.$format"]
	if {$filename != ""} {
		if { [string match "$filename" "*.$format"] == 0 } {
			set filename "$filename.$format"
			::abook::saveToDisk $filename $format
		}
	}

	destroy .savecontacts
}

###TODO: Replace all this msg_box calls with ::amsn::infoMsg
proc msg_box {msg} { ::amsn::infoMsg "$msg" }

############################################################
### Extra procedures that go nowhere else
############################################################


#///////////////////////////////////////////////////////////////////////
# launch_browser(url)
# Launches the configured file manager
proc launch_browser { url {local 0}} {
	if { ![regexp ^\[\[:alnum:\]\]+:// $url] && $local != 1 } {
		set url "http://$url"
	}

	if { [OnWin] && [string tolower [string range $url 0 6]] == "file://" } {
		set url [string range $url 7 end]
		regsub -all "/" $url "\\\\" url
	}

	status_log "url is $url\n"

	#status_log "Launching browser for url: $url\n"
	if { [OnWin] } {
		catch {package require WinUtils }
		if { [catch { WinLoadFile $url }] } {
			regsub -all -nocase {htm} $url {ht%6D} url
			regsub -all -nocase {&} $url {^&} url
			catch { exec rundll32 url.dll,FileProtocolHandler $url & } res
		}
	} else {
		if { [string first "\$url" [::config::getKey browser]] == -1 } {
			::config::setKey browser "[::config::getKey browser] \$url"
		}

		#if { [catch {eval exec [::config::getKey browser] [list $url] &} res ] } {}
		#status_log "Launching [::config::getKey browser]\n"
		if { [catch {eval exec [::config::getKey browser] &} res ] } {
			::amsn::errorMsg "[trans cantexec [::config::getKey browser]]"
		}
	}
}

#///////////////////////////////////////////////////////////////////////
# open_file(file)
# open the file with the environnment's default
proc open_file {file} {
	#use WinLoadFile for windows
	if { [OnWin] } {
		#replace all / with \
		regsub -all {/} $file {\\} file

		package require WinUtils
		WinLoadFile $file
	} elseif { [string length [::config::getKey openfilecommand]] < 1 } {
		msg_box "[trans checkopenfilecommand $file]"
	} else {
		if {[catch {eval exec [::config::getKey openfilecommand] &} res]} {
			status_log "[::config::getKey openfilecommand]"
			status_log $res
			::amsn::errorMsg "[trans cantexec [::config::getKey openfilecommand]]"
		}
	}
}

#///////////////////////////////////////////////////////////////////////
# launch_filemanager(directory)
# Launches the configured file manager
proc launch_filemanager {location} {
	if { [string length [::config::getKey filemanager]] < 1 } {
		msg_box "[trans checkfilman $location]"
	} else {
		#replace all / with \ for windows
		if { [OnWin] } {
			regsub -all {/} $location {\\} location
		}

		if { [string first "\$location" [::config::getKey filemanager]] == -1 } {
			::config::setKey filemanager "[::config::getKey filemanager] \$location"
		}


		if {[catch {eval exec [::config::getKey filemanager] &} res]} {
			::amsn::errorMsg "[trans cantexec [::config::getKey filemanager]]"
		}
	}
}
#///////////////////////////////////////////////////////////////////////

#///////////////////////////////////////////////////////////////////////
# launch_mailer(directory)
# Launches the configured mailer program
proc launch_mailer {recipient} {
	global password

	if {[string length [::config::getKey mailcommand]]==0} {
		::hotmail::composeMail $recipient
			return 0
	}

	if { [string first "\$recipient" [::config::getKey mailcommand]] == -1 } {
		::config::setKey mailcommand "[::config::getKey mailcommand] \$recipient"
	}


	if { [catch {eval exec [::config::getKey mailcommand] &} res]} {
		::amsn::errorMsg "[trans cantexec [::config::getKey mailcommand]]"
	}
	return 0
}
#///////////////////////////////////////////////////////////////////////


#///////////////////////////////////////////////////////////////////////
# toggle_status()
# Enabled/disables status window (for debugging purposes)
proc toggle_status {} {
	set w .status
	if {"[wm state $w]" == "normal"} {
		wm state $w withdrawn
		set status_show 0
	} else {
		wm state $w normal
		set status_show 1
		raise $w
		focus $w.enter
	}
}
#///////////////////////////////////////////////////////////////////////


#///////////////////////////////////////////////////////////////////////
# timestamp()
# Returns a timestamp like [HH:MM:SS]
proc timestamp {} {
	set stamp [clock format [clock seconds] -format %H:%M:%S]
	return "[::config::getKey leftdelimiter]$stamp[::config::getKey rightdelimiter]"
}
#///////////////////////////////////////////////////////////////////////


#///////////////////////////////////////////////////////////////////////////////
# status_log (text,[color])
# Logs the given text with a timestamp using the given color
# to the status window
proc status_log {txt {colour ""}} {
	global followtext_status queued_status
#	return

	#ensure txt ends in a newline
	if { [string index $txt end] != "\n" } {
		set txt "$txt\n"
	}

	if { [catch {
		#puts -nonewline "[timestamp] $txt"

		.status.info insert end "[timestamp] $txt" $colour
		.status.info delete 0.0 end-1000lines
		if { $followtext_status == 1 } {
			catch {.status.info yview end}
		}
	}]} {
		lappend queued_status [list $txt $colour]
	}
}
#///////////////////////////////////////////////////////////////////////////////



if { [info command ::tk::exit] == "" && [info command exit] == "exit" } {
	rename exit ::tk::exit
}

#///////////////////////////////////////////////////////////////////////
# close_cleanup()
# Makes some cleanup and config save before closing
proc exit {} {
	global HOME lockSock
	catch { ::MSN::logout}

	# if there is a container
	if { [info exists ::ChatWindow::containers] } {
		foreach { key value } [array get ::ChatWindow::containers] {
			::ChatWindow::CloseAll $value
		}
	}
	if { [info exists ::ChatWindow::windows] } {
		foreach { value } [array get ::ChatWindow::windows] {
			#cycle in every window and destroy it
			#force the destroy
			set ::ChatWindow::recent_message($value) 0
			::ChatWindow::Close $value
		}
	}

	::config::setKey wingeometry [wm geometry .]

	save_config
	::config::saveGlobal

	#before quitting, unload plugins, so that they run their DeInit proc
	#we unload plugins at that moment and not before, since save_config
	#would have saved wrong plugins config because no plugin would have been
	#loaded at that moment
	::plugins::UnLoadPlugins

	LoadLoginList 1
	# Unlock current profile
	LoginList changelock 0 [::config::getKey login] 0
	if { [info exists lockSock] } {
		if { $lockSock != 0 } {
			catch {close $lockSock} res
		}
	}
	SaveLoginList
	SaveStateList

	close_dock    ;# Close down the dock socket
	catch {file delete [file join $HOME hotlog.htm]} res
	# As suggested by Joe English, letting the idler do the exit is better since it lets the C stack unwind
	# into a safer state.. would resolve possible segfaults on exit.. 
	# other alternative is to use 'destroy .' instead of 'exit'.. especially when it's called from a -command option of a menu entry

	# ok.. more info.. we shouldn't rename 'exit' at all.. argh :s and we should never call exit, 
	# we should call 'destroy .' whenever we want to exit the program...
	# and we should bind this cleanup procedure to the <Destroy> even of the '.' window... 
	# for now, I'll leave it like that.. 
	after idle ::tk::exit
}
#///////////////////////////////////////////////////////////////////////



#///////////////////////////////////////////////////////////////////////
# idleCheck()
# Check idle every five seconds and reset idle if the mouse has moved
proc idleCheck {} {
	global idletime oldmousepos trigger autostatuschange

	set mousepos [winfo pointerxy .]
	if { $mousepos != $oldmousepos } {
		set oldmousepos $mousepos
		set idletime 0
	}

	# Check for empty fields and use 5min by default
	if {[::config::getKey awaytime] == ""} { ::config::setKey awaytime 10 }
	if {[::config::getKey idletime] == ""} { ::config::setKey idletime 5 }

	if { [string is digit [::config::getKey awaytime]] && [string is digit [::config::getKey idletime]] } {
		#Avoid running this if the settings are not digits, which can happen while changing preferences
		set second [expr {[::config::getKey awaytime] * 60}]
		set first [expr {[::config::getKey idletime] * 60}]

		set changed 0

		if { $idletime >= $second && [::config::getKey autoaway] == 1 && \
			(([::MSN::myStatusIs] == "IDL" && $autostatuschange == 1) || \
			([::MSN::myStatusIs] == "NLN"))} {
			#We change to Away if time has passed, and if IDL was set automatically
			::MSN::changeStatus AWY
			set autostatuschange 1

			set changed "AWY"
		} elseif {$idletime >= $first && [::MSN::myStatusIs] == "NLN" && [::config::getKey autoidle] == 1} {
			#We change to idle if time has passed and we're online
			::MSN::changeStatus IDL
			set autostatuschange 1

			set changed "IDL"
		} elseif { $idletime == 0 && $autostatuschange == 1} {
			#We change to only if mouse movement, and status change was automatic
			::MSN::changeStatus NLN
			#Status change always resets automatic change to 0

			set changed "NLN"
		}

		if { $changed != "0" } {
			#PostEvent 'ChangeMyState' when the user changes his/her state
			set evPar(automessage) $::automessage
			set evPar(idx) $changed
			::plugins::PostEvent ChangeMyState evPar
		}
	}

	set idletime [expr {$idletime + 5}]
	after 5000 idleCheck
}
#///////////////////////////////////////////////////////////////////////


#///////////////////////////////////////////////////////////////////////
proc choose_theme { } {
	setColor . . background {-background -highlightbackground}
}
#///////////////////////////////////////////////////////////////////////



#///////////////////////////////////////////////////////////////////////
proc setColor {w button name options} {
	catch {grab $w}
	set initialColor [$button cget -$name]
	set color [tk_chooseColor -title "[trans choosebgcolor]" -parent $w \
		-initialcolor $initialColor]
	if { $color != "" } {
		::config::setKey backgroundcolor $color
		::themes::ApplyDeep $w $options $color
	}
	catch {grab release $w}
}
#///////////////////////////////////////////////////////////////////////




#given a string, this proc returns, as a list, the positions (first and end) of any URL in this string.
proc urlParserString { str } {
	set list2return [list]
	set pos 0
	set url_indices {}
	#this regexp is a bit complex, but it reaches all URLs as specified in the RFC 1738 on http://www.ietf.org/rfc/rfc1738.txt
	while { [regexp -start $pos -indices {(\w+)://([\%\/\$\*\~\,\!\'\#\.\@\+\-\=\?\;\:\^\&\_[:alnum:]]+)} $str url_indices ] } {
		set pos [lindex $url_indices 1]
		lappend list2return [lindex $url_indices 0] $pos
	}
	set pos 0
	while { [regexp -start $pos -indices {www.([\%\/\$\*\~\,\!\'\#\.\@\+\-\=\?\;\:\^\&\_[:alnum:]]+)} $str url_indices ] } {
		set pos [lindex $url_indices 1]
		set pos_start [lindex $url_indices 0]
		#check if the url was not found before
		if { ![regexp :// [string range $str [expr {$pos_start - 3}] $pos ] ]} {
			lappend list2return $pos_start $pos
		}
	}
	return $list2return
}


#///////////////////////////////////////////////////////////////////////
proc show_umenu {user_login grId x y} {
	set blocked [::MSN::userIsBlocked $user_login]
	#clear the menu
	.user_menu delete 0 end

	set statecode [::abook::getVolatileData $user_login state FLN]
	set mobile [expr {[::abook::getContactData $user_login MOB] == "Y"}]

	#Add the first item, depending on what's possible
	if {[::MSN::userIsNotIM ${user_login}]} {
		.user_menu add command -label "[trans sendmail] ($user_login)" \
			-command "launch_mailer ${user_login}"
		set first "[trans sendmail] ($user_login)"
	} elseif {$statecode != "FLN"} {
		.user_menu add command -label "[trans sendmsg] ($user_login)" \
			-command "::amsn::chatUser ${user_login}"
		set first "[trans sendmsg] ($user_login)"
	} elseif { $mobile == 1 } {
		.user_menu add command -label "[trans sendmobmsg] ($user_login)" \
			-command "::MSNMobile::OpenMobileWindow ${user_login}"
		set first "[trans sendmobmsg] ($user_login)"
		.user_menu add command -label "[trans sendoim] ($user_login)" \
			-command "::amsn::chatUser $user_login; set ::OIM_GUI::oim_asksend_[string map {: _} ${user_login} ] 0"
	} else {

		.user_menu add command -label "[trans sendoim] ($user_login)" \
			-command "::amsn::chatUser $user_login; set ::OIM_GUI::oim_asksend_[string map {: _} ${user_login} ] 0"
		.user_menu add command -label "[trans sendmail] ($user_login)" \
			-command "launch_mailer $user_login"
		set first "[trans sendoim] ($user_login)"
	}
	
	#here comes the actions submenu if more then 3 extra actions are defined.  We add all the core actions here, plugins can add actions later, and after plugins are done we chack how much actions there are.  If more then 3, the submenu is added, esle, all acitons are copied in the root menu over here.	
	set actions .user_menu.actionssubmenu
	if {[winfo exists $actions]} { destroy $actions }
	menu $actions -tearoff 0 -type normal


	if {[::MSN::userIsNotIM ${user_login}] } {
		$actions add command -label "[trans addtocontacts]" \
		    -command "::MSN::addUser ${user_login}"
	} else {
		#add mobile if it's not already the default action
		#	mobile is default when offline and a mobile account is set up
		if {$mobile == 1 && $statecode != "FLN"} {
			$actions add command -label "[trans sendmobmsg]" \
			    -command "::MSNMobile::OpenMobileWindow ${user_login}"	
		}
		#add e-mail if it's not already the default action	
		#	e-mail is default when offline and no mobile account set up
		if { !($mobile != 1 && $statecode == "FLN")} {
			$actions add command -label "[trans sendmail]" \
			    -command "launch_mailer $user_login"
		}
	}
	
	#view profile action			
	.user_menu add command -label "[trans viewprofile]" \
		-command "::hotmail::viewProfile [list ${user_login}]"		
			
	#-----------------------
	.user_menu add separator

	#The url-actions
	set the_nick [::abook::getNick ${user_login}]
	set the_psm [::abook::getpsmmedia $user_login]
	#parse nick and PSM in the same time.
	set nickpsm "${the_nick} ${the_psm}"
	set url_indices [urlParserString "$nickpsm"]
	for {set i 0} {$i<[llength $url_indices]} {incr i} {
		set pos_start [lindex $url_indices $i ]
		incr i
		set pos [lindex $url_indices $i ]
		set urltext [string range $nickpsm $pos_start $pos]
		.user_menu add command -label "[trans goto ${urltext} ] " \
		-command "launch_browser [list $urltext]"
		.user_menu add command -label "[trans copytoclipboard \"${urltext}\"]" \
		-command "clipboard clear;clipboard append \"${urltext}\""
		#end with a separator:
		#-----------------------
		.user_menu add separator
	}

	#chat history
	.user_menu add command -label "[trans history]" \
		-command "::log::OpenLogWin ${user_login}"
	#webcam history
	.user_menu add command -label "[trans webcamhistory]" \
	    -command "::log::OpenCamLogWin ${user_login}" 

	#-----------------------
	.user_menu add separator

	if {![::MSN::userIsNotIM ${user_login}] } {
		#block/unblock
		if {$blocked == 0} {
			.user_menu add command -label "[trans block]" -command  "::amsn::blockUser ${user_login}"
		} else {
			.user_menu add command -label "[trans unblock]" \
			    -command  "::amsn::unblockUser ${user_login}"
		}
	}

	#move/copy
	::groups::updateMenu menu .user_menu.move_group_menu ::groups::menuCmdMove [list $grId $user_login]
	::groups::updateMenu menu .user_menu.copy_group_menu ::groups::menuCmdCopy $user_login

	#check if user is in a virtual group
	set grIdV 1
	foreach group [::guiContactList::getGroupList 1] {
		if { [lindex $group 0] == $grId } {
			set grIdV 0
			break
		}
	}

	if {$grIdV} {
		.user_menu add cascade -label "[trans movetogroup]"  -state disabled
		.user_menu add cascade -label "[trans copytogroup]"  -state disabled
		.user_menu add command -label "[trans removefromgroup]"  -state disabled
	} else {
		.user_menu add cascade -label "[trans movetogroup]" -menu .user_menu.move_group_menu
		#you may not copy a contact from "no group" to a normal group
		if { $grId == 0 } {
			.user_menu add cascade -label "[trans copytogroup]"  -state disabled
			.user_menu add command -label "[trans removefromgroup]"  -state disabled
		} else {
			.user_menu add cascade -label "[trans copytogroup]" -menu .user_menu.copy_group_menu
			.user_menu add command -label "[trans removefromgroup]" -command [list ::amsn::removeUserFromGroup $user_login $grId]
		}	
	}

	#delete, if in a normal group, only from current group, otherwise from all groups and FL
	.user_menu add command -label "[trans delete]" -command [list ::amsn::deleteUser $user_login]

	#-----------------------
	.user_menu add separator
	.user_menu add command -label "[trans cfgalarm]" -command "::abookGui::showUserProperties $user_login; .user_[::md5::md5 $user_login]_prop.nb raise alarms"
	.user_menu add command -label "[trans properties]" \
	-command "::abookGui::showUserProperties $user_login"

	# PostEvent 'right_menu'
	set evPar(menu_name) .user_menu
	set evPar(user_login) ${user_login}
	::plugins::PostEvent right_menu evPar

	#check if the actions-submenu contains 3 or more items.  If not, add those items to the root menu.	
	set nrofactions [$actions index end]
	#index starts counting at 0, this means "less then 3 items"

	set start [expr [.user_menu index $first] + 1]
	if {$nrofactions < 2 }  {
		for {set i 0} {$i <= $nrofactions} {incr i} {
			eval .user_menu insert $start [$actions type $i]
			foreach option [$actions entryconfigure $i] {
#FIXME				#why is the value the last item in this list ?
				.user_menu entryconfigure $start [lindex $option 0] [lindex $option end]
			}
			incr start
		}
	} elseif { $nrofactions == "none"} {
		#menu is empty
	} else {
		#3 or more actions are defines, add the submenu
		.user_menu insert $start cascade -label "[trans moreactions]" -menu $actions
	}

	kill_balloon
	
	tk_popup .user_menu $x $y
}

#///////////////////////////////////////////////////////////////////////
proc run_command_otherwindow { command } {
	set tmp [.otherwindow.email get]
	if { $tmp != "" } {
		eval $command [list $tmp]
		destroy .otherwindow
	}
}
#///////////////////////////////////////////////////////////////////////

proc BossMode { } {
	global bossMode BossMode

	if { [info exists bossMode] == 0 } {
		set bossMode 0
	}

	if { $bossMode == 0 } {
		set children [winfo children .]

		if { [catch { toplevel .bossmode } ] } {
			set bossMode 0
			set children ""
		} else {
			wm title .bossmode "[trans pass]"

			label .bossmode.passl -text "[trans pass]"
			entry .bossmode.pass -show "*" -validate key -vcmd {expr {[string length %P]<=16} }
			pack .bossmode.passl .bossmode.pass -side left

			#updatebossmodetime
			bind .bossmode.pass <Return> "BossMode"

			if { [WinDock] } {
				wm state .bossmode withdraw
				wm protocol .bossmode WM_DELETE_WINDOW "wm state .bossmode withdraw"
				catch {wm iconbitmap .bossmode [::skin::GetSkinFile winicons bossmode.ico]}
			} else {
				wm protocol .bossmode WM_DELETE_WINDOW "BossMode"
			}
			statusicon_proc "BOSS"
		}

		foreach child $children {
			if { "$child" == ".bossmode" } {continue}

			if { [catch { wm state "$child" } res ] } {
				status_log "$res\n"
				continue
			}
			if { [wm overrideredirect "$child"] == 0 } {
				set BossMode($child) [wm state "$child"]
				wm state "$child" normal
				wm state "$child" withdraw
			}
		}

		if { "$children" != "" } {
			set BossMode(.) [wm state .]
			wm state . normal
			wm state . withdraw

			set bossMode 1

		}
	} elseif { $bossMode == 1 && [winfo exists .bossmode]} {
		if { [.bossmode.pass get] != [set ::password] } {
			return
		}

		set children [winfo children .]

		foreach child $children {
			if { [catch { wm state "$child" } res ] } {
				status_log "$res\n"
				continue
			}

			if { "$child" == ".bossmode" } {continue}

			if { [wm overrideredirect "$child"] == 0 } {
				wm state "$child" normal

				if { [info exists BossMode($child)] } {
					wm state "$child" "$BossMode($child)"
				}
			}
		}

		wm state . normal

		if { [info exists BossMode(.)] } {
			wm state . $BossMode(.)
		}

		set bossMode 0
		destroy .bossmode

		statusicon_proc [::MSN::myStatusIs]
	}
}

proc updatebossmodetime { } {
	.bossmode.time configure -text "[string map { \" "" } [clock format [clock seconds] -format \"%T\"]]"
	#" Just to fix some editors syntax hilighting
	after 1000 updatebossmodetime
}

proc window_history { command w } {
	global win_history

	set HISTMAX 100

	set new [info exists win_history(${w}_count)]

	catch {
		if { [winfo class $w] == "Text" } {
			set zero 0.0
		} else {
			set zero 0
		}
	}

	switch $command {
		add {
			if { [winfo class $w] == "Text" } {
				set msg "[$w get 0.0 end-1c]"
			} else  {
				set msg "[$w get]"
			}

			if { $msg != "" } {
				if { $new } {
					set idx $win_history(${w}_count)
				} else {
					set idx 0
				}

				if { $idx == $HISTMAX } {
					set win_history(${w}) [lrange $win_history(${w}) 1 end]
					lappend win_history(${w}) "$msg"
					set win_history(${w}_index) $HISTMAX
					return
				}

				set win_history(${w}_count) [expr {$idx + 1}]
				set win_history(${w}_index) [expr {$idx + 1}]
				#		set win_history(${w}_${idx}) "$msg"
				lappend win_history(${w}) "$msg"

			}
		}
		clear {

			if {! $new } { return -1}

			# 	    foreach histories [array names win_history] {
			# 		if { [string match "${w}*" $histories] } {
			# 		    unset win_history($histories)
			# 		}
			# 	    }
			catch {
				unset win_history(${w}_count)
				unset win_history(${w}_index)
				unset win_history(${w})
				unset win_history(${w}_temp)
			}
		}
		previous {
			if {! $new } { return -1}
			set idx $win_history(${w}_index)
			if { $idx ==  0 } { return -1}


			if { $idx ==  $win_history(${w}_count) } {
				if { [winfo class $w] == "Text" } {
					set msg "[$w get 0.0 end-1c]"
				} else  {
					set msg "[$w get]"
				}
				set win_history(${w}_temp) "$msg"
			}

			incr idx -1
			set win_history(${w}_index) $idx

			$w delete $zero end
			#	    $w insert $zero "$win_history(${w}_${idx})"
			$w insert $zero "[lindex $win_history(${w}) $idx]"
		}
		next {
			if {! $new } { return -1}
			set idx $win_history(${w}_index)
			if { $idx ==  $win_history(${w}_count) } { return -1}

			incr idx
			set win_history(${w}_index) $idx
			$w delete $zero end
			#	    if {! [info exists win_history(${w}_${idx})] } { }
			if { $idx ==  $win_history(${w}_count) } {
					$w insert $zero "$win_history(${w}_temp)"
			} else {
				#		$w insert $zero "$win_history(${w}_${idx})"
				$w insert $zero "[lindex $win_history(${w}) $idx]"
			}

		}
	}
}



########################################################################
#### ALL ABOUT CONVERTING AND CHOOSING DISPLAY PICTURES
########################################################################

# Converts the given $filename to the given size, and leaves
# xx.png and xxx.gif in the given destination directory
proc convert_image { filename destdir size } {
	set filetail [file tail $filename]
	set filetail_noext [filenoext $filetail]

	set tempfile [file join $destdir $filetail]
	set destfile [file join $destdir $filetail_noext]

	if { ![file exists $filename] } {
		status_log "Tring to convert file $filename that does not exist\n" error
		return ""
	}
	if { [catch {::picture::IsAnimated $filename} res] } {
		#The image is surely bad so don't try to load it maybe a bad FT
		#I don't think we should warn the user : annoying when it's due to bad DP of a contact
		status_log $res
		return
	}
	if { $res } {
		#We are animated so we just convert it
		status_log "converting animation $filename to $tempfile\n"
		if {[catch {::picture::Convert $filename ${destfile}.png} res]} {
			msg_box $res
			return
		}
	} else {
		status_log "converting $filename to $tempfile with size $size\n"
		#Separe the size X and Y in 2 variables
		set sizexy [split $size "x" ]
		if { [lindex $sizexy 1] == "" } {
			set sizex [lindex $sizexy 0]
			set sizey [lindex $sizexy 0]
		} else {
			set sizex [lindex $sizexy 0]
			set sizey [lindex $sizexy 1]
		}
	
		#Create img from the file
		if {[catch {set img [image create photo [TmpImgName] -file $filename -format cximage]} res]} {
			#If there's an error, it means the filename is corrupted, remove it
			catch { file delete $filename }
			catch { file delete [filenoext $filename].dat }
			#As the image couldn't ne loaded we can't destroy it :)
			return
		}
		#Resize with ratio
		if {[catch {::picture::ResizeWithRatio $img $sizex $sizey} res]} {
			image delete $img
			msg_box $res
			return
		}
		#Save in PNG
		if {[catch {::picture::Save $img ${destfile}.png cxpng} res]} {
			image delete $img
			msg_box $res
			return
		}

		image delete $img
	}

	return ${destfile}.png
}

proc convert_image_plus { filename type size } {
	global HOME
	catch { create_dir [file join $HOME $type]}
	return [convert_image $filename [file join $HOME $type] $size]
}




proc load_my_pic { } {
	global pgBuddyTop
	if { [::config::getKey displaypic] == "" } {
		::config::setKey displaypic nopic.gif
	}
	set dpfilename [PathRelToAbs [::config::getKey displaypic]]
	status_log "load_my_pic: Trying to set display picture $dpfilename\n" blue
	if {[file readable [::skin::GetSkinFile displaypic $dpfilename]]} {
		if { ![catch {image create photo displaypicture_std_self -file "[::skin::GetSkinFile displaypic $dpfilename]" -format cximage}] } {
			load_my_smaller_pic
		} else {
			# Image corrupted on disk
			image delete $dpfilename
			::config::setKey displaypic nopic.gif 
		}
	} else {
		status_log "load_my_pic: Picture not found!!\n" red
		clear_disp
	}
}
#Create a smaller display picture from the bigger one
proc load_my_smaller_pic {} {
	if { [ImageExists displaypicture_not_self]} {
		displaypicture_not_self blank
	}
	image create photo displaypicture_not_self -format cximage
	if { [catch {displaypicture_not_self copy displaypicture_std_self}] } {
		displaypicture_not_self copy [::skin::getNoDisplayPicture]
	}
	::picture::ResizeWithRatio displaypicture_not_self 50 50
}

proc clear_disp { } {
	global pgBuddyTop

	::config::setKey displaypic nopic.gif

	if { [catch {image create photo displaypicture_std_self -file "[::skin::GetSkinFile displaypic nopic.gif]" -format cximage}] } {
		image create photo displaypicture_std_self
	}
	load_my_smaller_pic
}


proc pictureBrowser {} {
	dpBrowser
}

proc dpBrowser { {target_user "self" } } {
	global HOME

	package require dpbrowser
	

	set w .dpbrowser
	#if it already exists, create the window, otherwise, raise it
	if { [winfo exists $w] } {
		raise $w
		return
	}
	toplevel $w
	wm minsize $w 480 10
	wm title $w "[trans picbrowser]"
		
	#Get all the contacts
	set contact_list [list]
	foreach contact [::abook::getAllContacts] {
		#Selects the contacts who are in our list and adds them to the contact_list
		if {[string last "FL" [::abook::getContactData $contact lists]] != -1} {
			lappend contact_list $contact
		}
	}
	#Sorts contacts
	set contactlist [lsort -dictionary $contact_list]
	
	# Select current DP (custom or not) for target user
	if { $target_user != "self" } {
		if { [::abook::getContactData $target_user customdp ""] != "" } {
			set image_name [::abook::getContactData $target_user customdp ""]
		} else {
			set image_name [::abook::getContactData $target_user displaypicfile ""]
		}
		if {$image_name != ""} {
			set selected_path [file join $HOME displaypic cache $target_user [filenoext $image_name].png]
		} else {
			set selected_path ""
		}
	} else {
		set selected_path [displaypicture_std_self cget -file]
	}
	
	################
	# First column #
	################
	frame $w.leftpane
	frame $w.leftpane.mydpstitle -bd 0
	label $w.leftpane.mydpstitle.text -text "[trans mypics]:" -font bboldf
	#clear cache button ?
	pack $w.leftpane.mydpstitle.text -side left

	frame $w.leftpane.moredpstitle -bd 0
	label $w.leftpane.moredpstitle.text -text "[trans cachedpicsfor]:" -font bboldf
	#combobox to choose user which configures the widget with -user $user

	set combo $w.leftpane.moredpstitle.combo
	combobox::combobox $combo -highlightthickness 0 -width 22  -font splainf -exportselection true -command "configureDpBrowser $target_user" -editable false
	$combo list delete 0 end
	$combo list insert end "[trans selectcontact]"
	
	set i 1
	foreach contact $contactlist {
		#put the name of the device in the widget
		$combo list insert end $contact
		if {$contact == $target_user} {
			set selection $i
		}
		incr i
	}
	$combo list insert end "[trans otherdps]"
	
	# If we are choosing a custom DP for a contact, show his cache in the lower pane
	if {$target_user == "self"} {
		catch {$combo select 0}
		set selected_user ""
	} else {
		catch {$combo select $selection}
		set selected_user $target_user
	}

	pack $w.leftpane.moredpstitle.text -side left
	pack $w.leftpane.moredpstitle.combo -side right

	::dpbrowser $w.leftpane.mydps -width 3 -mode "both" -invertmatch 0 -firstselect $selected_path \
		-command [list updateDpBrowserSelection $w.leftpane.mydps $target_user] -user self

	::dpbrowser $w.leftpane.moredps -width 3 -mode "both" -invertmatch 0 -firstselect $selected_path \
		-command [list updateDpBrowserSelection $w.leftpane.moredps $target_user] -user $selected_user
	
	#################
	# second column #
	#################
	frame $w.rightpane
	#preview
	label $w.rightpane.dppreviewtxt -text "[trans preview]:"
	if { $selected_path == "" || [catch {image create photo displaypicture_pre_$target_user -file $selected_path -format cximage}] } {
		image create photo displaypicture_pre_$target_user -file [[::skin::getNoDisplayPicture] cget -file] -format cximage
	}
	label $w.rightpane.dppreview -image displaypicture_pre_$target_user

	
	#browse button
	button $w.rightpane.browsebutton -command "pictureChooseFile $target_user" -text "[trans browse]..."
	
	#under this button is space for more buttons we'll make a frame for so plugins can pack stuff in this frame
	frame $w.rightpane.pluginsframe -bd 0

	set evPar(target) $target_user
	set evPar(win) $w.rightpane.pluginsframe
	::plugins::PostEvent xtra_choosepic_buttons evPar

	#################
	# lower pane    #
	#################
	frame $w.lowerpane -bd 0
	button $w.lowerpane.ok -text "[trans ok]" -command "applyDP $target_user;destroy $w"
	button $w.lowerpane.cancel -text "[trans cancel]" -command "destroy .dpbrowser"


	#################
	# packing       #
	#################

	pack $w.lowerpane.ok $w.lowerpane.cancel -side right -padx 5
	pack $w.lowerpane -side bottom -fill x

	pack $w.rightpane.dppreviewtxt $w.rightpane.dppreview $w.rightpane.browsebutton $w.rightpane.pluginsframe -fill x
	pack $w.rightpane -side right -fill y

	pack $w.leftpane.mydpstitle -fill x
	pack $w.leftpane.mydps -expand true -fill both
	pack $w.leftpane.moredpstitle -fill x
	pack $w.leftpane.moredps -expand true -fill both
	pack $w.leftpane -side left -fill both -expand true

	bind $w.rightpane.dppreview <Destroy> "catch { image delete displaypicture_pre_$target_user }"
}

proc configureDpBrowser {target combowidget selection} {
	set invert_match 0
	if {$selection == "[trans selectcontact]"} {
		set selection ""
	}
	if {$selection == "[trans otherdps]"} {
		#Get all the contacts
		set contact_list [list]
		foreach contact [::abook::getAllContacts] {
			#Selects the contacts who are in our list and adds them to the contact_list
			if {[string last "FL" [::abook::getContactData $contact lists]] != -1} {
				lappend contact_list $contact
			}
		}
		set invert_match 1
		set selection $contact_list
	}
	[winfo toplevel $combowidget].leftpane.moredps configure -invertmatch $invert_match -user $selection
}

# This procedure is called back from the dpbrowser pane when a picture is selected
proc updateDpBrowserSelection { browser target } {
	set w [winfo toplevel $browser]
	set file [lindex [$browser getSelected] 1]

	set old_image [$w.rightpane.dppreview cget -image]
	$w.rightpane.dppreview configure -image ""
	catch {image delete $old_image}
	if {$file == ""} {
		set file [[::skin::getNoDisplayPicture] cget -file]
	}
	$w.rightpane.dppreview configure -image [image create photo displaypicture_pre_$target -file $file -format cximage]
	if {"$browser" == "$w.leftpane.mydps"} {
		$w.leftpane.moredps deSelect
	} else {
		$w.leftpane.mydps deSelect
	}
}

#proc chooseFileDialog {basename {initialfile ""} {types {{"All files"         *}} }} {}
proc chooseFileDialog { {initialfile ""} {title ""} {parent ""} {entry ""} {operation "open"} {types {{ "All Files" {*} }} }} {
	if { $parent == "" || ![winfo exists $parent] } {
		catch {set parent [focus]}
		if { $parent == "" } {
			set parent "."
		}
	}

	global  starting_dir

	if { ![file isdirectory $starting_dir] } {
		set starting_dir [pwd]
	}

	if { $operation == "open" } {
		if {![file exists $initialfile]} {
			set initialfile ""
		}
		set selfile [tk_getOpenFile -filetypes $types -parent $parent -initialdir $starting_dir -initialfile $initialfile -title $title]
	} else {
		set selfile [tk_getSaveFile -filetypes $types -parent $parent -initialdir $starting_dir -initialfile $initialfile -title $title]
	}
	if { $selfile != "" } {
		#Remember last directory
		set starting_dir [file dirname $selfile]

		if { $entry != "" } {
			$entry delete 0 end
			$entry insert 0 $selfile

			# Next line has caused some problems with an old Tile version
			catch { $entry xview end }
		}
	}

	return $selfile
}





proc pictureChooseFile { target } {

	set file [chooseFileDialog "" "" "" "" open [list [list [trans imagefiles] [list *.gif *.GIF *.jpg *.JPG *.jpeg *.JPEG *.bmp *.BMP *.png *.PNG]] [list [trans allfiles] *]]]
	setDPFromFile $target $file

}

proc setDPFromFile { target file } {
	global HOME
	if { $file != "" } {
		set convertsize "96x96"
		if { [catch {::picture::GetPictureSize $file} cursize] } {
			status_log "Error opening $file: $cursize\n"
			msg_box $cursize
			return ""
		}
		if { $cursize != "96x96" && ![::picture::IsAnimated $file] } {
			set convertsize [AskDPSize $cursize]
		}

		if { ![catch {convert_image_plus $file displaypic $convertsize} res]} {
			if {![winfo exists .dpbrowser]} {
				dpBrowser
			}

			image create photo displaypicture_pre_$target -file [::skin::GetSkinFile "displaypic" "[filenoext [file tail $file]].png"] -format cximage
			.dpbrowser.rightpane.dppreview configure -image displaypicture_pre_$target
			set desc_file "[filenoext [file tail $file]].dat"
			set fd [open [file join $HOME displaypic $desc_file] w]
			status_log "Writing description to $desc_file\n"
#			puts $fd "[clock format [clock seconds] -format %x]\n[filenoext [file tail $file]].png"
			puts $fd "[clock seconds]\n[filenoext [file tail $file]].png"
			close $fd
			
			# Redraw dpBrowser's upper pane
			.dpbrowser.leftpane.mydps configure -user self
			
			return "[filenoext [file tail $file]].png"
		} else {
			status_log "Error converting $file: $res\n"
		}
	}

	return ""
}

#Window created to choose if we should use another size (other than 96x96) for display picture
proc AskDPSize { cursize } {
	global done dpsize

	if {[winfo exists .askdpsize]} {
		return "96x96"
	}

	toplevel .askdpsize

	set dpsize "96x96"
	set done 0

	label .askdpsize.lwhatsize -text [trans whatsize] -font splainf
	frame .askdpsize.rb

	radiobutton .askdpsize.rb.retain -text [trans original] -value $cursize -variable dpsize
	radiobutton .askdpsize.rb.huge -text [trans huge] -value "192x192" -variable dpsize
	radiobutton .askdpsize.rb.large -text [trans large] -value "128x128" -variable dpsize
	radiobutton .askdpsize.rb.default -text [trans default2] -value "96x96" -variable dpsize
	radiobutton .askdpsize.rb.small -text [trans small] -value "64x64" -variable dpsize

	button .askdpsize.okb -text [trans ok] -command "set done 1" -default active
	button .askdpsize.cancelb -text [trans cancel] -command "destroy .askdpsize" -default normal

	pack .askdpsize.lwhatsize -side top -anchor w -pady 10 -padx 10
	pack .askdpsize.rb.retain -side top -anchor w
	pack .askdpsize.rb.huge -side top -anchor w
	pack .askdpsize.rb.large -side top -anchor w
	pack .askdpsize.rb.default -side top -anchor w
	pack .askdpsize.rb.small -side top -anchor w

	pack .askdpsize.rb -side top -padx 10 -pady 10
	pack .askdpsize.okb .askdpsize.cancelb -side right -padx 10

	wm title .askdpsize [trans displaypic]
	moveinscreen .askdpsize 30
	vwait done

	destroy .askdpsize
	status_log "User requested pic size $dpsize\n"
	return $dpsize
}

proc applyDP { { email "self" } } {
	set file ""
	catch {set file [displaypicture_pre_$email cget -file]}
	if { $file == [[::skin::getNoDisplayPicture] cget -file] } {
		# Some skin add a dat file for nopic.gif too, so it's selectable
		# Check this is not the case
		if {[lindex [.dpbrowser.leftpane.mydps getSelected] 1] == ""} {
			set file ""
		}
	}
	set_displaypic $file $email
}

proc set_displaypic { file { email "self" } } {
	if { $email == "self" } {
		if { $file != "" } {
			::config::setKey displaypic $file
			status_log "set_displaypic: File set to $file\n" blue
			load_my_pic
			::MSN::changeStatus [set ::MSN::myStatus]
			save_config
		} else {
			status_log "set_displaypic: Setting displaypic to [::skin::getNoDisplayPicture]\n" blue
			clear_disp
			::MSN::changeStatus [set ::MSN::myStatus]
		}
		::MSN::updateDP
	} else {
		global customdp_$email
		set customdp_$email $file
	}
}

proc saveFile {filename} {
	set name [file tail $filename]
	set newfilename [chooseFileDialog "$name" "[trans save]" "" "" save]
	catch {file copy $filename $newfilename}
}

###################### Protocol Debugging ###########################
if { $initialize_amsn == 1 } {
	global degt_protocol_window_visible degt_command_window_visible

	set degt_protocol_window_visible 0
	set degt_command_window_visible 0
}

proc hexify_all { str } {
	set out ""
	for {set i 0} { $i < [string length $str] } { incr i} {
		set c [string range $str $i $i]
		binary scan $c H* h
		append out "\[$h\]"
	}
	set out
}
proc hexify { str } {
	set out ""
	for {set i 0} { $i < [string length $str] } { incr i} {
		set c [string range $str $i $i]
		if {[string is ascii $c] && (![string is control $c] || $c == "\r" || $c == "\n") } {
			append out $c
		} else {
			binary scan $c H* h
			append out "\[$h\]"
		}
	}
	set out
}
proc hexify_c { str } {
	set out "{"
	for {set i 0} { $i < [string length $str] } { incr i} {
		set c [string range $str $i $i]
		binary scan $c H* h
		append out "0x$h"

		if {[expr {$i+1}] < [string length $str] } {
			append out ","
			if {[expr {$i % 4}] == 3} {
				append out "\n"
			} else {
				append out " "
			}
		}
	}
	append out "}"
	set out
}

proc unhexify { str } {
	set out "" 
	for { set i 0 } { $i < [string length $str] } { incr i } {
		if {[string range $str $i $i] == "\[" &&
		    [string length $str] > [expr {$i + 3}]  &&
		    [string range $str [expr {$i + 3}] [expr {$i + 3}]] == "\]" } {
			set d1 [string range $str [expr {$i + 1}] [expr {$i + 1}]]
			set d2 [string range $str [expr {$i + 2}] [expr {$i + 2 }]]
			if {([string is digit $d1] || $d1 == "a" || $d1 == "b" ||
			     $d1 == "c" || $d1 == "d" || $d1 == "e" || $d1 == "f") || 
			    ([string is digit $d2] || $d2 == "a" || $d2 == "b" ||
			     $d2 == "c" || $d2 == "d" || $d2 == "e" || $d2 == "f")} {
				append out [binary format H* "${d1}${d2}"]
				incr i 3
			} else {
				append out "\[${d1}${d2}\]"
			}
		} else {
			append out [string range $str $i $i]
		}
	}
	return $out
}


proc degt_protocol { str {colour ""}} {
	global followtext_degt
#	return
	.degt.mid.txt insert end "[timestamp] [hexify $str]\n" $colour
	.degt.mid.txt delete 0.0 end-1000lines
	if { $followtext_degt == 1} {
		.degt.mid.txt yview end
	}
}

proc degt_protocol_win_toggle {} {
	global degt_protocol_window_visible

	if { $degt_protocol_window_visible } {
		wm state .degt withdraw
		set degt_protocol_window_visible 0
	} else {
		wm state .degt normal
		set degt_protocol_window_visible 1
		raise .degt
	}
}

proc degt_protocol_win { } {
	global followtext_degt

	set followtext_degt 1

	toplevel .degt
	wm title .degt "MSN Protocol Debug"
	wm iconname .degt "MSNProt"
	wm state .degt withdraw

	frame .degt.top -class Degt
		label .degt.top.name -text "Protocol" -justify left -font sboldf
		pack .degt.top.name -side left -anchor w

	#font create debug -family Verdana -size 24 -weight bold
	frame .degt.mid -class Degt

	text   .degt.mid.txt -height 20 -width 85 -font splainf \
		-wrap none -background white -foreground black \
		-yscrollcommand ".degt.mid.sy set" \
		-xscrollcommand ".degt.mid.sx set"
	scrollbar .degt.mid.sy -command ".degt.mid.txt yview"
	scrollbar .degt.mid.sx -orient horizontal -command ".degt.mid.txt xview"

	.degt.mid.txt tag configure error -foreground #ff0000
	.degt.mid.txt tag configure nssend -foreground #888888
	.degt.mid.txt tag configure nsrecv -foreground #000000
	.degt.mid.txt tag configure sbsend -foreground #006666
	.degt.mid.txt tag configure sbrecv -foreground #000088
	.degt.mid.txt tag configure msgcontents -foreground #004400
	.degt.mid.txt tag configure red -foreground red
	.degt.mid.txt tag configure white -foreground white -background black
	.degt.mid.txt tag configure blue -foreground blue

	pack .degt.mid.sy -side right -fill y
	pack .degt.mid.sx -side bottom -fill x
	pack .degt.mid.txt -anchor nw  -expand true -fill both

	pack .degt.mid -expand true -fill both

	checkbutton .degt.follow -text "[trans followtext]" -onvalue 1 -offvalue 0 -variable followtext_degt -font sboldf

	frame .degt.bot -relief sunken -borderwidth 1 -class Degt
	button .degt.bot.save -text [trans savetofile] -command degt_protocol_save
		button .degt.bot.clear  -text [trans clear] \
			-command ".degt.mid.txt delete 0.0 end"
		button .degt.bot.close -text [trans close] -command degt_protocol_win_toggle
		pack .degt.bot.save .degt.bot.close .degt.bot.clear -side left

	pack .degt.top .degt.mid .degt.follow .degt.bot -side top

	bind . <Control-d> { degt_protocol_win_toggle }
	wm protocol .degt WM_DELETE_WINDOW { degt_protocol_win_toggle }
}

proc degt_ns_command_win_toggle {} {
    global degt_command_window_visible

    if { $degt_command_window_visible } {
	wm state .nscmd withdraw
	set degt_command_window_visible 0
    } else {
	wm state .nscmd normal
	set degt_command_window_visible 1
    }
}

proc degt_protocol_save { } {
	set w .protocol_save

	toplevel $w
	wm title $w [trans savetofile]
	label $w.msg -justify center -text [trans enterfilename]
	pack $w.msg -side top

	frame $w.buttons -class Degt
	pack $w.buttons -side bottom -fill x -pady 2m
	button $w.buttons.dismiss -text [trans cancel] -command "destroy $w"
	button $w.buttons.save -text [trans save] -command "degt_protocol_save_file $w.filename.entry; destroy $w"
	pack $w.buttons.save $w.buttons.dismiss -side left -expand 1

	frame $w.filename -bd 2 -class Degt
	entry $w.filename.entry -relief sunken -width 40
	label $w.filename.label -text "[trans filename]:"
	pack $w.filename.entry -side right
	pack $w.filename.label -side left
	pack $w.msg $w.filename -side top -fill x
	focus $w.filename.entry

	chooseFileDialog "protocol_log.txt" "" $w $w.filename.entry save
	catch {grab $w}
}

proc degt_protocol_save_file { filename } {
	set fd [open [${filename} get] a+]
	fconfigure $fd -encoding utf-8
	puts $fd "[.degt.mid.txt get 0.0 end]"
	close $fd
}

# Ctrl-M to toggle raise/hide. This window is for developers only
# to issue commands manually to the Notification Server
proc degt_ns_command_win {} {
	if {[winfo exists .nscmd]} {
		return
	}

	toplevel .nscmd
	wm title .nscmd "MSN Command"
	wm iconname .nscmd "MSNCmd"
	wm state .nscmd withdraw
	frame .nscmd.f -class Degt
	label .nscmd.f.l -text "NS Command:" -font bboldf
	entry .nscmd.f.e -width 20
	pack .nscmd.f.l .nscmd.f.e -side left
	pack .nscmd.f

	bind .nscmd.f.e <Return> {
		set cmd [string trim [.nscmd.f.e get]]
		if { [string length $cmd] > 0 } {
		# There is actually a command typed. If %T found in
		# the string replace it by a transaction ID
		set nsclst [split $cmd]
		set nscmd [lindex $nsclst 0]
		set nspar [lreplace $nsclst 0 0]
		# Send command to the Notification Server
		::MSN::WriteSB ns $nscmd $nspar
		}
	}
	wm protocol .nscmd WM_DELETE_WINDOW { degt_ns_command_win_toggle }
}



namespace eval ::OIM_GUI {
	
	#Most of this code is from the MSNMobile namespace from protocol.tcl

	#TODO:
	# * fix all pending bugs !

    namespace export IsOIM MessageSend MessagesReceived OpenOIMWindow

	
	#TODO:when we write a message to a CW, it should do the same as WLM, try to open an SB, if the CAL answer is 207 (user is offline, cannot join chat), then send the OIM
	#use a list of such users ......
	#Have a look at proc chatUser (gui.tcl, ~2540)
	proc IsOIM {user} {
		if {[::abook::getVolatileData $user state] == "FLN" && ![::MSN::chatReady [GetChatId $user]] } {
			return 1
		} else {
			return 0
		}
	}

	proc MessageSendCallback { chatid error } {
		if {![string match *success* $error]} {
			::amsn::WinWriteFail $chatid "($error)"
		}
	}

	proc MessageSend { chatid txt } {
		set email $chatid
		status_log "sending OIM to $chatid" green
		if { ![info exists ::OIM_GUI::oim_asksend_[string map {: _} ${chatid} ] ] } {
			set ::OIM_GUI::oim_asksend_[string map {: _} ${chatid} ] 1
		}
		
		# should fix issue with automessages from alarms since the window is
		# not yet created and the user has just gone offline
		# in that case, should we send the message ?  ask to send the message ? 
		# for the moment we send it without asking
		set window [::ChatWindow::For $chatid]
		if {[config::getKey no_oim_confirmation 0] == 0 &&
		    [set ::OIM_GUI::oim_asksend_[string map {: _} ${chatid} ]] &&
		    $window != 0} {
			set answer [::amsn::messageBox [trans asksendoim] yesno question ""  $window]
		} else {
			set answer "yes"
		}

		if { $answer == "yes"} {
			set ::OIM_GUI::oim_asksend_[string map {: _} ${chatid} ] 0
			::MSNOIM::sendOIMMessage [list ::OIM_GUI::MessageSendCallback $chatid] $email $txt
		}
		return $answer
    }

	proc deleteOIMCallback {oim_messages success} {
		if { $success == 0 } {
			status_log "\[OIM\]Unable to delete messages for OIMs : $oim_messages" white
		} else {
			status_log "\[OIM\]Successfully deleted OIMs : $oim_messages" green
		}
	
	}

	proc MessagesReceivedCallback { oim_messages email nick MsgId oimlist oim_message } {
		if { $oim_message == "" } { 
			status_log "\[OIM\]Unable to fetch message from $nick <$email>; MsgId is $MsgId"
		} else {
			lappend oimlist $oim_message
		}

		if { [llength $oim_messages] > 0} {
			foreach {email nick MsgId} [lindex $oim_messages 0] break
			::MSNOIM::getOIMMessage [list ::OIM_GUI::MessagesReceivedCallback [lrange $oim_messages 1 end] $email $nick $MsgId $oimlist] $MsgId
		} else {
			#No more messages to grab
			#oldest are first
			set sorted_oims [lsort -command SortOIMs $oimlist]
			set to_delete [list]
			foreach oim_message $sorted_oims {
				if { [DisplayOIM $oim_message] } {
					lappend to_delete [lindex $oim_message 4]
				}
			}

			if {[llength $to_delete] > 0 } {
				::MSNOIM::deleteOIMMessage [list ::OIM_GUI::deleteOIMCallback $to_delete] $to_delete
			}
		}
	}

    proc MessagesReceived { oim_messages } {
		if { [llength $oim_messages] > 0} {
			foreach {email nick MsgId} [lindex $oim_messages 0] break
			::MSNOIM::getOIMMessage [list ::OIM_GUI::MessagesReceivedCallback [lrange $oim_messages 1 end] $email $nick $MsgId [list]]  $MsgId
		}

    }

	#oldest are first
	proc SortOIMs { oim1 oim2 } {
		#an oim is [list $sequence $email $nick $body $mid $runId]
		set seq1 [lindex $oim1 0]
		set seq2 [lindex $oim2 0]
		if {$seq1 > $seq2 } {
			return 1
		} elseif {$seq1 < $seq2 } {
			return -1
		} else {
			#should never happen
			return 0
		}
	}

	proc DisplayOIM {oim_message} {
		#an oim_message is [list $sequence $email $nick $body $mid $runId]
		set user [lindex $oim_message 1]
		set nick [lindex $oim_message 2]
		set msg [lindex $oim_message 3]
		set MsgId [lindex $oim_message 4]
		set arrivalTime [lindex $oim_message 6]
		set unixtimestamp 0

		#convert the arrival time
		set pos [string first . $arrivalTime]
		incr pos -1
		set arrivalTime [string range $arrivalTime 0 $pos]
		set unixtimestamp [clock scan $arrivalTime -gmt 1]

		set dateformat [string tolower [::config::getKey dateformat]]
		set part1 [string index $dateformat 0 ]
		set part2 [string index $dateformat 1 ]
		set part3 [string index $dateformat 2 ]
		if { [catch { set str "[ clock format $unixtimestamp -format "%$part1/%$part2/%$part3 %T"]"} ] } {
			#the timestamp is maybe corrupted, don't display it
			status_log "\[DisplayOIM\] timestamp =  $timestamp seems corrupted, or ::config::getKey dateformat = [::config::getKey dateformat] is corrupted" white
			set unixtimestamp 0
			set tstamp ""
		} else {
			set tstamp [::config::getKey leftdelimiter]
			append tstamp $str
			append tstamp [::config::getKey rightdelimiter]
		}
		
		set chatid [GetChatId $user]

		if { $chatid == 0 } {
			if {$user == "" } {
				return 0
			}
			# 1 means we want to display an OIM
			::amsn::chatUser $user 1
			#TODO: use the normal way to get the chatid
			set chatid [GetChatId $user]
		}
		status_log "Writing offline msg \"$msg\" on : $chatid\n" red

		set customchatstyle [::config::getKey customchatstyle]
		switch [::config::getKey chatstyle] {
			msn {
				if {$unixtimestamp} {
					set customchatstyle "\$tstamp [trans says \$nick]: \$newline"
				} else {
					set customchatstyle "[trans says \$nick]: \$newline"

				}
			}
			irc {
				if {$unixtimestamp} {
					set customchatstyle "\$tstamp <\$nick> "
				} else {
					#timestamp is wrong
					set customchatstyle "<\$nick> "
				}
			}
			- {}
		}

		#By default, quote backslashes and variables
		set customchatstyle [string map {"\\" "\\\\" "\$" "\\\$" "\(" "\\\(" } $customchatstyle]
		#Now, let's unquote the variables we want to replace
		set customchatstyle [string map { "\\\$nick" "\${nick}" "\\\$tstamp" "\${tstamp}" "\\\$newline" "\n" } $customchatstyle]
		#Return the custom nick, replacing backslashses and variables
		set customchatstyle [subst -nocommands $customchatstyle]
		
		set custommsg "\n${customchatstyle}${msg}"
		SendMessageFIFO [list ::amsn::WinWrite $chatid "$custommsg" user] "::amsn::messages_stack($chatid)" "::amsn::messages_flushing($chatid)"

		#We	should add an event for sending message
		#loging
		if {[::config::getKey keep_logs]} {
			::log::PutLog $chatid $nick $msg "" 0 $tstamp
		}
		return 1
	}

    proc OpenOIMWindow { user } {
		set chatid [GetChatId $user]
		status_log "opening chat window for offline messaging : $chatid\n" red

		if { $chatid == 0 } {
			set win [::ChatWindow::Open]
			set chatid "$user"
			::ChatWindow::SetFor $chatid $win
			
			if { [winfo exists .bossmode] } {
				set ::BossMode(${win_name}) "normal"
				wm state $win withdraw
			} else {
				wm state $win normal
			}

			wm deiconify $win
		} else {
			set win [::ChatWindow::For $chatid]
			if { [winfo exists .bossmode] } {
				set ::BossMode(${win_name}) "normal"
				wm state $win withdraw
			} else {
				wm state $win normal
			}

			wm deiconify $win
			focus $win
		}
    }

    proc GetChatId { user } {
			set chatid $user
			set win [::ChatWindow::For $chatid]
			if {$win != 0 && [winfo exists $win] } {
				return $chatid
			} else {
				return 0
			}
    }

}



#///////////////////////////////////////////////////////////////////////////////
# if a button has a -image, -relief flat but not -overrelief, it will actually be created as a label
# this is a workaround for platforms like macos and tileqt which have a problem with buttons (like
# not honouring "-relief flat" (tileqt) or not supporting alpha transparancy(macos))
# TODO: add a bind that works as -command on a button (mousebutton press, move away, release does not trigger)
# apply buttons2labels on Mac, because there seem to be problems with buttons there
# TODO: as soon as it is fixed in tk on mac, make it version-conditional
snit::widgetadaptor buttonlabel {
	option -command -default ""
	option -overrelief -default ""
	option -repeatdelay -default ""
	option -repeatinterval -default ""
	option -default -default ""
		
	delegate option * to hull

	constructor {args} {
		installhull using label
		$self configurelist $args

		bind $self <<Button1>> [list $self _LabelClicked]
	}

	method _LabelClicked { } {
		return [$self invoke]
	}
	
	method invoke { } {
		if {[$self cget -state] != "disabled" } {
			eval $options(-command)
		} else {
			return ""
		}
	}
	method flash { } {
		
	}
}
	
proc buttons2labels { } {
	if { [info commands ::tk::button2] == "" } {
		rename button ::tk::button2
	}
	proc button { pathName args } {
		array set options $args
		if { [info exists options(-image)] &&
		     [info exists options(-relief)] && $options(-relief) == "flat" } {
			eval buttonlabel [list $pathName] [array get options]
		} else {
			eval ::tk::button2 [list $pathName] $args
		}
	}
}

if { $initialize_amsn == 1 } {
	if {[OnMac] } {
		buttons2labels
	}
}
