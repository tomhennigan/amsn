
::Version::setSubversionId {$Id$}

package require contentmanager
package require scalable-bg

snit::widgetadaptor loginscreen {

	option	-font	-default splainf

	variable after_id
	variable accept_userSelected 1

	variable background_tag

	variable lang_button_icon
	variable lang_button_text

	component dp_label
	variable dp_label_tag

	component user_label
	component user_field
	variable user_field_tag

	component pass_label
	component pass_field
	variable pass_field_tag

	component status_label
	component status_field
	variable status_field_tag

	component rem_me_field
	variable forget_me_label
	component rem_pass_field
	component auto_login_field

	component login_button
	component login_button_background
	variable login_button_tag

	component forgot_pass_link
	component service_status_link
	component new_account_link

	component check_ver_icon
	component check_ver_text

	variable more_label

	variable remember_me 0

	delegate method * to hull except {SortElements PopulateStateList LoginButtonPressed CanvasTextToLink LinkClicked LoggingIn ShowMore}
	delegate option * to hull except -font


	typeconstructor {
		::Event::registerEvent loggedOut all [list ::loginscreen LoggingOut]
		::Event::registerEvent show_login_screen all [list ::loginscreen LoggingOut]
	}

	constructor { args } {
		# Set up after_id array entries
		array set after_id {checkUser {} PosBg {} Sort {}}

		# Create canvas
		installhull using canvas -background [::skin::getKey loginbg] -highlightthickness 0 -xscrollcommand "$self CanvasScrolled" -yscrollcommand "$self CanvasScrolled"

		# Parse and apply creation-time options
		$self configurelist $args

		# Create background image
		set background_tag [$self create image 0 0 -anchor se -image [::skin::loadPixmap back]]

		# Create framework for elements
		contentmanager add group login_screen				-orient vertical	-widget $self
		contentmanager add group login_screen lang			-orient horizontal	-widget $self	-ipadx 4	-ipady 4
		contentmanager add group login_screen main			-orient vertical	-widget $self	-align center 	-pady 16
		contentmanager add group login_screen main dp			-orient horizontal	-widget $self	-align center
		contentmanager add group login_screen main fields 		-orient vertical	-widget $self	-pady 4		-align center
		contentmanager add group login_screen main fields user		-orient vertical	-widget $self	-pady 4		-align center
		contentmanager add group login_screen main fields pass		-orient vertical	-widget $self	-pady 4		-align center
		contentmanager add group login_screen main fields status	-orient vertical	-widget $self	-pady 4		-align center
		contentmanager add group login_screen main checkboxes 		-orient vertical	-widget $self
		contentmanager add group login_screen main checkboxes rem_me	-orient horizontal	-widget $self	-pady 2
		contentmanager add group login_screen main checkboxes forget_me	-orient horizontal	-widget $self	-pady 2		-padx 32
		contentmanager add group login_screen main checkboxes rem_pass	-orient horizontal	-widget $self	-pady 2
		contentmanager add group login_screen main checkboxes auto_login -orient horizontal	-widget $self	-pady 2
		contentmanager add group login_screen main login		-orient horizontal	-widget $self	-align center	-pady 8
		contentmanager add group login_screen main links		-orient vertical	-pady 32	-widget $self	-align left
		contentmanager add group login_screen main check_ver		-orient horizontal	-pady 8		-widget $self	-align center
		contentmanager add group login_screen main more			-orient horizontal	-pady 8		-widget $self	-align right

		# Create widgets
		# Language button
		set lang_button_icon [$self create image 0 0 -anchor nw -image [::skin::loadPixmap globe]]
		set lang_button_text [$self create text 0 0 -anchor nw -text [trans language] -fill [::skin::getKey loginurlfg]]
		# Display picture
		set dp_label [label $self.dp -image [::skin::getDisplayPicture ""] -borderwidth 1 -highlightthickness 0 -relief solid]
		set dp_label_tag [$self create window 0 0 -anchor nw -window $dp_label]
		# Username
		set user_label_tag [$self create text 0 0 -anchor nw -text "[trans user]:" -fill [::skin::getKey loginfg]]
		set user_field [combobox::combobox $self.user -editable true -relief solid -width 25 -command "$self UserSelected" -background [::skin::getKey loginwidgetbg]]
		set user_field_tag [$self create window 0 0 -anchor nw -window $user_field]
		# Password
		set pass_label_tag [$self create text 0 0 -anchor nw -text "[trans pass]:" -fill [::skin::getKey loginfg]]
		set pass_field [entry $self.pass -show "*" -relief solid -width 25 -vcmd {expr {[string length %P] <= 16} } -validate key -background [::skin::getKey loginwidgetbg]]
		set pass_field_tag [$self create window 0 0 -anchor nw -window $pass_field]
		# Status
		set status_label_tag [$self create text 0 0 -anchor nw -text "[trans signinstatus]:" -fill [::skin::getKey loginfg]]
		set status_field [combobox::combobox $self.status -editable true -relief solid -width 25 -command remember_state_list -background [::skin::getKey loginwidgetbg]]
		set status_field_tag [$self create window 0 0 -anchor nw -window $status_field]
		# Options
		# Remember me
		set rem_me_label_tag [$self create text 0 0 -anchor nw -text [trans rememberaccount] -fill [::skin::getKey loginfg]]
		set rem_me_field [checkbutton $self.rem_me -variable [myvar remember_me] -background [::skin::getKey loginbg]]
		set rem_me_field_tag [$self create window 0 0 -anchor nw -window $rem_me_field]
		# Forget me
		set forget_me_label [$self create text 0 0 -anchor nw -text [trans forget_me] -fill [::skin::getKey loginfg]]
		# Remember password
		set rem_pass_label_tag [$self create text 0 0 -anchor nw -text [trans rememberpass] -fill [::skin::getKey loginfg]]
		set rem_pass_field [checkbutton $self.rem_pass -variable [::config::getVar save_password] -background [::skin::getKey loginbg] -command [list $self ValidateCheckbuttonsSP]]
		set rem_pass_field_tag [$self create window 0 0 -anchor nw -window $rem_pass_field]
		# Log in automatically
		set auto_login_label_tag [$self create text 0 0 -anchor nw -text [trans autoconnect] -fill [::skin::getKey loginfg]]
		set auto_login_field [checkbutton $self.auto_login -variable [::config::getVar autoconnect] -background [::skin::getKey loginbg] -command [list $self ValidateCheckbuttonsAC]]
		set auto_login_field_tag [$self create window 0 0 -anchor nw -window $auto_login_field]

		set login_button_background [scalable-bg ::$self.login.bg -source [::skin::loadPixmap loginbutton] \
			-n [::skin::getKey loginbuttony 1] -e [::skin::getKey loginbuttonx 1] \
			-s [::skin::getKey loginbuttony 1] -w [::skin::getKey loginbuttonx 1] \
			-resizemethod [::skin::getKey loginbuttonresize "tile"]]

		# Login button
		set login_button [button $self.login \
				-text [trans login] \
				-image [::skin::loadPixmap nullimage] \
				-background [::skin::getKey loginbuttonbg] \
				-activebackground [::skin::getKey loginbuttonbg] \
				-foreground [::skin::getKey loginbuttonfg] \
				-activeforeground [::skin::getKey loginbuttonfghover] \
				-command [list $self LoginFormSubmitted] -cursor hand2 \
				-bd 0 -relief flat -font sboldf -highlightthickness 0 \
				-pady 0 -padx 0 -overrelief flat -compound center]

		bind $login_button <Configure> [list $self ResizeLoginButton %w %h]
		bind $login_button <Destroy> [list $login_button_background destroy]
		bind $login_button <Enter> \
			[list $login_button_background configure -source [::skin::loadPixmap loginbutton_hover]]
		bind $login_button <Leave> \
			[list $login_button_background configure -source [::skin::loadPixmap loginbutton]]

		set login_button_tag [$self create window 0 0 -anchor nw -window $login_button]
		# Useful links
		# Forgot password
		set forgot_pass_link [$self create text 0 0 -anchor nw -text [trans forgot_pass]]
		# Service status
		set service_status_link [$self create text 0 0 -anchor nw -text [trans msnstatus]]
		# New account
		set new_account_link [$self create text 0 0 -anchor nw -text [trans new_account]]
		# Check for newer amsn version
		set check_version_icon [$self create image 0 0 -anchor nw -image [::skin::loadPixmap download]]
		set check_version_text [$self create text 0 0 -anchor nw -text [trans checkver] -fill [::skin::getKey loginurlfg]]

		set more_label [$self create text 0 0 -anchor nw -text [trans more]]

		# Place widgets in framework
		# Language button
		contentmanager add element login_screen lang icon -widget $self -tag $lang_button_icon -valign middle -padx 8
		contentmanager add element login_screen lang text -widget $self -tag $lang_button_text -valign middle
		# Display picture
		contentmanager add element login_screen main dp label -widget $self -tag $dp_label_tag
		# Username
		contentmanager add element login_screen main fields user label -widget $self -tag $user_label_tag
		contentmanager add element login_screen main fields user field -widget $self -tag $user_field_tag
		# Password
		contentmanager add element login_screen main fields pass label -widget $self -tag $pass_label_tag
		contentmanager add element login_screen main fields pass field -widget $self -tag $pass_field_tag
		# Status
		contentmanager add element login_screen main fields status label -widget $self -tag $status_label_tag
		contentmanager add element login_screen main fields status field -widget $self -tag $status_field_tag
		# Options
		contentmanager add element login_screen main checkboxes rem_me field -widget $self -tag $rem_me_field_tag -padx 2 -valign middle
		contentmanager add element login_screen main checkboxes rem_me label -widget $self -tag $rem_me_label_tag -padx 4 -valign middle
		contentmanager add element login_screen main checkboxes forget_me	label	-widget $self	-tag $forget_me_label
		contentmanager add element login_screen main checkboxes rem_pass field -widget $self -tag $rem_pass_field_tag -padx 2 -valign middle
		contentmanager add element login_screen main checkboxes rem_pass label -widget $self -tag $rem_pass_label_tag -padx 2 -valign middle
		contentmanager add element login_screen main checkboxes auto_login field -widget $self -tag $auto_login_field_tag -padx 2 -valign middle
		contentmanager add element login_screen main checkboxes auto_login label -widget $self -tag $auto_login_label_tag -padx 2 -valign middle
		# Login button
		contentmanager add element login_screen main login login_button -widget $self -tag $login_button_tag
		# Links
		contentmanager add element login_screen main links forgot_pass -widget $self -tag $forgot_pass_link -pady 2
		contentmanager add element login_screen main links service_status -widget $self -tag $service_status_link -pady 2
		contentmanager add element login_screen main links new_account -widget $self -tag $new_account_link -pady 2
		contentmanager add element login_screen main check_ver icon -widget $self -tag $check_version_icon -padx 4 -valign middle
		contentmanager add element login_screen main check_ver text -widget $self -tag $check_version_text -padx 4 -valign middle
		contentmanager add element login_screen main more label	-widget $self	-tag $more_label

		# Set font for canvas all text items
		set all_tags [$self find all]
		foreach tag $all_tags {
			if { [$self type $tag] == "text" } {
				$self itemconfigure $tag -font splainf
			}
		}

		# Make checkbuttons look nice
		foreach checkbutton [list $rem_me_field $rem_pass_field $auto_login_field] {
			if {[OnMac]} {
				# Checkbuttons already look nice for us.
				$checkbutton configure -relief flat -highlightthickness 0 -bd 0 -bg [::skin::getKey loginbg] -selectcolor [::skin::getKey logincheckfg]
			} else {
				$checkbutton configure -relief flat -highlightthickness 0 -bd 0 \
					-bg [::skin::getKey loginbg] -selectcolor [::skin::getKey logincheckfg] \
					-image [::skin::loadPixmap checkbox] -selectimage [::skin::loadPixmap checkbox_on] -indicatoron 0
			}
		}

		# Bindings
		# Geometry events
		bind $self <Map> "$self WidgetResized"
		bind $self <Configure> "$self WidgetResized"
		# Bind language button
		contentmanager bind login_screen lang <ButtonRelease-1> "::lang::show_languagechoose"
		contentmanager bind login_screen lang <Enter> "$self configure -cursor hand2"
		contentmanager bind login_screen lang <Leave> "$self configure -cursor left_ptr"
		# Catch hand-editing of username field
		bind $user_field <KeyRelease> "$self UsernameEdited"
		# Bind <Return> on password field to submit login form
		bind $pass_field <Return> "$self LoginFormSubmitted"
		# Make checkbutton labels clickable
		contentmanager bind login_screen main checkboxes rem_me label <ButtonPress-1> "$rem_me_field invoke"
		contentmanager bind login_screen main checkboxes rem_pass label <ButtonPress-1> "$rem_pass_field invoke"
		contentmanager bind login_screen main checkboxes auto_login label <ButtonPress-1> "$auto_login_field invoke"
		# Make text items into links
		$self CanvasTextToLink login_screen main checkboxes forget_me label "$self ForgetMe"
		$self CanvasTextToLink login_screen main more label "$self ShowMore"
		$self CanvasTextToLink login_screen main links forgot_pass [list launch_browser "https://accountservices.passport.net/uiresetpw.srf?lc=1033"]
		$self CanvasTextToLink login_screen main links service_status [list launch_browser "http://messenger.msn.com/Status.aspx"]
		$self CanvasTextToLink login_screen main links new_account [list launch_browser "https://accountservices.passport.net/reg.srf?sl=1&lc=1033"]
		$self CanvasTextToLink login_screen main check_ver text "::autoupdate::check_version"

		$self FillLoginFields

		# Register for events
		::Event::registerEvent loggingIn all [list $self LoggingIn]
		::Event::registerEvent reconnecting all [list $self LoggingIn]
		::Event::registerEvent profileCreated all [list $self profileCreated]
		::Event::registerEvent profileDeleted all [list $self profileDeleted]

		if { [$user_field get] == "" } {
			catch {focus -force $user_field}
		} else {
			catch {focus -force $pass_field}
			
		}
	}

	destructor {
		catch { contentmanager delete login_screen }
		foreach {name id} [array get after_id] {
			after cancel $id
		}
		# Unregister for events
		::Event::unregisterEvent loggingIn all [list $self LoggingIn]
		::Event::unregisterEvent reconnecting all [list $self LoggingIn]
		::Event::unregisterEvent profileCreated all [list $self profileCreated]
		::Event::unregisterEvent profileDeleted all [list $self profileDeleted]
	}

	method ResizeLoginButton {width height} {
		#Don't put {} here for expr as we need to substitute in the current context
		$login_button_background configure -width [expr $width+2*[::skin::getKey loginbuttonx 1]] \
			-height [expr $height+2*[::skin::getKey loginbuttony 1]]
		bind $login_button <Configure> ""
		$login_button configure -image [$login_button_background name]
	}

	# ------------------------------------------------------------------------------------------------------------
	# WidgetResized
	# Called when canvas is resized. Calls methods to do things dependent on size of window
	# Called by: Binding
	method WidgetResized {} {
		# Keep background in bottom right corner
		after cancel $after_id(PosBg)
		set after_id(PosBg) [after 10 [list $self AutoPositionBackground]]
		# Resize input fields
		$self AutoResizeInputFields
		# Arrange items on the canvas
		after cancel $after_id(Sort)
		set after_id(Sort) [after 10 [list $self SortElements]]
	}

	# ------------------------------------------------------------------------------------------------------------
	# 
	method CanvasScrolled { args } {
		# Keep background in bottom right corner
		#$self AutoPositionBackground
	}

	# ------------------------------------------------------------------------------------------------------------
	# AutoPositionBackground
	# Places the background in its correct place on the canvas
	# Called by: WidgetResized
	method AutoPositionBackground {} {
		set bg_x [expr {round([expr {[winfo width $self] - 5}])}]
		set bg_y [expr {round([expr {[winfo height $self] - 5}])}]
		$self coords $background_tag $bg_x $bg_y
	}

	# ------------------------------------------------------------------------------------------------------------
	# AutoResizeInputFields
	# Resizes input fields (username, password and status) based on the canvas's size
	# Called by: WidgetResized
	method AutoResizeInputFields {} {
		# Get window's width
		set win_width [winfo width $self]
		# Set field width to 3/4 of window's width
		set field_width [expr {round($win_width * 0.75)}]
		# Get the maximum width we want the fields (approx. 35 characters wide)
		set max_field_width [expr {[font measure $options(-font) -displayof $user_field "_"] * 35}]
		# Enforce maximum width
		if { $field_width > $max_field_width } {
			set field_width $max_field_width
		}
		# Resize fields
		foreach tag [list $user_field_tag $pass_field_tag $status_field_tag] {
			$self itemconfigure $tag -width $field_width
		}
	}

	# ------------------------------------------------------------------------------------------------------------
	# FillLoginFields
	# Fills in login fields
	# Called by: constructor, profileDeleted
	method FillLoginFields { } {
		# Fill in usernames and states
		$user_field list delete 0 end
		$self PopulateUserList
		$user_field delete 0 end
		$user_field insert end [::config::getKey login]
		$self UsernameEdited
		$self PopulateStateList
	}

	# ------------------------------------------------------------------------------------------------------------
	# PopulateUserList
	# Add profiles to user combobox
	# Called by: FillLoginFields
	method PopulateUserList { } {
		# Populate user list
		LoadLoginList 1
		set tmp_list ""
		$user_field list delete 0 end
		set idx 0
		while { [LoginList get $idx] != 0 } {
			lappend tmp_list [LoginList get $idx]
			incr idx
		}
		eval $user_field list insert end $tmp_list
	}

	# ------------------------------------------------------------------------------------------------------------
	# PopulateStateList
	# Add normal and custom states to list of available sign-in states
	# Called by: constructor, UserSelected
	method PopulateStateList {} {
		# Make the list editable
		$status_field configure -editable true
		# Standard states
		$status_field list delete 0 end
		set i 0
		while { $i < 8 } {
			set statecode "[::MSN::numberToState $i]"
			set description "[trans [::MSN::stateToDescription $statecode]]"
			$status_field list insert end $description
			incr i
		}
		# Custom states
		AddStatesToList $status_field
		# Make it non-editable
		$status_field configure -editable false
		# Select remembered state
		$status_field select [get_state_list_idx [::config::getKey connectas]]
	}

	# ------------------------------------------------------------------------------------------------------------
	# CanvasTextToLink
	# Makes a canvas text into a blue link with a command binding
	# Called by: constructor
	method CanvasTextToLink { args } {
		# Get path for contentmanager item
		set tree [lrange $args 0 end-1]
		# Get "link"'s command
		set cmd [list [lindex $args end]]
		# Get the canvas tag
		set canvas_tag [eval contentmanager cget $tree -tag]
		# Bind the tag
		eval contentmanager bind $tree <Enter> [list "$self configure -cursor hand2"]
		eval contentmanager bind $tree <Leave> [list "$self configure -cursor left_ptr"]
		eval contentmanager bind $tree <ButtonRelease-1> [list "$self LinkClicked $canvas_tag %x %y $cmd"]
		# Make it blue :)
		$self itemconfigure $canvas_tag -fill [::skin::getKey loginurlfg]
	}
	
	method ValidateCheckbuttonsAC { } {
		if { [::config::getKey autoconnect] == 1} {
			::config::setKey save_password 1
		} 
		if { [::config::getKey save_password] != 1} {
			::config::setKey autoconnect 0
		}
	}
	method ValidateCheckbuttonsSP { } {
		if { [::config::getKey save_password] != 1} {
			::config::setKey autoconnect 0
		}
		if { [::config::getKey autoconnect] == 1} {
			::config::setKey save_password 1
		} 
	}

	# ------------------------------------------------------------------------------------------------------------
	# LinkClicked
	# Checks that the ButtonRelease event happened inside the bounding box of the link and execute's its command if it does.
	# Called by: Various bindings
	method LinkClicked { tag x y cmd } {
		# Convert x and y to actual canvas coords, in case we've scrolled.
		set x [$self canvasx $x]
		set y [$self canvasy $y]
		# Get item's coords
		set item_coords [$self bbox $tag]
		# Check the ButtonRelease was within the link's bbox. If it was, execute the link's command
		if { $x > [lindex $item_coords 0] && $x < [lindex $item_coords 2] && $y > [lindex $item_coords 1] && $y < [lindex $item_coords 3] } {
			eval $cmd
		}
	}

	# ------------------------------------------------------------------------------------------------------------
	# SortElements
	# Arrange elements on the canvas
	# Called by: Binding
	method SortElements {} {

		# We need to show everything so that it calculates their sizes when it sorts them
 		contentmanager show login_screen lang
 		contentmanager show login_screen main
 		contentmanager show login_screen main dp
 		contentmanager show login_screen main fields
 		contentmanager show login_screen main checkboxes
 		contentmanager show login_screen main login
 		contentmanager show login_screen main links
 		contentmanager show login_screen main check_ver
 		contentmanager show login_screen main more

		# We sort to get the sizes of each element..
		contentmanager sort login_screen  -level r


		# Then we hide everything apart from the fields and the 'show' button
 		contentmanager hide login_screen lang
 		contentmanager show login_screen main
 		contentmanager hide login_screen main dp
 		contentmanager show login_screen main fields
 		contentmanager hide login_screen main checkboxes
 		contentmanager hide login_screen main login
 		contentmanager hide login_screen main links
 		contentmanager hide login_screen main check_ver
 		contentmanager show login_screen main more

 		set max [winfo height $self]


 		set current 0

		incr current [contentmanager height login_screen main fields]
		incr current [contentmanager cget login_screen main fields -pady]
		incr current [contentmanager cget login_screen main fields -pady]
		incr current [contentmanager height login_screen main login]
		incr current [contentmanager cget login_screen main login -pady]
		incr current [contentmanager cget login_screen main login -pady]
		incr current [contentmanager height login_screen main more]
		incr current [contentmanager cget login_screen main more -pady]
		incr current [contentmanager cget login_screen main more -pady]


		if { $current < $max } {
			contentmanager show login_screen main login
			incr current [contentmanager height login_screen main checkboxes]
			incr current [contentmanager cget login_screen main checkboxes -pady]
			incr current [contentmanager cget login_screen main checkboxes -pady]
			
			if { $current < $max } {
				contentmanager show login_screen main checkboxes
				
				incr current [contentmanager height login_screen main dp]
				incr current [contentmanager cget login_screen main dp -pady]
				incr current [contentmanager cget login_screen main dp -pady]
			
				if { $current < $max } {
					contentmanager show login_screen main dp
					
					incr current [contentmanager height login_screen lang]
					incr current [contentmanager cget login_screen lang -pady]
					incr current [contentmanager cget login_screen lang -pady]
			
					if { $current < $max } {
						contentmanager show login_screen lang

						incr current [contentmanager height login_screen main check_ver]
						incr current [contentmanager cget login_screen main check_ver -pady]
						incr current [contentmanager cget login_screen main check_ver -pady]
						
						if { $current < $max } {
							contentmanager show login_screen main check_ver

							if { [::config::getKey show_login_screen_links 1] } {
								incr current [contentmanager height login_screen main links]
								incr current [contentmanager cget login_screen main links -pady]
								incr current [contentmanager cget login_screen main links -pady]

								if { $current < $max } {
									contentmanager show login_screen main links
									contentmanager hide login_screen main more
								}
							} else {
								contentmanager hide login_screen main links
								contentmanager hide login_screen main more
							}
						}
					}
				}
			}
		} 

		set padx [expr {[winfo width $self] - [contentmanager width login_screen main]}]
		if { $padx < 0 } {
			set padx 0
		}
		contentmanager configure login_screen main -padx $padx
		contentmanager sort login_screen  -level r

		# TODO : this should be done by simply specifying a -padx or -ipadx to login_screen main.. I can't get it to work, I don't understand the damn contentmanager!
		#set main_x [expr {([winfo width $self] / 2) - ([contentmanager width login_screen main] / 2)}]
		#set main_y [expr {[contentmanager height login_screen lang] + 16}]
	 	#contentmanager coords login_screen main $main_x $main_y
		
	}

	# ------------------------------------------------------------------------------------------------------------
	# ShowMore
	# Show all elements on login screen and enlarge login window accordingly
	# Called by: Binding
	method ShowMore { } {
		# We need to show everything so that it calculates their sizes when it sorts them
 		contentmanager show login_screen lang
 		contentmanager show login_screen main
 		contentmanager show login_screen main dp
 		contentmanager show login_screen main fields
 		contentmanager show login_screen main checkboxes
 		contentmanager show login_screen main login
 		contentmanager show login_screen main links
 		contentmanager show login_screen main check_ver
 		contentmanager show login_screen main more

		# We sort to get the sizes of each element..
		contentmanager sort login_screen  -level r

		set h [contentmanager height login_screen]
		set w [contentmanager width login_screen]
		incr h [contentmanager cget login_screen -pady]
		incr h [contentmanager cget login_screen -pady]
		incr w [contentmanager cget login_screen -padx]
		incr w [contentmanager cget login_screen -padx]
	      
		set current_w [winfo width $self]
		set current_h [winfo height $self]

		set adjustment_w [expr {$w - $current_w}]
		set adjustment_h [expr {$h - $current_h}]
		
		set geometry [winfo geometry [winfo toplevel $self]]

		regexp {=?(\d+)x(\d+)[+\-](-?\d+)[+\-](-?\d+)} $geometry -> width height x y
		
		incr width $adjustment_w
		incr height $adjustment_h

		wm geometry [winfo toplevel $self] ${width}x${height}
	
	}

	# ------------------------------------------------------------------------------------------------------------
	# UsernameEdited
	# Called when the username field is edited
	# Called by: Binding
	method UsernameEdited {} {
		# Get username
		set username [$user_field get]
		# Don't let it check numbers, it'll try and load that number profile (e.g. 0 would load the first profile, 1 the second etc)
		if { [string is integer $username] } { set username "" }
		after cancel $after_id(checkUser)
		set after_id(checkUser) [after 100 [list $self CheckUsername "$username"]]
	}

	# ------------------------------------------------------------------------------------------------------------
	# CheckUsername
	# Check whether $username exists as an amsn profile. If so, switch to it and set up DP etc
	# Called by: UsernameEdited
	method CheckUsername { {username ""} } {
		# Check if the username has a profile.
		# If it does, switch to it, select the remember me box and set the DP.
		# If it doesn't, deselect the remember me box and set the DP to generic 'nopic' DP
		if { [LoginList exists 0 $username] } {
			$self UserSelected $user_field $username
		} else {
			# De-select 'remember me' field
			$rem_me_field deselect
			# Disable 'forget me' button
			$self itemconfigure $forget_me_label -fill [::skin::getKey disabledfg] -state disabled
			if { [::config::getGlobalKey disableprofiles] != 1 } {
				$rem_me_field configure -state normal
			}
			# If we've got a profile loaded, switch to default generic one
			if { [::config::getKey login] != "" } {
				# Switching to default profile, remove lock on previous profiles if needed
				SwitchToDefaultProfile
				# -------------------------------------------------------
				# Change DP
				$dp_label configure -image [::skin::getNoDisplayPicture]
			}
			# Blank password field
			$pass_field delete 0 end
		}
	}

	# ------------------------------------------------------------------------------------------------------------
	# UserSelected
	# Various changes to login screen after changing user, e.g display picture, password (if stored) etc
	# Called by: CheckUsername, loggedOut
	method UserSelected { combo user } {
		# This is needed here to make sure we change user only once per 100 ms, the reason behind it is that the combobox calls the -command (which is UserSelected)
		# on <FocusOut> so if we enter a profile in use by typing the address, then we'll get a 'profile in use' popup which generates a <FocusOut> which causes a second
		# popup to appear at the same time..
		if { $accept_userSelected == 0 } {
			return
		} else {
			set accept_userSelected 0
			after 100 "if \[info exists [myvar accept_userSelected]\] [list [list set [myvar accept_userSelected] 1]]"
		}

		# Don't let us use integers as username (see UsernameEdited)
		if { [string is integer $user] } { set user "" }
		# We have to check whether this profile exists because sometimes userSelected gets called when it shouldn't,
		# e.g when tab is pressed in the username combobox
		if { [LoginList exists 0 $user] } {
			# Select and disable 'remember me' checkbutton
			$rem_me_field select
			$rem_me_field configure -state disabled
			# Enable 'forget me' buttton
			$self itemconfigure $forget_me_label -fill [::skin::getKey loginurlfg] -state normal
			# Switch to this profile
			ConfigChange $combo $user
			# Get states
			$self PopulateStateList
			# Change DP
			$dp_label configure -image displaypicture_std_self
			# If we've remembered the password, insert it, if not, clear the password field
			if { [set [$rem_pass_field cget -variable]] } {
				global password
				$pass_field delete 0 end
				$pass_field insert end $password
			} else {
				$pass_field delete 0 end
			}
		} else {
			$pass_field delete 0 end
		}

		# Re-sort stuff on canvas (in case, for example, we now have a larger/smaller DP)
		# The 'after 100' is because the status combobox doesn't seem to regain it's height immediately for some
		# reason, so if we sort straight away, the checkbox below the status combo overlaps it.
		after cancel $after_id(Sort)
		set after_id(Sort) [after 100 [list $self SortElements]]
	}

	# ------------------------------------------------------------------------------------------------------------
	# ForgetMe
	# Dialog confirming user wants to delete current profile. Provides link to relevant section of preferences window.
	# Called by: Binding
	method ForgetMe {} {
		# Create dialog
		set w [toplevel .forgetme_dialog -width 400]
		wm title $w [trans delprofile]
		
		# Icon
		set icon [label $w.icon -image [::skin::loadPixmap info]]

		# Message
		set message [label $w.msg -text [trans howto_remove_profile [::config::getKey login]] -justify left]

		# Link to prefs "Others" page
		set link [label $w.link		-text			[trans goto_prefs_removeprofile] \
						-fg			blue \
						-font			splainf \
						-cursor			hand2 ]

		# Bind the clickable label 
		bind $w.link <Enter> "$w.link configure -font sunderf"
		bind $w.link <Leave> "$w.link configure -font splainf"
		bind $w.link <ButtonRelease> [list $self ForgetMeLinkClicked $w]

		# OK button
		set ok_button [button $w.ok -text [trans Ok] -command "destroy $w"]


		# Set widgets out using grid
		grid $icon	-row 0	-column	0	-sticky nw	-columnspan 1	-padx 4	-pady 4
		grid $message	-row 0	-column 1	-sticky new	-columnspan 1	-padx 4	-pady 4
		grid $link	-row 1	-column 1	-sticky new	-columnspan 2	-padx 4	-pady 4
		grid $ok_button	-row 2	-column 0	-sticky s	-columnspan 2	-padx 4	-pady 4 -ipadx 20

		grid columnconfigure	$w	1	-weight 1
		grid rowconfigure	$w	2	-weight 1

		# Make dialog transient
		wm transient $w $self

		# Make the dialog non-resizable
		wm resizable .forgetme_dialog 0 0

		# Raise dialog and put local grab on it
		raise $w
		grab set $w
	}

	# ------------------------------------------------------------------------------------------------------------
	# ForgetMeLinkClicked
	# Switches to default profile, clears login screen and opens preferences window at "Others" page so user can delete profile. Closes forget me dialog too.
	# Called by: Binding
	method ForgetMeLinkClicked { w } {
		# Switch to default profile so user can delete the current one
		SwitchToDefaultProfile
		# Open preferences window at "Others" page
		Preferences others

		# Remove grab on dialog and destroy it
		grab release $w
		destroy $w
	}

	# ------------------------------------------------------------------------------------------------------------
	# LoginFormSubmitted
	# Validates login data and logs in if all is fine. Creates profile if 'remember me' is selected and the profile doesn't already exist.
	# Called by: Various bindings
	method LoginFormSubmitted { } {
		# Get user and pass
		set user [$user_field get]
		set pass [$pass_field get]

		# Check we actually have a username and password entered!
		if { $user == "" || $pass == "" } { return }

		
		# If remember me checkbutton is selected and a profile doesn't already exists for this user, create a profile for them.
		if { $remember_me && ![LoginList exists 0 $user] } {
			CreateProfile $user
		}

		# Login with them
		$self login $user $pass
	}

	# ------------------------------------------------------------------------------------------------------------
	# profileDeleted
	# Receives event when a profile is deleted and removes that profile from user list
	method profileDeleted { event email } {
		# Remove profile from user list
		for { set i 0 } { $i < [$user_field list size] } { incr i 1 } {
			if { [$user_field list get $i] == $email } {
				$user_field list delete $i
			}
		}

		# Fill login fields
		$self FillLoginFields
	}

	# ------------------------------------------------------------------------------------------------------------
	# Receives event when a profile is created and adds that profile to user list
	method profileCreated { event email } {
		# Add profile to user list
		$user_field list insert end $email
	}

	# ------------------------------------------------------------------------------------------------------------
	# login
	# Logs in with the current details
	# Called by: LoginFormSubmitted
	method login { user pass } {
		global password

		# Set username and password key and global respectively
		set password $pass
		if { !$remember_me || ![LoginList exists 0 $user] } {
			::config::setKey login [string tolower $user]
		}

		# Connect
		::MSN::connect $password
	}

	# ------------------------------------------------------------------------------------------------------------
	# logginIn
	# Receives the event fired by protocol. Unpacks this widget and packs the sign-in progress widget.
	method LoggingIn { event } {
		status_log "logging in, destroying loginscreen : $event "
		pack forget $self
		pack .main.f -expand true -fill both
		destroy $self
	}

	# ------------------------------------------------------------------------------------------------------------
	# loggedOut
	typemethod LoggingOut { event } {
		status_log "logging out, creating loginscreen : $event "
		# TODO : this is very ugly code... damn!
		if {! [winfo exists .main.loginscreen] } {
			loginscreen .main.loginscreen						
		}
		pack forget .main.f
		pack .main.loginscreen -e 1 -f both
	}

	# ------------------------------------------------------------------------------------------------------------
	# clear
	# Clears/deselects all fields on the login screen
	# Called by: 
	method clear { } {
		$user_field delete 0 end

		$self UsernameEdited
	}
}

