#!/usr/bin/wish

########################################################################
##             skins.tcl - aMSN Skins System (0.95B)                  ##
##  ----------------------------------------------------------------  ##
##   If you want to add any option to skins system, please, be sure   ##
##    of commenting out your code and keep your values in a proper    ##
##      section of settings.xml, so the system remains coherent       ##
########################################################################

namespace eval ::skin {

	variable preview_skin_change 0

	################################################################
	# ::skin::getKey (key, [default])
	# This procedure get the value of a skin's configuration key
	# supplied by $key and returns it. If the given key doesn't
	# exists, it will return $default if supplied, or "" if not.
	# Arguments:
	#  - key => The requested skin's configurarion key.
	#  - default => [NOT REQUIRED] the fallback value.
	proc getKey {key {default ""}} {
		if { [info exists ::skin_setting($key)] } {
			return [::set ::skin_setting($key)]
		} else {
			status_log "OOPS, trying to get a setting that don't exists: $key\n" red
			return $default
		}
	}


	################################################################
	# ::skin::setKey (key, value)
	# This procedure assigns a value (supplied by $value) to a 
	# skin's configuration key supplied by $key. It returns nothing.
	# Arguments:
	#  - key => The name of the skin's configurarion key.
	#  - value => The data assigned to $key
	proc setKey {key value} {
		::set ::skin_setting($key) $value
	}


	################################################################
	# ::skin::InitSkinDefaults ()
	# Here we set every data wich depends on skins to default, so we
	# can load a skin without problems.
	proc InitSkinDefaults { } {
		global emoticon_number emotions emotions_names emotions_data
		set emoticon_number 0
		set emotions_names [list]
		if { [info exists emotions] } {unset emotions}
		if { [info exists emotions_data] } {unset emotions_data}

		::skin::setKey bigstate_xpad 0
		::skin::setKey bigstate_ypad 3
		
		::skin::setKey mystatus_xpad 5
		::skin::setKey mystatus_ypad 0
		
		::skin::setKey mailbox_xpad 5
		::skin::setKey mailbox_ypad 0
		
		::skin::setKey contract_xpad 5
		::skin::setKey contract_ypad 0
		
		::skin::setKey expand_xpad 5
		::skin::setKey expand_ypad 0
		
	}


	################################################################
	# ::skin::setPixmap (pixmap_name, pixmap_file)
	# This procedure sets the image name -- file name association 
	# in order to load pictures on demand.
	# Arguments:
	#  - pixmap_name => Name of the image resource to be used in amsn
	#  - pixmap_file => The image file
	proc setPixmap {pixmap_name pixmap_file} {
		variable pixmap_names
		set pixmap_names($pixmap_name) $pixmap_file
	}


	################################################################
	# ::skin::loadPixmap (pixmap_name)
	# Checks if the image was previously loaded, or we need to load
	# it. This way, the pixmaps will be loaded first time they're 
	# used, on demand. It returns the image resource to be used.
	# Arguments:
	#  - pixmap_name => Name of the image resource to be used in amsn
	proc loadPixmap {pixmap_name} {
		# Check if pixmap is already loaded
		variable loaded_pixmaps
		if { [info exists loaded_pixmaps($pixmap_name)] } {
			return $loaded_pixmaps($pixmap_name)
		}

		# Not loaded, so let's load it
		variable pixmap_names
		if { ! [info exists pixmap_names($pixmap_name) ] } {
			return ""
		}

		set loaded_pixmaps($pixmap_name) [image create photo -file [::skin::GetSkinFile pixmaps $pixmap_names($pixmap_name)] -format gif]
		return $loaded_pixmaps($pixmap_name)
	}


	################################################################
	# ::skin::getNoDisplayPicture ([skin_name])
	# Checks if the image was previously loaded, or we need to load
	# it. This way, the no_pic will be loaded first time it's used.
	# It always returns 'no_pic', is always the same name (static).
	# Arguments:
	#  - skin_name => [NOT REQUIRED] Overrides the current skin.
	proc getNoDisplayPicture { {skin_name ""} } {
		variable loaded_images
		if { [info exists loaded_images(no_pic)] } {
			return no_pic
		}
		image create photo no_pic -file [::skin::GetSkinFile displaypic nopic.gif $skin_name] -format gif
		set loaded_images(no_pic) 1
		return no_pic
	}


