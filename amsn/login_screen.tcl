
::Version::setSubversionId {$Id$}

package require contentmanager

snit::widgetadaptor loginscreen {

	variable background_tag

	component dp_label

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
	component rem_pass_field
	component auto_login_field

	component login_button
	variable login_button_tag

	component forgot_pass_link
	component service_status_link
	component new_account_link

	variable remember_me

	delegate method * to hull except {SortElements PopulateStateList LoginButtonPressed CanvasTextToLink LinkClicked}

	constructor { args } {
		set remember_me 0

		installhull using canvas -bg white -highlightthickness 0 -xscrollcommand "$self CanvasScrolled" -yscrollcommand "$self CanvasScrolled"

		# Create background image
		set background_tag [$self create image 0 0 -anchor se -image [::skin::loadPixmap back]]

		# Create framework for elements
		contentmanager add group main			-orient vertical	-widget $self
		contentmanager add group main lang		-orient horizontal	-widget $self
		contentmanager add group main dp		-orient horizontal	-widget $self	-align center
		contentmanager add group main user		-orient vertical	-widget $self
		contentmanager add group main pass		-orient vertical	-widget $self
		contentmanager add group main status		-orient vertical	-widget $self
		contentmanager add group main rem_me		-orient horizontal	-widget $self
		contentmanager add group main rem_pass		-orient horizontal	-widget $self
		contentmanager add group main auto_login	-orient horizontal	-widget $self
		contentmanager add group main login		-orient horizontal	-widget $self	-align center
		contentmanager add group main links		-orient vertical	-pady 25	-widget $self	-align center

		# Create widgets
		# Display picture
		set dp_label [$self create image 0 0 -anchor nw -image [::skin::getDisplayPicture ""]]
		# Username
		set user_label_tag [$self create text 0 0 -anchor nw -text [trans user]]
		set user_field [combobox::combobox $self.user -editable true -bg white -relief solid -width 25 -command "$self UserSelected"]
		set user_field_tag [$self create window 0 0 -anchor nw -window $user_field]
		# Populate user list
		set tmp_list ""
		$user_field list delete 0 end
		set idx 0
		while { [LoginList get $idx] != 0 } {
			lappend tmp_list [LoginList get $idx]
			incr idx
		}
		eval $user_field list insert end $tmp_list
		# Password
		set pass_label_tag [$self create text 0 0 -anchor nw -text [trans pass]]
		set pass_field [entry $self.pass -show "*" -bg white -relief solid -width 25]
		set pass_field_tag [$self create window 0 0 -anchor nw -window $pass_field]
		# Status
		set status_label_tag [$self create text 0 0 -anchor nw -text [trans signinstatus]]
		set status_field [combobox::combobox $self.status -editable true -bg white -relief solid -width 25]
		set status_field_tag [$self create window 0 0 -anchor nw -window $status_field]
		# Populate status list
		$self PopulateStateList
		# Options
		# Remember me
		set rem_me_label_tag [$self create text 0 0 -anchor nw -text [trans remember_me]]
		set rem_me_field [checkbutton $self.rem_me -variable [myvar remember_me]]
		set rem_me_field_tag [$self create window 0 0 -anchor nw -window $rem_me_field]
		# Remember password
		set rem_pass_label_tag [$self create text 0 0 -anchor nw -text [trans rememberpass]]
		set rem_pass_field [checkbutton $self.rem_pass -variable [::config::getVar save_password]]
		set rem_pass_field_tag [$self create window 0 0 -anchor nw -window $rem_pass_field]
		# Log in automatically
		set auto_login_label_tag [$self create text 0 0 -anchor nw -text [trans autoconnect2]]
		set auto_login_field [checkbutton $self.auto_login -variable [::config::getVar autoconnect]]
		set auto_login_field_tag [$self create window 0 0 -anchor nw -window $auto_login_field]
		# Login button
		set login_button [button $self.login -text [trans login] -command "$self LoginButtonPressed"]
		set login_button_tag [$self create window 0 0 -anchor nw -window $login_button]
		# Useful links
		# Forgot password
		set forgot_pass_link [$self create text 0 0 -anchor nw -text [trans forgot_pass]]
		# Service status
		set service_status_link [$self create text 0 0 -anchor nw -text [trans msnstatus]]
		# New account
		set new_account_link [$self create text 0 0 -anchor nw -text [trans new_account]]

		# Place widgets in framework
		# Display picture
		contentmanager add element main dp label -widget $self -tag $dp_label
		# Username
		contentmanager add element main user label -widget $self -tag $user_label_tag
		contentmanager add element main user field -widget $self -tag $user_field_tag
		# Password
		contentmanager add element main pass label -widget $self -tag $pass_label_tag
		contentmanager add element main pass field -widget $self -tag $pass_field_tag
		# Status
		contentmanager add element main status label -widget $self -tag $status_label_tag
		contentmanager add element main status field -widget $self -tag $status_field_tag
		# Options
		contentmanager add element main rem_me field -widget $self -tag $rem_me_field_tag
		contentmanager add element main rem_me label -widget $self -tag $rem_me_label_tag
		contentmanager add element main rem_pass field -widget $self -tag $rem_pass_field_tag
		contentmanager add element main rem_pass label -widget $self -tag $rem_pass_label_tag
		contentmanager add element main auto_login field -widget $self -tag $auto_login_field_tag
		contentmanager add element main auto_login label -widget $self -tag $auto_login_label_tag
		# Login button
		contentmanager add element main login login_button -widget $self -tag $login_button_tag
		# Links
		contentmanager add element main links forgot_pass -widget $self -tag $forgot_pass_link -pady 2
		contentmanager add element main links service_status -widget $self -tag $service_status_link -pady 2
		contentmanager add element main links new_account -widget $self -tag $new_account_link -pady 2
		# Make the text items into links
		$self CanvasTextToLink main links forgot_pass [list launch_browser "https://accountservices.passport.net/uiresetpw.srf?lc=1033"]
		$self CanvasTextToLink main links service_status [list launch_browser "http://messenger.msn.com/Status.aspx"]
		$self CanvasTextToLink main links new_account [list launch_browser "https://accountservices.passport.net/reg.srf?sl=1&lc=1033"]

		# Set font for canvas all text items
		set all_tags [$self find all]
		foreach tag $all_tags {
			if { [$self type $tag] == "text" } {
				$self itemconfigure $tag -font splainf
			}
		}

		# Bindings
		bind $user_field <KeyRelease> "+after cancel [list $self UsernameEdited]; after 1 [list $self UsernameEdited]"
		bind $self <Map> "$self Resized"
		bind $self <Configure> "$self Resized"
	}

	method Resized {} {
		$self AutoPositionBackground
		$self SortElements
	}

	method CanvasScrolled { args } {
		$self AutoPositionBackground
	}

	method AutoPositionBackground {} {
		set bg_x [expr {[winfo width $self] - 5}]
		set bg_y [expr {[winfo height $self] - 5}]
		$self coords $background_tag [$self canvasx $bg_x] [$self canvasy $bg_y]
	}

	method CanvasTextToLink { args } {
		set tree [lrange $args 0 end-1]
		set cmd [list [lindex $args end]]
		set canvas_tag [eval contentmanager cget $tree -tag]
		eval contentmanager bind $tree <Enter> [list "$self configure -cursor hand2"]
		eval contentmanager bind $tree <Leave> [list "$self configure -cursor left_ptr"]
		eval contentmanager bind $tree <ButtonRelease-1> [list "$self LinkClicked $canvas_tag %x %y $cmd"]
		$self itemconfigure $canvas_tag -fill blue
	}

	method LinkClicked { tag x y cmd } {
		# Convert x and y to actual canvas coords, in case we've scrolled.
		set x [$self canvasx $x]
		set y [$self canvasy $y]

		set item_coords [$self bbox $tag]

		if { $x > [lindex $item_coords 0] && $x < [lindex $item_coords 2] && $y > [lindex $item_coords 1] && $y < [lindex $item_coords 3] } {
			eval $cmd
		}
	}

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

	method SortElements {} {
		contentmanager sort main -level r
		set main_x [expr {([winfo width $self] / 2) - ([contentmanager width main] / 2)}]
		set main_y 25
		contentmanager coords main $main_x $main_y
	}

	method UsernameEdited {} {
		# Get username
		set username [$user_field get]
		# Check if the username has a profile.
		# If it does, switch to it, select the remember me box and set the DP.
		# If it doesn't, deselect the remember me box and set the DP to generic 'nopic' DP
		if { [LoginList exists 0 $username] } {
			$rem_me_field select
			$rem_me_field configure -state disabled
			ConfigChange $user_field $username
			$self itemconfigure $dp_label -image displaypicture_std_self
		} else {
			$rem_me_field deselect
			$rem_me_field configure -state normal
			$self itemconfigure $dp_label -image [::skin::getDisplayPicture $username]
		}
	}

	method UserSelected { combo user } {
		# We have to check whether this profile exists because sometimes userSelected gets called when it shouldn't,
		# e.g when tab is pressed in the username combobox
		if { [LoginList exists 0 $user] } {
			$rem_me_field select
			$rem_me_field configure -state disabled
			ConfigChange $combo $user
			$self PopulateStateList
			$self itemconfigure $dp_label -image displaypicture_std_self
		}
	}

	method LoginButtonPressed { } {
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

	method login { user pass } {
		global password

		# Set username and password key and global repsectively
		set password $pass
		::config::setKey login $user

		# Connect
		::MSN::connect $password

		# TEMPORARY CODE TO SWITCH BACK TO WIDGET WITH LOGIN PROGRESS IN
		pack forget $self
		destroy .l
		pack .main -e 1 -f both
	}
}

pack forget .main
pack [loginscreen .l] -e 1 -f both

namespace eval ::loginScreen {

	proc createLoginScreen { } {
		set win [frame .loginscreen -bg white]
		set fields [frame $win.fields -bg white]

		set bg [label $win.bg -bg white -image [::skin::loadPixmap back]]
		place $bg -anchor se -relx 1.0 -x -5 -rely 1.0 -y -5

		# ------------------------------------------------
		# Create language button
		set lang_button [button $win.lang -borderwidth 0 -fg #777777 -bg white -activebackground white -highlightthickness 0 -compound left -image [::skin::loadPixmap globe] -text [trans language] -command ::lang::show_languagechoose -cursor hand2]
		$lang_button configure -relief flat
		pack $lang_button -side top -anchor w -padx 4 -pady 4

		# ------------------------------------------------
		# Create display picture
		load_my_pic
		set dp [label $win.dp -bg white -image displaypicture_std_self -highlightthickness 0 -relief solid -borderwidth 1]
		pack $dp -anchor n

		# ------------------------------------------------	
		# Create username label and combobox
		set username_frame [frame $fields.username_frame -bg white]
		set username_label [label $username_frame.username_label -bg white -borderwidth 0 -text "[trans user]:"]
		set username_field [combobox::combobox $username_frame.username -editable true -bg white -relief solid -command "::loginScreen::userSelected $win" -width 25]
		pack $username_label $username_field -anchor w -side top -pady 0
		# Populate it
		set tmp_list ""
		$username_field list delete 0 end
		set idx 0
		while { [LoginList get $idx] != 0 } {
			lappend tmp_list [LoginList get $idx]
			incr idx
		}
		eval $username_field list insert end $tmp_list
		# Add binding to change profile when it's edited by hand
		bind $username_field <KeyRelease> "+after cancel [list ::loginScreen::usernameEdited $win]; after 1 [list ::loginScreen::usernameEdited $win]"

		# --------------------------------------------------
		# Create password label and field
		set password_frame [frame $fields.password_frame -bg white]
		set password_label [label $password_frame.password_label -bg white -borderwidth 0 -text "[trans pass]:"]
		set password_field [entry $password_frame.password -show "*" -bg white -relief solid -width 25]
		pack $password_label $password_field -anchor w -side top -pady 0
		# Bind password field so that pressing Enter/Return will start login
		bind $password_field <Return> "::loginScreen::loginScreenOk $win"

		# --------------------------------------------------
		# Create 'remember me' checkbutton
		set remember_me_field [checkbutton $fields.rem_me -bg white -text "[trans remember_me]" -variable ::loginScreen::remember_me]

		# --------------------------------------------------
		# Create 'remember my password' checkbutton
		set remember_password_field [checkbutton $fields.rem_pass -bg white -text "[trans rememberpass]" -variable [::config::getVar save_password]]

		# --------------------------------------------------
		# Create 'sign me in automatically' checkbutton
		set auto_login_field [checkbutton $fields.connect_on_start -bg white -text "[trans autoconnect2]" -onvalue 1 -offvalue 0 -variable [::config::getVar autoconnect]]

		# --------------------------------------------------
		# Create status label and combobox
		set choose_status_frame [frame $fields.choose_status_frame -bg white]
		set choose_status_label [label $choose_status_frame.status_label -bg white -text [trans signinstatus]]
		set choose_status [combobox::combobox $choose_status_frame.status -editable true -bg white -command remember_state_list]
		pack $choose_status_label $choose_status -side left -padx 2
		# Populate it
		# Standard states
		set i 0
		while { $i < 8 } {
			set statecode "[::MSN::numberToState $i]"
			set description "[trans [::MSN::stateToDescription $statecode]]"
			$choose_status list insert end $description
			incr i
		}
		# Custom states
		AddStatesToList $choose_status
		# Select remembered state
		$choose_status select [get_state_list_idx [::config::getKey connectas]]
		# Make it non-editable
		$choose_status configure -editable false

		# ------------------------------------------------
		# Create Sign in button
		set sign_in [button $win.signin -text [trans login] -command "::loginScreen::loginScreenOk $win" -cursor hand2]

		# ------------------------------------------------
		# Create useful links
		set links_frame [frame $win.links_frame -bg white]
		set forgot_password_link [button $links_frame.forgot -cursor hand2 -borderwidth 0 -highlightthickness 0 -relief flat -activebackground white -bg white -fg #777777 -text [trans forgot_pass] -command ""]
		set service_status_link [button $links_frame.service_status -cursor hand2 -borderwidth 0 -highlightthickness 0 -relief flat -activebackground white -bg white -fg #777777 -text [trans msnstatus] -command "launch_browser \"http://messenger.msn.com/Status.aspx\""]
		set new_account_link [button $links_frame.new_account -cursor hand2 -borderwidth 0 -highlightthickness 0 -relief flat -activebackground white -bg white -fg #777777 -text [trans new_account] -command ""]
		# Pack them
		pack $forgot_password_link $service_status_link $new_account_link -anchor w -side top -pady 2

		# Select first user
		$username_field select 0

		# Pack stuff
		pack $username_frame $password_frame $choose_status $remember_me_field $remember_password_field $auto_login_field -anchor w -side top -pady 2
		pack $dp $fields $sign_in -anchor n -pady 4
		pack $links_frame -anchor w -padx 4 -pady 16

		lower $bg

		# Pack login form
		pack forget .main -anchor n
		pack $win -expand true -fill both
	}
	
	proc usernameEdited { win } {
		# Get widget names
		set combo $win.fields.username_frame.username
		set dp_label $win.dp
		set remember_me_field $win.fields.rem_me
		set username [$combo get]

		# Check if the username has a profile.
		# If it does, switch to it, select the remember me box and set the DP.
		# If it doesn't, deselect the remember me box and set the DP to generic 'nopic' DP
		if { [LoginList exists 0 $username] } {
			$remember_me_field select
			$remember_me_field configure -state disabled
			ConfigChange $combo [$combo get]
			$dp_label configure -image displaypicture_std_self
		} else {
			$remember_me_field deselect
			$remember_me_field configure -state normal
			$dp_label configure -image [::skin::getDisplayPicture $username]
		}
	}
	
	proc userSelected { win combo username } {
		# Get widget names
		set combo $win.fields.username_frame.username
		set dp_label $win.dp
		set remember_me_field $win.fields.rem_me

		# We have to check whether this profile exists because sometimes userSelected gets called when it shouldn't,
		# e.g when tab is pressed in the username combobox
		if { [LoginList exists 0 $username] } {
			$remember_me_field select
			$remember_me_field configure -state disabled
			ConfigChange $combo $username
			$dp_label configure -image displaypicture_std_self
		}
	}
	
	proc loginScreenOk { win } {
		# Get user and pass
		set username [$win.fields.username_frame.username get]
		set password [$win.fields.password_frame.password get]
	
		# Check we actually have a username and password entered!
		if { $username == "" || $password == "" } { return }
	
		# If remember me checkbutton is selected and a profile doesn't already exists for this user, create a profile for them.
		if { $::loginScreen::remember_me } {
			if { ![LoginList exists 0 $username] } {
				CreateProfile $username
			}
		}
	
		# Login with them
		login $username $password
	}
	
	proc login { user pass } {
		global password
	
		# Set username and password key and global repsectively
		set password $pass
		::config::setKey login $user
	
		# Connect
		::MSN::connect $password
	}
}

#::loginScreen::createLoginScreen