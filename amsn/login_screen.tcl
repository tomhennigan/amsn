
::Version::setSubversionId {$Id$}

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

::loginScreen::createLoginScreen