	################################################################
	# ::skin::getColorBar ([skin_name])
	# Creates the special image that is placed below of the nickname
	# in the contacts' list. It returns the image resource.
	# Arguments:
	#  - skin_name => [NOT REQUIRED] Overrides the current skin.
	proc getColorBar { {skin_name ""} } {
		# Get the contact list width
		global pgBuddy
		set width [expr {[winfo width $pgBuddy.text]} - 1 ]
		if { $width < 160 } {
			set width 160
		}

		# Delete old mainbar, and load colorbar
		# The colorbar will be loaded as follows:
		# [first 10 px][11th px repeating to fill][the rest of the colorbar]
		catch {image delete mainbar}

		set barheight [image height [loadPixmap colorbar]]
		set barwidth [image width [loadPixmap colorbar]]
		set barendwidth [expr $barwidth - 11]
		set barendstart [expr $width - $barendwidth]
	
		# Create the color bar copying from the pixmap
		image create photo mainbar -width $width -height $barheight
		mainbar blank
		mainbar copy [loadPixmap colorbar] -from 0 0 10 $barheight
		mainbar copy [loadPixmap colorbar] -from 10 0 11 $barheight -to 10 0 $barendstart $barheight
		mainbar copy [loadPixmap colorbar] -from [expr $barwidth - $barendwidth] 0 $barwidth $barheight -to $barendstart 0 $width $barheight

		return mainbar
	}


	################################################################
	# ::skin::loadSound (sound_name)
	# Checks if sound_name is loaded and loads it if it isn't.
	# This function is for the Snack Library.
	# Arguments:
	#  - sound_name => The filename of the desired sound.
	proc loadSound {sound_name} {
		variable loaded_sounds

		if { [info exists loaded_sounds($sound_name)] } {
			return snd_$sound_name
		}

		snack::sound snd_$sound_name -file [::skin::GetSkinFile sounds $sound_name]
		set loaded_sounds($sound_name) 1

		return snd_$sound_name
	}


	################################################################
	# ::skin::reloadSkin (skin_name)
	# This procedure reloads everything that depends on skins.
	# Arguments:
	#  - skin_name => The new skin to switch on.
	proc reloadSkin { skin_name } {
		reloadSkinSettings $skin_name

		# Reload all pixmaps
		variable loaded_pixmaps
		variable pixmap_names
		foreach name [array names loaded_pixmaps] {
			image create photo $loaded_pixmaps($name) -file [::skin::GetSkinFile pixmaps $pixmap_names($name) $skin_name] -format gif
		}

		# Reload smileys
		variable loaded_smileys
		variable smiley_names
		foreach name [array names loaded_smileys] {
			image create photo $loaded_smileys($name) -file [::skin::KeySkinFile smileys $smiley_names($name) $skin_name] -format gif
		}

		# Now reload special images that need special treatment
		variable loaded_images
		if {[info exists loaded_images(no_pic)]} {
			unset loaded_images(no_pic)
			::skin::getNoDisplayPicture $skin_name
		}
		if {[info exists loaded_images(colorbar)]} {
			unset loaded_images(colorbar)
			::skin::getColorBar $skin_name
			# This statment is required for update the colorbar in realtime (without waiting for resizing contact list).
			# Should be removed when the new contact list comes out.
			if { [::MSN::myStatusIs] != "FLN" } { cmsn_draw_online }
		}

		# Reload sounds
		variable loaded_sounds
		foreach name [array names loaded_sounds] {
			snd_$name configure -file [::skin::GetSkinFile sounds $name]
		}

		# Change frame color (For All Platforms except Mac)
		if {[catch {tk windowingsystem} wsystem] || $wsystem != "aqua"} {
			catch {.main configure -background [::skin::getKey mainwindowbg]}
		}
	}


	################################################################
	# ::skin::reloadSkinSettings (skin_name)
	# This procedure loads the XML file of the new skin and applies
	# its changes.
	# Arguments:
	#  - skin_name => The new skin to switch on.
	proc reloadSkinSettings { skin_name } {
		# Set defaults
		::skin::InitSkinDefaults
	
		# Load smileys info from default skin first
		set skin_id [sxml::init [::skin::GetSkinFile "" settings.xml default]]
		sxml::register_routine $skin_id "skin:smileys:emoticon" ::smiley::newEmoticon
		sxml::register_routine $skin_id "skin:smileys:size" ::skin::SetEmoticonSize
		sxml::parse $skin_id
		sxml::end $skin_id
		
		# Then reload the real skin
		set skin_id [sxml::init [::skin::GetSkinFile "" settings.xml $skin_name]]

		if { $skin_id == -1 } {
			::amsn::errorMsg "[trans noskins]"
			exit
		}

		set ::loading_skin $skin_name
		sxml::register_routine $skin_id "skin:Information" ::skin::SetSkinInfo
		sxml::register_routine $skin_id "skin:General:Colors" ::skin::SetConfigKeys
		sxml::register_routine $skin_id "skin:General:Geometry" ::skin::SetConfigKeys
		sxml::register_routine $skin_id "skin:General:Options" ::skin::SetConfigKeys
		sxml::register_routine $skin_id "skin:ContactList:Colors" ::skin::SetConfigKeys
		sxml::register_routine $skin_id "skin:ContactList:Geometry" ::skin::SetConfigKeys
		sxml::register_routine $skin_id "skin:ContactList:Options" ::skin::SetConfigKeys
		sxml::register_routine $skin_id "skin:ChatWindow:Colors" ::skin::SetConfigKeys
		sxml::register_routine $skin_id "skin:ChatWindow:Geometry" ::skin::SetConfigKeys
		sxml::register_routine $skin_id "skin:ChatWindow:Options" ::skin::SetConfigKeys
		sxml::register_routine $skin_id "skin:smileys:emoticon" ::smiley::newEmoticon
		sxml::register_routine $skin_id "skin:smileys:size" ::skin::SetEmoticonSize
		sxml::parse $skin_id
		sxml::end $skin_id
		unset ::loading_skin

		if { [winfo exists .smile_selector]} {destroy .smile_selector}
	}


	################################################################
	# ::skin::SetEmoticonSize (cstack cdata saved_data cattr saved_attr args)
	# Sets the default smiley size for this skin. Arguments supplied
	# by the XML parser.
	proc SetEmoticonSize {cstack cdata saved_data cattr saved_attr args} {
		upvar $saved_data sdata

		if { [info exists sdata(${cstack}:smilew)] } { ::skin::setKey smilew [string trim $sdata(${cstack}:smilew)] }
		if { [info exists sdata(${cstack}:smileh)] } { ::skin::setKey smileh [string trim $sdata(${cstack}:smileh)] }

		return 0
	}


	################################################################
	# ::skin::GetSkinFile (type, filename, [skin_override])
	# Forms the path to the desired filename and returns it.
	# Arguments:
	#  - type => The subdir in skins/ (pixmaps, sounds, smileys...)
	#  - filename => The desired filename (for example, online.gif)
	#  - skin_override => [NOT REQUIRED] Use this skin instead of current
	proc GetSkinFile { type filename {skin_override ""} } {
		global HOME2 HOME

		if { [catch { set skin "[::config::getGlobalKey skin]" } ] != 0 } {
			set skin "default"
		}

		if { $skin_override != "" } {
			set skin $skin_override
		}
		set defaultskin "default"

		#Get file using global path
		if { "[string range $filename 0 0]" == "/" && [file readable  $filename] } {
			return "$filename"
		#Get file from program dir skins folder
		} elseif { [file readable [file join [set ::program_dir] skins $skin $type $filename]] } {
			return "[file join [set ::program_dir] skins $skin $type $filename]"
		#Get file from ~/.amsn/skins folder
		} elseif { [file readable [file join $HOME2 skins $skin $type $filename]] } {
			return "[file join $HOME2 skins $skin $type $filename]"
		#Get file from ~/.amsn/profile/skins folder
		} elseif { [file readable [file join $HOME skins $skin $type $filename]] } {
			return "[file join $HOME skins $skin $type $filename]"
		#Get file from default skin
		} elseif { [file readable [file join [set ::program_dir] skins $defaultskin $type $filename]] } {
			return "[file join [set ::program_dir] skins $defaultskin $type $filename]"
		} else {
			return "[file join [set ::program_dir] skins $defaultskin $type null]"
		}
	}


	################################################################
	# ::skin::SetSkinInfo (cstack cdata saved_data cattr saved_attr args)
	# Gets the information of the skin from the XML file and puts it
	# in global variable $skin. Arguments supplied by the XML parser.
	proc SetSkinInfo {cstack cdata saved_data cattr saved_attr args} {
		global skin
		upvar $saved_data sdata

		foreach key [array names sdata] {
			set skin([string range $key [expr [string length $cstack] + 1] [string length $key]]) [string trim $sdata($key)]
		}

		return 0
	}


	################################################################
	# ::skin::FindSkins ()
	# It looks for all the skins with a settings.xml file that it can
	# find and adds them to a list. When it finish, it returns the list.
	proc FindSkins { } {
		global HOME HOME2

		set skins [glob -directory skins */settings.xml]
		set skins_in_home [glob -nocomplain -directory [file join $HOME skins] */settings.xml]
		set skins_in_home2 [glob -nocomplain -directory [file join $HOME2 skins] */settings.xml]
		set skins [concat $skins $skins_in_home $skins_in_home2]
		set skinlist [list]

		foreach skin $skins {
			set dir [file dirname $skin]
			set desc ""

			if { [file readable [file join $dir desc.txt] ] } {
				set fd [open [file join $dir desc.txt]]
				set desc [string trim [read $fd]]
				close $fd
			}

			set lastslash [expr {[string last "/" $dir]+1}]
			set skinname [string range $dir $lastslash end]
			lappend skinname $desc
			lappend skinlist $skinname
		}

		return $skinlist
	}


	################################################################
	# ::skin::SetConfigKeys (cstack cdata saved_data cattr saved_attr args)
	# This procedure loads the skin's data from settings.xml into
	# the proper variables. Arguments supplied by the XML parser.
	proc SetConfigKeys {cstack cdata saved_data cattr saved_attr args} {
		upvar $saved_data sdata
		foreach key [array names sdata] {
			::skin::setKey [string range $key [expr [string length $cstack] + 1] [string length $key]] [string trim $sdata($key)]
		}

		# This bits are used to override certain keys loaded before with specific values for MacOS X (TkAqua)
		# Don't use buttonbarbg on Mac OS X and put 0 value to chatborders.
		if { ![catch {tk windowingsystem} wsystem] && $wsystem == "aqua" } {
			if { [info exists sdata(${cstack}:chatwindowbg)] } { ::skin::setKey buttonbarbg [string trim $sdata(${cstack}:chatwindowbg)] }
				::skin::setKey chat_top_border 0
				::skin::setKey chat_output_border 0
				::skin::setKey chat_buttons_border 0
				::skin::setKey chat_input_border 0
				::skin::setKey chat_status_border 0
				::skin::setKey chat_top_pady 0
				::skin::setKey chat_status_pady 0
				::skin::setKey chat_paned_pady 0
		}

		# Procedures binded to the XML parser must ALWAYS return 0
		return 0
	}
}

namespace eval ::skinsGUI {


	################################################################
	# ::skinsGUI::SelectSkin ()
	# This procedure creates the skins selector window and shows it.
	proc SelectSkin { } {
		set w .skin_selector

		if { [winfo exists $w] } {
			focus $w
			raise $w
			return
		}

		toplevel $w
		wm resizable $w 0 0
		wm title $w "[trans chooseskin]"
		wm geometry $w +100+100

		label $w.choose -text "[trans chooseskin]" -font bboldf
		pack $w.choose -side top

		frame $w.main -relief solid -borderwidth 2
		frame $w.main.left -relief flat
		frame $w.main.right -relief flat
		frame $w.main.left.images -relief flat
		text $w.main.left.desc -height 6 -width 40 -relief flat -background [::skin::getKey mainwindowbg] \
			-font sboldf -wrap word
		listbox $w.main.right.box -yscrollcommand "$w.main.right.ys set" -font splainf -background \
			white -relief flat -highlightthickness 0  -height 8 -width 30
		scrollbar $w.main.right.ys -command "$w.main.right.box yview" -highlightthickness 0 \
			-borderwidth 1 -elementborderwidth 2

		bind $w <<Escape>> "::skinsGUI::SelectSkinCancel $w"

		pack $w.main.left.images -in $w.main.left -side top -expand 0 -fill both
		pack $w.main.left.desc -in $w.main.left -side bottom -expand 1 -fill both
		pack $w.main.left -in $w.main -side left -expand 1 -fill both
		pack $w.main.right.ys -side right -fill both
		pack $w.main.right.box -side left -expand 0 -fill both
		pack $w.main.right -side right -expand 1 -fill both
		pack $w.main -expand 1 -fill both

		label $w.status -text ""
		pack $w.status -side bottom

		image create photo blank -width 1 -height 75
		label $w.main.left.images.blank -image blank

		image create photo blank2 -width 400 -height 1
		label $w.main.left.images.blank2 -image blank2

		set select -1
		set idx 0

		button $w.ok -text "[trans ok]" -command "::skinsGUI::SelectSkinOk $w" 
		button $w.cancel -text "[trans cancel]" -command "::skinsGUI::SelectSkinCancel $w" 
		checkbutton $w.preview -text "[trans preview]" -variable ::skin::preview_skin_change -onvalue 1 -offvalue 0

		pack $w.ok  $w.cancel $w.preview -side right -pady 5 -padx 5

		set the_skins [::skin::FindSkins]

		foreach skin $the_skins {
			if { [lindex $skin 0] == [::config::getGlobalKey skin] } { set select $idx } 
			$w.main.right.box insert end "[lindex $skin 0]"
			incr idx
		}

		set ::skin::skin_reloaded_needs_reset 0
		if { $select == -1 } {
			set select 0
			status_log "selecy = 0 --- didn't find current skin defaulting to first"

			$w.main.right.box selection set $select
	 		$w.main.right.box itemconfigure $select -background #AAAAAA

			set currentskin [lindex [lindex $the_skins 0] 0]
			if { $::skin::preview_skin_change == 1 } {
				set ::skin::skin_reloaded_needs_reset 1
				::skin::reloadSkin $currentskin
			}
		} else {
			status_log "select = $select --- [::config::getGlobalKey skin]\n"

			$w.main.right.box selection set $select
			$w.main.right.box itemconfigure $select -background #AAAAAA
		}
	
		::skinsGUI::DoPreview 1
		bind $w <Destroy> "grab release $w"
		bind $w.main.right.box <Button1-ButtonRelease> "::skinsGUI::DoPreview"

		moveinscreen $w 30
	}


	################################################################
	# ::skinsGUI::DoPreview ([skip_reload])
	# Updates the preview images (or skin if selected) when changing
	# the skin selection.
	# Arguments:
	#  - skip_reload => Don't reload the skin for preview.
	proc DoPreview { {skip_reload 0} } {
		set w .skin_selector
		set the_skins [::skin::FindSkins]
		set currentskin [lindex [lindex $the_skins [$w.main.right.box curselection]] 0]
		set currentdesc [lindex [lindex $the_skins [$w.main.right.box curselection]] 1]

		::skinsGUI::ClearPreview

		# If our skin hasn't the example images, take them from the default one
		image create photo preview1 -file [::skin::GetSkinFile pixmaps prefpers.gif $currentskin] -format gif
		image create photo preview2 -file [::skin::GetSkinFile pixmaps bonline.gif $currentskin] -format gif
		image create photo preview3 -file [::skin::GetSkinFile pixmaps offline.gif $currentskin] -format gif
		image create photo preview4 -file [::skin::GetSkinFile pixmaps baway.gif $currentskin] -format gif
		image create photo preview5 -file [::skin::GetSkinFile pixmaps amsnicon.gif $currentskin] -format gif
		image create photo preview6 -file [::skin::GetSkinFile pixmaps butblock.gif $currentskin] -format gif
		image create photo preview7 -file [::skin::GetSkinFile pixmaps butsmile.gif $currentskin] -format gif
		image create photo preview8 -file [::skin::GetSkinFile pixmaps butsend.gif $currentskin] -format gif
	
		label $w.main.left.images.1 -image preview1
		label $w.main.left.images.2 -image preview2
		label $w.main.left.images.3 -image preview3
		label $w.main.left.images.4 -image preview4
		label $w.main.left.images.5 -image preview5
		label $w.main.left.images.6 -image preview6
		label $w.main.left.images.7 -image preview7
		label $w.main.left.images.8 -image preview8

		grid $w.main.left.images.1 -in $w.main.left.images -row 1 -column 1
		grid $w.main.left.images.2 -in $w.main.left.images -row 1 -column 2
		grid $w.main.left.images.3 -in $w.main.left.images -row 1 -column 3
		grid $w.main.left.images.4 -in $w.main.left.images -row 1 -column 4
		grid $w.main.left.images.5 -in $w.main.left.images -row 1 -column 5
		grid $w.main.left.images.6 -in $w.main.left.images -row 1 -column 6
		grid $w.main.left.images.7 -in $w.main.left.images -row 1 -column 7
		grid $w.main.left.images.8 -in $w.main.left.images -row 1 -column 8
		grid $w.main.left.images.blank -in $w.main.left.images -row 1 -column 10
		grid $w.main.left.images.blank2 -in $w.main.left.images -row 2 -column 1 -columnspan 8

		$w.main.left.desc configure -state normal
		$w.main.left.desc delete 0.0 end
		$w.main.left.desc insert end "[trans description]\n\n$currentdesc"
		$w.main.left.desc configure -state disabled
	
		if { (!$skip_reload) && $::skin::preview_skin_change == 1 } {
			set ::skin::skin_reloaded_needs_reset 1
			::skin::reloadSkin $currentskin
		}
	}


	################################################################
	# ::skinsGUI::ClearPreview ()
	# Destroys every preview image on the skin selector.
	proc ClearPreview { } {
		if {[winfo exists .skin_selector.main.left.images]} {
			destroy .skin_selector.main.left.images.1
			destroy .skin_selector.main.left.images.2
			destroy .skin_selector.main.left.images.3
			destroy .skin_selector.main.left.images.4
			destroy .skin_selector.main.left.images.5
			destroy .skin_selector.main.left.images.6
			destroy .skin_selector.main.left.images.7
			destroy .skin_selector.main.left.images.8
		}
	}


	################################################################
	# ::skinsGUI::SelectSkinOk (w)
	# Checks if your selection is valid, if it is, it applies changes.
	# This procedure is called when OK in skin selector is pressed.
	# Arguments:
	#  - w => Path of the widget skin selector.
	proc SelectSkinOk { w } {
		if { [$w.main.right.box curselection] == "" } {
			$w.status configure -text "[trans selectskin]"
		} else {
			$w.status configure -text ""
			set skinidx [$w.main.right.box curselection]
			set skin [lindex [lindex [::skin::FindSkins] $skinidx] 0]
			status_log "Chose skin No $skinidx : $skin\n"
			config::setGlobalKey skin $skin
			save_config
			::config::saveGlobal
			unset ::skin::skin_reloaded_needs_reset
			::skin::reloadSkin $skin
			destroy $w
		}
	}


	################################################################
	# ::skinsGUI::SelectSkinCancel (w)
	# Checks if we need to reload current skin and destroys the selector.
	# This procedure is called when Cancel in skin selector is pressed.
	# Arguments:
	#  - w => Path of the widget skin selector.
	proc SelectSkinCancel { w } {
		if { $::skin::skin_reloaded_needs_reset } {
			::skin::reloadSkin [::config::getGlobalKey skin]
		}
		unset ::skin::skin_reloaded_needs_reset
		destroy $w
	}
}
