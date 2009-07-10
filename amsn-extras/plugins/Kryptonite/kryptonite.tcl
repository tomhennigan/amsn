##############################################################################
#
# Kryptonite aMSN plugin v0.1b (BETA VERSION)    MSN GnuPG Encryption
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#
# A special thanks to: Daniel Aldana M., Claudio Salazar S., Youness Alaoui
# for beta testing Kryptonite.
#
#
#
# Official site :   http://www.moonix.cl/kryptonite/
# Mirror site   :   http://kryptonite.sourceforge.net
#
#
# Copyright (c) Cristian Orellana Escobar <core@moonix.cl>
#
##############################################################################




namespace eval ::Kryptonite {

	global HOME
	variable writable_directory [file join "$HOME" Kryptonite]
	variable plugin_name "Kryptonite"
	variable plugin_version "0.1b"
	variable kryptonite_url "http://www.moonix.cl/kryptonite/"
	variable compat_version [list $plugin_version 0.1 0.1RC1]
	variable gpg_cmd
	variable fingerprint_rcv_count
	variable keys_rcv_count
	variable pk_sent_count
	variable pk_expire_date
	variable key_id
	variable plugin_rcv_count
	variable users
	variable users_key_id
	variable lock_icon_window




	proc Init { dir } {
		variable writable_directory


		::plugins::RegisterPlugin Kryptonite
		::Kryptonite::RegisterEvents
		::Kryptonite::LoadLangFiles $dir

		array set ::Kryptonite::config {
			pk_transfer 1
}
set ::Kryptonite::configlist [list \
[list bool "[trans conftransferauto]" pk_transfer]]

if {[array names ::plugins::config Kryptonite] != ""} {
	array set ::Kryptonite::config $::plugins::config(Kryptonite)

}

create_dir $writable_directory

::Kryptonite::validate

::skin::setPixmap secure_chat secure.gif pixmaps [file join $dir pixmaps]

# Wrap the message
if {[info proc ::Kryptonite::Original_WriteSBRaw] == "" } {
	rename ::MSN::WriteSBRaw ::Kryptonite::Original_WriteSBRaw
}

proc ::MSN::WriteSBRaw { sbn data } {
	eval [list ::Kryptonite::WriteSBRaw $sbn $data]
}
}

proc DeInit { } {
	variable users




	if {[info proc ::Kryptonite::Original_WriteSBRaw] != "" } {
		rename ::MSN::WriteSBRaw ""
		rename ::Kryptonite::Original_WriteSBRaw ::MSN::WriteSBRaw
}

# If Kryptonite is unloaded, notify to the others users that have Kryptonite loaded
foreach username [array names users] {
	sendChatStatus $username "AUN"
	delSecureChat $username
}
}

proc RegisterEvents {} {
	::plugins::RegisterEvent Kryptonite ChangeState stateChanged
	::plugins::RegisterEvent Kryptonite chatwindow_closed windowClosed
	::plugins::RegisterEvent Kryptonite new_conversation newConversation
	::plugins::RegisterEvent Kryptonite OnConnect connected
	::plugins::RegisterEvent Kryptonite PacketReceived packetReceived
	::plugins::RegisterEvent Kryptonite user_joins_chat checkCaps
	::plugins::RegisterEvent Kryptonite user_leaves_chat userLeaves
}


proc LoadLangFiles {dir} {
	set langdir [file join $dir "lang"]
	set lang [::config::getGlobalKey language]
	load_lang en $langdir
	load_lang $lang $langdir
}

proc WriteSBRaw { sbn data } {
	set chatid [::MSN::ChatFor $sbn]

	if {$chatid != 0} {
		set user [::MSN::usersInChat $chatid]
		if { [llength $user] == 1 &&
			[lindex [split $data] 0] == "MSG" &&
			[::Kryptonite::getUserLevel $user] == 2 } {
				set msg [join [lrange [split $data \n] 1 end] \n]
				set encrypted_message [::Kryptonite::encryptMSG $user $msg]
				if { $encrypted_message == "" } {
					::Kryptonite::Original_WriteSBRaw $sbn $data
		}
		set messages [::Kryptonite::BuildMultipartMessages $user $encrypted_message]

		foreach data $messages {
			::Kryptonite::Original_WriteSBRaw $sbn $data
		}
	} else {
		::Kryptonite::Original_WriteSBRaw $sbn $data
	}
} else {
	::Kryptonite::Original_WriteSBRaw $sbn $data
}
}


proc connected { event evpar } {
	::Kryptonite::validate
}


# Unwrap the message
proc packetReceived { event evpar } {
	upvar 2 $evpar args
	upvar 2 $args(chatid) chatid
	upvar 2 $args(msg) message
	upvar 2 command command

	set sbn [::MSN::SBFor $chatid]
	if { $sbn == 0 } { return }

	set content_type [lindex [split [$message getHeader Content-Type] ";"] 0]

	set user [::MSN::usersInChat $chatid]
	if { [llength $user] != 1} {
		return
}


switch -- $content_type {
	application/x-kryptonite-data {
		if {[getUserLevel $user] == 2} {
			set plaintext [decryptMSG $user $message]
			set message_received [Message create %AUTO%]

			set plaintext [string map {"\n" "\r\n"} $plaintext]
			$message_received createFromPayload $plaintext

			$sbn handleMSG $command $message_received
		}

	}
	application/x-kryptonite-fingerprintinfo {
		fingerprintInfoReceived $user $message
		return
	}
	application/x-kryptonite-plugininfo {
		pluginInfoReceived $user $message
		return
	}
	application/x-kryptonite-publickey {
		keyReceived $user $message
		return
	}
	application/x-kryptonite-status {
		if {[getUserLevel $user] >= 1} {
			chatStatusReceived $user $message
			return
		}
	}
}
}

proc newConversation { event evpar } {
	upvar 2 $evpar args
	set chatid $args(chatid)

	set user [::MSN::usersInChat $chatid]
	if { [llength $user] != 1} {
		return
}

if {[getUserLevel $user] == 2} {
	addSecureChat $user
}
}

# Automatically log out user when his MSN status is offline.
proc stateChanged { event evpar } {
	upvar 2 $evpar args
	upvar 2 $args(user) username
	upvar 2 $args(substate) substate
	variable users
	variable users_key_id

	if { $username != [::config::getKey login] } {
		if { $substate == "FLN" } {
			if {[getUserLevel $username] > 0} {
				if {[info exists users_key_id($username)]} {
					unset users_key_id($chatid)
			}

			delSecureChat $username
		}
	}
} else {
	foreach user_name [array names users] {
		delSecureChat $user_name
	}
}
}


# Check for backward compatibility of Kryptonite versions.
proc compatVer { remote_plugin_version plugin_compat_vers} {
	variable plugin_version
	variable compat_version

	set remote_list [lsearch $plugin_compat_vers $plugin_version]
	set local_list [lsearch $compat_version $remote_plugin_version]

	if { $remote_list == -1 && $local_list == -1 } {
		return -1
} else {
	return 0
}


}


# Automatically log out user after window close.
proc windowClosed {event evpar } {
	upvar 2 $evpar args
	upvar 2 $args(chatid) chatid
	variable users
	variable users_key_id
	variable keys_rcv_count
	variable plugin_rcv_count
	variable pk_sent_count
	variable fingerprint_rcv_count
	variable lock_icon_window

	# If you are in a conference, return to it
	set user [::MSN::usersInChat $chatid]
	if { [llength $user] != 1} {
		return
}

set win_name [::ChatWindow::For $chatid]

if {[info exists users_key_id($chatid)]} {
	unset users_key_id($chatid)
}

catch {unset plugin_rcv_count($chatid)}


# If the contact has initiated session, log out him
if {[getUserLevel $user] != 0} {
	catch {unset users($chatid)}
	catch {unset pk_sent_count($chatid)}
	catch {unset keys_rcv_count($chatid)}
	catch {unset fingerprint_rcv_count($chatid)}

	if {[getUserLevel $user] == 2} {
		if { $win_name != 0 } {
			catch { unset lock_icon_window($win_name)}
			destroy_lock_icon $win_name
		}
	}
}
}


# To properly update a public key, we must first delete the old version of it, and then import the new version.
proc deleteKeys { user } {
	variable gpg_cmd
	variable writable_directory

	set remotedata_fp ""
	set remote_fingerprint_file [file join $writable_directory "[string map {@ _} $user]_delete_keys"]

	if {[catch { exec $gpg_cmd --no-secmem-warning --ignore-valid-from --ignore-time-conflict --fingerprint $user > $remote_fingerprint_file } res]}  {
		puts $res
		set status 0
		if { [lindex $::errorCode 0] eq "CHILDSTATUS" } {
			set status [lindex $::errorCode 2]
	} else {
		plugins_log Kryptonite "Failed updating the public key of $user: $::errorCode (deleteKeys)"
	}
	if { $status != 0 } {
		plugins_log Kryptonite "Error $::errorCode. Failed to execute : $res (deleteKeys)"
		::Kryptonite::validate
	}
	return
}

if {[catch { set fileID_remote_fp [open $remote_fingerprint_file] } res]} {
	plugins_log Kryptonite "Failed to open file  $remote_fingerprint_file: $res (deleteKeys)"
	return
} else {
	if {[catch { set remotedata_fp [read $fileID_remote_fp] } res]} {
		plugins_log Kryptonite "Failed to read file $remote_fingerprint_file: $res (deleteKeys)"
		catch { close $fileID_remote_fp }
		return
	}
	if {[catch { close $fileID_remote_fp } res]} {
		plugins_log Kryptonite "Failed to close file $remote_fingerprint_file: $res (deleteKeys)"
		return
	}
}

catch {file delete $remote_fingerprint_file}

# Verify if exists more of one fingerprint related to contact
# mail (this implies that the contact have more of one key).
# If it doesn't exist, then secondfp will be empty. If exists will
# have the last checked fingerprint.
set fp_list [split $remotedata_fp \n]
set fp_list_size [llength $fp_list]

# Obtain all the fingerprints
set x 0
while { $x < [expr {$fp_list_size - 5}]} {
	if { [string first pub [lindex $fp_list $x]] == 0} {
		set pub_info [lindex $fp_list $x]
		set key_id_info [string range $pub_info \
		[expr {[string first / $pub_info] + 1}] \
		[expr {[string first / $pub_info] + 8}]]

		set fp_info [lindex $fp_list [expr {$x + 1}]]
		set fingerprint [string range $fp_info \
		[expr {[string last = $fp_info] + 1}] end-1]

		set uid [lindex $fp_list [expr {$x + 2}]]
		set email [string range $uid [string last < $uid] end-1]

		set sub_info [lindex $fp_list [expr {$x + 3}]]

		if { $email == "<$user>" } {
			if {[catch { exec $gpg_cmd --no-secmem-warning --batch --yes --delete-key "0x$key_id_info" } res] } {
				plugins_log Kryptonite "Failed to delete public key 0x$key_id_info of $user: $res (deleteKeys)"
				::Kryptonite::validate
			}
		}
		incr x 5
	} else {
		incr x
	}
}
}


# Get local fingerprint from default keyring.
proc localFingerprint { } {
	variable gpg_cmd
	variable writable_directory
	variable pk_expire_date
	variable key_id

	set localdata_fp ""
	set key_expired 0
	set mapped_login [string map {@ _} [::config::getKey login]]
	set local_fingerprint_file [file join $writable_directory ${mapped_login}_fingerprint]
	if {[catch { exec $gpg_cmd --no-secmem-warning --ignore-valid-from --ignore-time-conflict --fingerprint [::config::getKey login] > $local_fingerprint_file} res]} {
		puts $res
		set status 0
		if { [lindex $::errorCode 0] eq "CHILDSTATUS" } {
			set status [lindex $::errorCode 2]
	} else {
		plugins_log Kryptonite "Error to get the local fingerprint: $::errorCode (localFingerprint)"
	}

	if { $status != 0 } {
		plugins_log Kryptonite "Error $::errorCode. Failed to execute : $res (localFingerprint)"
		msg_box "[trans errorkeygen] [::abook::getPersonal login]"
		plugins_log Kryptonite "Doesn't exist a keys pair for [::abook::getPersonal login] (localFingerprint)"
		::plugins::UnLoadPlugin	"Kryptonite"
	};# else error but don't unload plugin ?
	return
}

if {[catch { set fileID_local_fp [open $local_fingerprint_file] } res]} {
	plugins_log Kryptonite "Failed To open file $local_fingerprint_file: $res (localFingerprint)"
	return
}

if {[catch { set localdata_fp [read $fileID_local_fp] } res]} {
	plugins_log Kryptonite "Failed to read file $local_fingerprint_file: $res (localFingerprint)"
	return
}


if {[catch { close $fileID_local_fp } res]} {
	plugins_log Kryptonite "Failed to close file $local_fingerprint_file: $res (localFingerprint)"
	return
}

if { [file exists $local_fingerprint_file] } {
	catch {file delete $local_fingerprint_file}
}

# Verify if exists more of one fingerprint related to my
# mail (this implies that i have more of one key).
# If doesn't exist, then secondfp will be empty. If exists will
# have the last checked fingerprint.

set fp_list_size [llength [split $localdata_fp \n]]
set fp_list [split $localdata_fp \n]

# Obtain all the fingerprints
set pk_fingerprint ""
set current_date [clock seconds]

set x 0
while { $x < [expr {$fp_list_size - 5}]} {
	if { [string first pub [lindex $fp_list $x]] == 0} {
		set pub_info [lindex $fp_list $x]
		set key_id_info [string range $pub_info [expr {[string first "/" $pub_info] + 1}] [expr {[string first "/" $pub_info] + 8}]]

		set fp_info [lindex $fp_list [expr {$x + 1}]]
		set fingerprint [string range $fp_info [expr {[string last = $fp_info] + 1}] end]

		set uid [lindex $fp_list [expr {$x + 2}]]
		set email [string range $uid [string last "<" $uid] end]

		set sub_info [lindex $fp_list [expr {$x + 3}]]


		# Check in case a single key has multiple emails associated with it
		while { $email != "<[::config::getKey login]>" &&
			[string first uid $sub_info] == 0 } {
				incr x
				set uid [lindex $fp_list [expr {$x + 2}]]
				set email [string range $uid [string last "<" $uid] end]
				set sub_info [lindex $fp_list [expr {$x + 3}]]
		}

		if {$email == "<[::config::getKey login]>"} {
			set pk_expire_date ""
			if { [string last "expires:" $pub_info] != -1 } {
				set pk_expire_date [string range $pub_info [expr {[string last ":" $pub_info] + 2}] end-1]
				set pk_expire_date [clock scan $pk_expire_data -format "%Y-%m-%d"]
			}

			# Validate expiration
			# When a key available is found, it gets out from loop

			if { $pk_expire_date == "" ||
				( $pk_expire_date != "" &&
				$current_date < $pk_expire_date )} {
					set key_id $key_id_info
					set key_id "0x$key_id"
					set pk_fingerprint $fingerprint
					set key_expired 0
					break
			} else {
				if { $pk_expire_date != "" && $current_date >= $pk_expire_date} {
					set key_expired 1
				}
			}
		}
		incr x 5

	} else {
		incr x
	}

}

if { $key_expired == 1} {
	msg_box "[trans expiredkey [::config::getKey login]]"
	plugins_log Kryptonite "Public key of [::config::getKey login] expired (localFingerprint)"
	::plugins::UnLoadPlugin	"Kryptonite"
	return
}

if {[string length $pk_fingerprint] > 51 } {
	msg_box "[trans badkey [::abook::getPersonal login]]"
	plugins_log Kryptonite "Malformed fingerprint (localFingerprint)"
	::plugins::UnLoadPlugin	"Kryptonite"
	return
}

if { [string length $pk_fingerprint] == 0 } {
	msg_box "[trans novalidkey]"
	::plugins::UnLoadPlugin	"Kryptonite"
	return

}
return $pk_fingerprint
}









# Get remote fingerprint from default keyring.
proc remoteFingerprint { chatid } {
	variable gpg_cmd
	variable writable_directory
	variable users_key_id

	set remotedata_fp ""

	set mapped_chatid [string map {@ _} $chatid]
	set remote_fingerprint_file [file join $writable_directory ${mapped_chatid}_fingerprint]

	if {[catch { exec $gpg_cmd --no-secmem-warning --ignore-valid-from --ignore-time-conflict --fingerprint $chatid > $remote_fingerprint_file } res]}  {
		puts $res
		set status 0
		if { [lindex $::errorCode 0] eq "CHILDSTATUS" } {
			set status [lindex $::errorCode 2]
	} else {
		plugins_log Kryptonite "Failed to get the remote fingerprint for $chatid: $::errorCode (remoteFingerprint)"
	}
	if { $status != 0 } {
		plugins_log Kryptonite "Failed to get the remote fingerprint for $chatid $::errorCode. Failed to execute: $res (remoteFingerprint)"
		::Kryptonite::validate
	}
	return
}

if {[catch { set fileID_remote_fp [open $remote_fingerprint_file] } res]} {
	plugins_log Kryptonite "Failed To open file $remote_fingerprint_file: $res (remoteFingerprint)"
	return
}

if {[catch { set remotedata_fp [read $fileID_remote_fp] } res]} {
	plugins_log Kryptonite "Failed to read file $remote_fingerprint_file: $res (remoteFingerprint)"
	return
}

if {[catch { close $fileID_remote_fp } res]} {
	plugins_log Kryptonite "Failed to close file $remote_fingerprint_file: $res (remoteFingerprint)"
	return
}

if { [file exists $remote_fingerprint_file] } {
	catch {file delete $remote_fingerprint_file}
}


# Verify if exists more of one fingerprint related to contact
# mail (this implies that the contact have more of one key).
# If doesn't exist, then secondfp will be empty. If exists will
# have the last checked fingerprint.

set fp_list_size [llength [split $remotedata_fp \n]]
set fp_list [split $remotedata_fp \n]
set fingerprint_count 0

# Obtain all the fingerprints

set remote_pk_fingerprint ""
set current_date [clock seconds]

set x 0
while { $x < [expr $fp_list_size -5]} {
	if { [string first pub [lindex $fp_list $x]] == 0} {
		set pub_info [lindex $fp_list $x]
		set key_id_info [string range $pub_info [expr {[string first "/" $pub_info] + 1}] [expr {[string first "/" $pub_info] + 8}]]

		set fp_info [lindex $fp_list [expr {$x + 1}]]
		set fingerprint [string range $fp_info [expr {[string last "=" $fp_info] + 1}] end]

		set uid [lindex $fp_list [expr {$x + 2}]]
		set email [string range $uid [string last "<" $uid] end]

		set sub_info [lindex $fp_list [expr {$x + 3}]]

		# Check in case a single key has multiple emails associated with it
		while { $email != "<$chatid>" &&
			[string first uid $sub_info] == 0 } {
				incr x
				set uid [lindex $fp_list [expr {$x + 2}]]
				set email [string range $uid [string last "<" $uid] end]
				set sub_info [lindex $fp_list [expr {$x + 3}]]
		}

		if { $email == "<$chatid>" } {
			set remote_pk_expire_date ""
			if { [string last "expires:" $pub_info] != -1 } {
				set remote_pk_expire_date [string range $pub_info [expr {[string last ":" $pub_info] + 2}] end-1]
				set pk_expire_date [clock scan $pk_expire_data -format "%Y-%m-%d"]
			}

			# Only is permited one public key per contact, if
			# exists more must be deleted
			# This is done to correctly update the contact public
			# key.
			if { $fingerprint_count != 0 } {
				;# TO CHECK : safe to delete stuff ?
				deleteKeys $chatid
				set remote_pk_fingerprint ""
				break
			}


			# Validate expiration
			if { $remote_pk_expire_date == "" ||
				($remote_pk_expire_date != "" &&
				$current_date < $remote_pk_expire_date)} {
					set remote_pk_fingerprint $fingerprint
					set fingerprint_count 1

					# Validate that 'key_id_info' is hexadecimal and 8 char long
					if { [string is xdigit $key_id_info] &&
						[string length $key_id_info] == 8}  {
							set users_key_id($chatid) "0x$key_id_info"
				}
			} else {
				if { $remote_pk_expire_date != "" && $current_date >= $remote_pk_expire_date} {
					plugins_log Kryptonite "Public key of $chatid expired (remoteFingerprint)"
					set remote_pk_fingerprint ""
				}
			}
		}
		incr x 5

	} else {
		incr x
	}

}

return $remote_pk_fingerprint
}

proc sendPluginInfo { chatid } {
	variable plugin_name
	variable plugin_version
	variable compat_version

	set sbn [::MSN::SBFor $chatid]
	if { $sbn == 0 } { return }
	if { [string first "@" $chatid] == -1} {
		return
}
set packet_info "Plugin-Name: $plugin_name\r\n"
append packet_info "Plugin-Version: $plugin_version\r\n"
append packet_info "Compat: $compat_version\r\n"
append packet_info "Content-Type: application/x-kryptonite-plugininfo\r\n\r\n"
set packet_info_length [string length $packet_info]
::MSN::WriteSBNoNL $sbn "MSG" "A $packet_info_length\r\n$packet_info"
}



proc pluginInfoReceived { chatid message } {
	variable plugin_name
	variable plugin_version
	variable kryptonite_url
	variable users
	variable plugin_rcv_count

	if { [string first @ $chatid] == -1} {
		return
}

# Only if the contact hasn't initiated session, process the received plugin information
if {[getUserLevel $chatid] == 0} {

	if {![info exists plugin_rcv_count($chatid)]} {
		set remote_plugin_name "[$message getHeader Plugin-Name]"
		set remote_plugin_version "[$message getHeader Plugin-Version]"
		set plugin_compat_vers "[$message getHeader Compat]"
		set level 1

		if {$remote_plugin_name == "" ||
			$remote_plugin_version == "" ||
			$plugin_compat_vers == ""} {
				return -1
		}


		if { $plugin_name == $remote_plugin_name } {
			set vers [compatVer $remote_plugin_version $plugin_compat_vers]

			if { $vers == -1 } {
				set win_name [::ChatWindow::MakeFor $chatid]
				if { $win_name != 0 } {
					::amsn::WinWrite $chatid "\n[trans compaterror $plugin_version $chatid $remote_plugin_version $kryptonite_url]\n" red
				}
				return
			}

			set plugin_rcv_count($chatid) 1
			set users($chatid) $level
			sendFingerprintInfo $chatid
			return 0
		}
	}


}

}


# Send our fingerprint to chatid

proc sendFingerprintInfo { chatid } {
	set sbn [::MSN::SBFor $chatid]
	if { $sbn == 0 } { return }
	if { [string first "@" $chatid] == -1} {
		return
}
set fingerprint_info "Content-Type: application/x-kryptonite-fingerprintinfo\r\n"
append fingerprint_info "LFingerprint: [localFingerprint]\r\n"
append fingerprint_info "RFingerprint: [remoteFingerprint $chatid]\r\n\r\n"
append fingerprint_info_length [string length $fingerprint_info]
::MSN::WriteSBNoNL $sbn "MSG" "A $fingerprint_info_length\r\n$fingerprint_info"
}

# Send our GnuPG public key to chatid
proc sendKey { chatid  } {
	variable gpg_cmd
	variable key_id
	variable writable_directory

	set sbn [::MSN::SBFor $chatid]
	if { $sbn == 0 } { return }
	if { [string first "@" $chatid] == -1} {
		return
}

set mapped_login [string map {@ _} [::config::getKey login]]
set filename_public_key [file join $writable_directory ${mapped_login}_public.key]


if {[catch { exec $gpg_cmd --no-secmem-warning --export -a $key_id > $filename_public_key} res]} {
	plugins_log Kryptonite "Failed to export personal public key: $res (sendKey)"
	::Kryptonite::validate
}

if {[catch { set fileID_asc [open $filename_public_key] } res]} {
	plugins_log Kryptonite "Failed To open file $filename_public_key: $res (sendKey)"
	return
}

if {[catch { set data [read $fileID_asc] } res]} {
	plugins_log Kryptonite "Failed to read file $filename_public_key: $res (sendKey)"
	return
}

if {[catch { close $fileID_asc } res]} {
	plugins_log Kryptonite "Failed to close file $filename_public_key: $res (sendKey)"
	return
}

if { [file exists $filename_public_key] } {
	catch {file delete $filename_public_key}
}



set key_message [split $data \r]
set key_message [string trim $key_message "{}"]

set total [expr int (ceil ([string length $key_message] / 400.0))]

set msgid "[format %X [myRand 4369 65450]][format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [expr { int([expr {rand() * 1000000}])%65450 } ] + 4369]-[format %X [myRand 4369 65450]][format %X [myRand 4369 65450]][format %X [myRand 4369 65450]]"

set key_message [encoding convertfrom utf-8 $key_message]

for {set part 0 } { $part < $total } { incr part } {
	set first [expr {$part * 400}]

	if { $part == [expr {$total-1}] } {
		set last [string length $key_message]
	} else {
		set last [expr {$first + 399}]
	}

	set chunk [string range $key_message $first $last]
	set packet ""

	if {$part == 0 } {
		append packet "MIME-Version: 1.0\r\n"
		append packet "Content-Type: application/x-kryptonite-publickey\r\n"

		if { $total == 1 } {
			append packet "\r\n$chunk"
						} else {
							append packet "Message-ID: \{$msgid\}\r\nChunks: $total\r\n\r\n$chunk"
						}

				} else {
					append packet "Message-ID: \{$msgid\}\r\nChunk: $part\r\n\r\n$chunk"
				}

				set packet_length [string length $packet]
				::MSN::WriteSBNoNL $sbn "MSG" "U $packet_length\r\n$packet"
}
}







proc validate { } {
	variable writable_directory
	variable gpg_cmd
	set gpg_cmd "gpg2"

	if {[catch { exec $gpg_cmd --no-secmem-warning --help} res]} {
		puts $res
		set gpg_cmd "gpg"
		if {[catch { exec $gpg_cmd --no-secmem-warning --help} res]} {
			msg_box "[trans gpgerror]"
			plugins_log Kryptonite "Failed to execute $gpg_cmd: $res (validate)"
			::plugins::UnLoadPlugin	"Kryptonite"
			return 0
	}
}

localFingerprint
}






# If the contact leaves the conversation, the session is closed
proc userLeaves {event evpar } {
	upvar 2 $evpar args
	upvar 2 $args(chatid) chatid
	upvar 2 $args(usr_name) usr_name
	variable users_key_id

	set win_name [::ChatWindow::For $chatid]

	if { $chatid == $usr_name} {
		if {[info exists users_key_id($chatid)]} {
			unset users_key_id($chatid)

	}

	# Verify if the conversation with the contact was previously
	# crypted, if is true send the encrypted messages, else return.
	if {[getUserLevel $chatid] != 0} {
		delSecureChat $chatid
		return
	}
}
}





# Bar where the padlock icon is allocated when the conversation is encrypted
proc status_iconbar { w image} {
	set iconbar [$w.statusbar getinnerframe].icon_bar
	text $iconbar -width 2 -height 1 -wrap none \
	-font splainf -borderwidth 0 -background [::skin::getKey statusbarbg] -foreground [::skin::getKey statusbartext]\
	-highlightthickness 0 -pady 0
	pack $iconbar -side right -expand false -padx 0 -pady 0 -anchor e
	set id_img [$iconbar image create end -image $image]
	$iconbar configure -state disabled
	return $iconbar
}



# Padlock icon for encrypted conversations
proc lock_icon { win_name } {
	variable plugin_version
	destroy [$win_name.statusbar getinnerframe].icon_bar
	set secure_chat_pixmap [status_iconbar ${win_name} [::skin::loadPixmap secure_chat]]
	set_balloon  [$win_name.statusbar getinnerframe].icon_bar "[trans cryptcon] (Kryptonite v$plugin_version)"
}



# Delete the padlock icon
proc destroy_lock_icon { win_name } {
	if {$win_name != 0 } {
		destroy [$win_name.statusbar getinnerframe].icon_bar
}
}


# Procedure in charge of send the plugin information when a contact
# joins to p2p conversation

proc checkCaps {event evpar} {
	upvar 2 $evpar args
	upvar 2 $args(chatid) chatid
	upvar 2 $args(win_name) win_name
	variable users
	variable fingerprint_rcv_count
	variable plugin_rcv_count
	variable keys_rcv_count
	variable pk_sent_count
	variable lock_icon_window

	set win_name [::ChatWindow::For $chatid]

	if { [string first @ $chatid] == -1} {
		set users_in_chat [::MSN::usersInChat $chatid]
		set old_user [lindex $users_in_chat 0]
		set win_name_old_user [::ChatWindow::For $old_user]

		# Log out the contact who has invited another to the conference,
		# only if is not kept a private with him, in opposite case
		# return.

		if { $win_name_old_user != "0"} {
			return
	}

	if {[getUserLevel $old_user] != 0} {
		unset users($old_user)
	}

	catch { unset fingerprint_rcv_count($old_user) }
	catch { unset plugin_rcv_count($old_user) }
	catch { unset keys_rcv_count($old_user) }
	catch { unset pk_sent_count($old_user) }

	if { $win_name != 0 } {
		if {[catch { unset lock_icon_window($win_name) } res] == 0 } {
			destroy_lock_icon $win_name
		}
	}

	return
}


sendPluginInfo $chatid
}



# Process the fingerprint received from contact
proc fingerprintInfoReceived { chatid message } {
	variable plugin_name
	variable pk_sent_count
	variable fingerprint_rcv_count

	# If I am in a conference, return
	if { [string first @ $chatid] == -1} {
		return
}


if {[getUserLevel $chatid] == 1 } {

	if {![info exists fingerprint_rcv_count($chatid)]} {
		set fingerprint_rcv_count($chatid) 0
	}


	# Can be received up to 2 messages with fingerprint information per session
	if {[set fingerprint_rcv_count($chatid)] < 3 } {
		set user_fingerprint_from_remote "[$message getHeader LFingerprint]"
		set self_fingerprint_from_remote "[$message getHeader RFingerprint]"

		if { [llength $user_fingerprint_from_remote] == 0 } {
			plugins_log Kryptonite "The contact $chatid doesn't have public key, or has a problem with it (fingerprintInfoReceived)"
			return -1
		}

		# Check if the contact has my correct public key
		if { $self_fingerprint_from_remote == [localFingerprint] } {
			#If it's true, and moreover the contact has the plugin and the
			#correct version so is in conditions of encrypt and decrypt
			#messages; else send my public key.

			if { $user_fingerprint_from_remote == [remoteFingerprint $chatid] } {
				addSecureChat $chatid
			}
		} else {
			if { $::Kryptonite::config(pk_transfer) == 1 } {
				#  Send the public key just one time per session
				if {![info exists pk_sent_count($chatid)]} {
					sendKey $chatid
					set pk_sent_count($chatid) 1
				}
			} else {
				set win_name [::ChatWindow::MakeFor $chatid]
				if { $win_name != 0 } {
					delSecureChat $chatid
					::amsn::WinWrite $chatid "\n[trans transferproblem $chatid $plugin_name]\n" red
					sendChatStatus $chatid "KSR"
				}
			}
		}

		incr fingerprint_rcv_count($chatid)

	}
}
}


# Import the contact public key
proc importKey { filename_publickey_received } {
	variable gpg_cmd
	if {[catch { exec $gpg_cmd --no-secmem-warning --import --quiet --ignore-valid-from --ignore-time-conflict  $filename_publickey_received } res] } {
		puts $res
		set status 0
		if { [lindex $::errorCode 0] eq "CHILDSTATUS" } {
			set status [lindex $::errorCode 2]
	} else {
		plugins_log Kryptonite "Failed to import the public key: $::errorCode (importKey)"
		return 0
	}

	if { $status != 0 } {
		plugins_log Kryptonite "Failed to import the public key: $res (importKey)"
		return 0
	}

}
return 1
}



# Verify that the contact public key is correctly related with the mail
# of MSN contact
proc checkValidKey {chatid filename} {

	variable gpg_cmd
	variable writable_directory

	set mapped_chatid [string map {@ _} $chatid]
	set filename_publickey_received [file join $writable_directory ${mapped_chatid}_list_packets]

	if {[catch { exec $gpg_cmd --no-secmem-warning --ignore-valid-from --ignore-time-conflict --list-packets $filename > $filename_publickey_received } res]}  {
		puts $res
		set status 0
		if { [lindex $::errorCode 0] eq "CHILDSTATUS" } {
			set status [lindex $::errorCode 2]
	} else {
		plugins_log Kryptonite "Failed to validate the public key of  $chatid: $::errorCode (checkValidKey)"
	}

	if { $status != 0 } {
		plugins_log Kryptonite "Failed to validate the public key of $chatid $::errorCode. Failed to execute : $res (checkValidKey)"
		::Kryptonite::validate
	}
}



if {[catch { set file_pk_rcv [open $filename_publickey_received] } res]} {
	plugins_log Kryptonite "Failed To open file $filename_publickey_received: $res (checkValidKey)"

}

if {[catch { set data [read $file_pk_rcv] } res]} {
	plugins_log Kryptonite "Failed to read file $filename_publickey_received: $res (checkValidKey)"

}

if {[catch { close $file_pk_rcv } res]} {
	plugins_log Kryptonite "Failed to close file $filename_publickey_received: $res (checkValidKey)"

}

if { [file exists $filename_publickey_received] } {
	file delete $filename_publickey_received
}


set data_size [llength [split $data \n]]	
set data_list [split $data \n]

foreach line $data_list {
	if {[string first ":user ID packet:" $line] == 0} {
		set uid $line
		set uid_length [string length $uid]
		set email [string range $uid [string last < $uid] [expr $uid_length -2]]   
		set email [string trim $email <]
		set email [string trim $email >] 		
		if { $email == "$chatid" } {	
			return 1

		} else {
			plugins_log Kryptonite "ID $email NOT correspond to mail of MSN: ($chatid) (checkValidKey)"
			return 0    			
		} 
	}
}



}








# Process the received public key from the contact

proc keyReceived { chatid message } {
	variable writable_directory
	variable keys_rcv_count


	set body_msg [$message getBody]

	set mapped_chatid [string map {@ _} $chatid]


	# If I am in a conference, return

	if { [string first @ $chatid] == -1} {					
		return		
}	



if {[getUserLevel $chatid] == 1 } {	

	if { $::Kryptonite::config(pk_transfer) == 1 } { 	
		if {[catch { puts [set keys_rcv_count($chatid)]} res]} {
			puts $res

			set filename_publickey_received [file join $writable_directory ${mapped_chatid}_publickey_received]
			set status_code "PKI"


			if {[catch { set file_publickey_received [open $filename_publickey_received "w" 0600] } res]} {
				plugins_log Kryptonite "Failed To open file $filename_publickey_received: $res (keyReceived)"

			}


			flush $file_publickey_received
			puts -nonewline $file_publickey_received $body_msg


			if {[catch { close $file_publickey_received } res]} {
				plugins_log Kryptonite "Failed to close file $filename_publickey_received: $res (keyReceived)"

			}


			if {[checkValidKey $chatid $filename_publickey_received] != 1 } {

				plugins_log Kryptonite "ID does not correspond to mail of MSN (keyReceived)"			
			}

			deleteKeys $chatid		

			if {[importKey $filename_publickey_received]} {
				sendFingerprintInfo $chatid		
				sendChatStatus $chatid $status_code
			}
			set keys_rcv_count($chatid) 1

			if { [file exists $filename_publickey_received] } {
				file delete $filename_publickey_received
			}


		}		

	} else {
		sendChatStatus $chatid "KRR"
		set win_name [::ChatWindow::MakeFor $chatid]
		if { $win_name != 0 } {					
			delSecureChat $chatid
			::amsn::WinWrite $chatid "\n[trans ultimately_error $chatid $plugin_name $chatid]\n" red
			return
		}


	}


}


}




# Initiate session


proc addSecureChat { chatid } {

	variable users

	set level 2		
	set users($chatid) $level
	set win_name [::ChatWindow::For $chatid]
	if { $win_name != 0 } {	
		if {[setLockIconStatus $win_name] == 1 } {
			lock_icon $win_name
	}
}


}



# Close session

proc delSecureChat { chatid } {
	variable users
	variable keys_rcv_count
	variable plugin_rcv_count
	variable pk_sent_count		
	variable fingerprint_rcv_count
	variable lock_icon_window

	unset users($chatid)


	set win_name [::ChatWindow::For $chatid]
	if { $win_name != 0 } {
		if {[catch { unset lock_icon_window($win_name) } res] == 0 } {
			destroy_lock_icon $win_name
	}

}		

if {[catch { unset fingerprint_rcv_count($chatid) } res] == 0} {

}

if {[catch { unset plugin_rcv_count($chatid) } res] == 0} {

}		

if {[catch { unset keys_rcv_count($chatid) } res] == 0} {

}

if {[catch { unset pk_sent_count($chatid) } res] == 0} {

}


}









proc setLockIconStatus { win } {
	variable lock_icon_window

	if {![info exists lock_icon_window($win)]} {
		set lock_icon_window($win) 1
		return 1
} else {
	return 0
}


}






proc BuildMultipartMessages { chatid encrypted_message} {


	set sbn [::MSN::SBFor $chatid]
	if { $sbn == 0 } { return }

	set total [expr int (ceil ([string length $encrypted_message] / 400.0))]
	set msgid "[format %X [myRand 4369 65450]][format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [expr { int([expr {rand() * 1000000}])%65450 } ] + 4369]-[format %X [myRand 4369 65450]][format %X [myRand 4369 65450]][format %X [myRand 4369 65450]]"

	for {set part 1 } { $part <= $total } { incr part } {


		set first [expr ($part-1)*400]

		if { $part != $total } {
			set last [expr $first+399]
		} else {
			set last [string length $encrypted_message]
		}

		set chunk [string range $encrypted_message $first $last]
		set packet ""

		if {$part == 1 } {
			set packet "MIME-Version: 1.0\r\nContent-Type: application/x-kryptonite-data\r\n"


			if { $total == 1 } {
				set packet "${packet}\r\n$chunk"
			} else {
				set packet "${packet}Message-ID: \{$msgid\}\r\nChunks: $total\r\n\r\n$chunk"
			}


		} else {
			set packet "${packet}Message-ID: \{$msgid\}\r\nChunk: [expr $part-1]\r\n\r\n$chunk"
		}



		set packet_length [string length $packet]
		set packet "MSG [incr ::MSN::trid] A $packet_length\r\n$packet"
		lappend messages_list $packet

}

return $messages_list

}	




# Process the received encrypted message 

proc decryptMSG { chatid message} {
	variable gpg_cmd
	variable writable_directory
	variable key_id               


	set mapped_chatid [string map {@ _} $chatid]
	set filename_msg_received [file join $writable_directory ${mapped_chatid}_rcv]
	set outfile [file join $writable_directory outfile_${mapped_chatid}]
	set error_code "RRE"


	if {[catch { set file_msg_received [open $filename_msg_received "w" 0600] } res]} {
		plugins_log Kryptonite "Failed To open file $filename_msg_received: $res (decryptMSG)"
		errorMessage $res $chatid $error_code 0
		return
}



flush $file_msg_received
puts -nonewline $file_msg_received [$message getBody]



if {[catch { close $file_msg_received } res]} {
	plugins_log Kryptonite "Failed to close file $filename_msg_received: $res (decryptMSG)"
	errorMessage $res $chatid $error_code 0
	if { [file exists $filename_msg_received] } {
		file delete $filename_msg_received
	}
	return		
	}



	if { [file exists $outfile] } {
		file delete $outfile
}




if {[catch { exec $gpg_cmd --no-secmem-warning  --ignore-valid-from --ignore-time-conflict -u $key_id --use-agent --output $outfile --batch -q --decrypt $filename_msg_received } res]} {
	puts "$res"

	set status 0
	if { [lindex $::errorCode 0] eq "CHILDSTATUS" } {
		set status [lindex $::errorCode 2]
	} else {
		plugins_log Kryptonite "Failed to decrypt the message from $chatid: $::errorCode (decryptMSG)"
	}

	if { $status != 0 } {
		plugins_log Kryptonite "Failed to decrypt the message from $chatid: $res (decryptMSG)"
		errorMessage $res $chatid $error_code 0
		::Kryptonite::validate
		return
	}
}


if {[catch { set fileID_decrypted [open $outfile] } res]} {
	plugins_log Kryptonite "Failed To open file $outfile: $res (decryptMSG)"
	errorMessage $res $chatid $error_code 0
	return
}

if {[catch { set data [read $fileID_decrypted] } res]} {
	plugins_log Kryptonite "Failed to read file $outfile: $res (decryptMSG)"
	errorMessage $res $chatid $error_code 0
	if { [file exists $outfile] } {
		file delete $outfile
	}
	return
}

if {[catch { close $fileID_decrypted } res]} {
	plugins_log Kryptonite "Failed to close file $outfile: $res (decryptMSG)"
	errorMessage $res $chatid $error_code 0
	if { [file exists $outfile] } {
		file delete $outfile
	}
	return
}

if { [file exists $outfile] } {
	file delete $outfile
}

if { [file exists $filename_msg_received] } {
	file delete $filename_msg_received
}	

set data [string range $data 0 [expr [string length $data]-2]]
return $data	


}





# Send status events during a session

proc sendChatStatus { chatid status } {

	set sbn [::MSN::SBFor $chatid]
	if { $sbn == 0 } { return }
	if { [string first "@" $chatid] == -1} {			
		return		
}
set packet "MIME-Version: 1.0\r\n"
set packet "${packet}Content-Type: application/x-kryptonite-status\r\n"
set packet "${packet}Status: $status\r\n\r\n"
set packet_length [string length $packet]
::MSN::WriteSBNoNL $sbn "MSG" "A $packet_length\r\n$packet"

}







# Process received status events
#
# Error codes:
#	
# PKI: Remote public key correctly imported
# KRR: The contact doesn't have my public key, and have disabled the automatic key transfer
# KSR: I don't have a updated version of contact's public key, and I have disabled the automatic key transfer 
# AUN: The contact has disabled Kryptonite
# RPE: The contact has got problems encrypting a message
# RRE: The contact hasn't achieved to decrypt a message that I send to 	him
#

proc chatStatusReceived { chatid message } {

	variable plugin_name


	if { [string first @ $chatid] == -1} {					
		return		
}	

set status "[$message getHeader Status]"
set win_name [::ChatWindow::MakeFor $chatid] 

if { $status == "" } {
	return -1
}


if {[getUserLevel $chatid] >= 1 } {

	if { $status == "PKI" } {
		sendFingerprintInfo $chatid
		return		
	}



	if { $status == "KRR" } {
		if { $win_name != 0 } {					
			::amsn::WinWrite $chatid "\n [trans krr_error $chatid]\n" red
		}				
		return
	}

	if { $status == "KSR" } {
		if { $win_name != 0 } {	
			::amsn::WinWrite $chatid "\n[trans ksr_error $chatid $plugin_name]\n" red
		}				
		return
	}

	if { $status == "AUN" } {
		if { $win_name != 0 } {
			::amsn::WinWrite $chatid "\n[trans aun_error $chatid]\n" red
		}
		delSecureChat $chatid

	}

	if {[getUserLevel $chatid] == 2 } {
		if { $status == "RPE" } {
			if { $win_name != 0 } {	
				::amsn::WinWrite $chatid "\n[trans rpe_error $chatid]\n" red
			}					
			delSecureChat $chatid		
			return		
		}


		if { $status == "RRE" } {
			if { $win_name != 0 } {	
				::amsn::WinWrite $chatid "\n[trans rre_error $chatid]\n" red
			}					
			delSecureChat $chatid		
			return		
		}		

	}

}


}








# Send an encrypted message


proc encryptMSG { chatid msg} { 
	variable users_key_id	
	variable gpg_cmd
	variable writable_directory	

	# Verify that a key_id exists for the user 


	if {![info exists users_key_id($chatid)]} {
		return
} 

set user_key [set users_key_id($chatid)]

set mapped_chatid [string map {@ _} $chatid]
set filename_plain_text [file join $writable_directory ${mapped_chatid}_to_sent]
set filename_encrypted_text "$filename_plain_text.asc"
set error_code "RPE"

if {[catch { set fileID_plain [open $filename_plain_text "w" 0600] } res]} {
	plugins_log Kryptonite "Failed To open file $filename_plain_text: $res (encryptMSG)"	
	if {[errorMessage $res $chatid $error_code 1] == 0} {
		set msg ""			 			
	}
	return
}



if {[catch { puts $fileID_plain $msg } res]} {
	plugins_log Kryptonite "Failed to write in file $filename_plain_text: $res (encryptMSG)"
	if {[errorMessage $res $chatid $error_code 1] == 0} {
		set msg ""			 			
	}
	if { [file exists $filename_plain_text] } {
		file delete $filename_plain_text
	}

	return		
}

if {[catch { close $fileID_plain } res]} {
	plugins_log Kryptonite "Failed to close file $filename_plain_text: $res (encryptMSG)"
	if {[errorMessage $res $chatid $error_code 1] == 0} {
		set msg ""			 			
	}

	if { [file exists $filename_plain_text] } {
		file delete $filename_plain_text
	}
	return		
}		



if { [file exists $filename_encrypted_text] } {

	file delete $filename_encrypted_text

}


if {[catch { exec $gpg_cmd --no-secmem-warning --ignore-valid-from --ignore-time-conflict --armor --batch -e --always-trust -r $user_key $filename_plain_text } res]} {
	puts $res
	set status 0			
	if { [lindex $::errorCode 0] eq "CHILDSTATUS" } {
		set status [lindex $::errorCode 2]

	} else {
		plugins_log Kryptonite "Failed to send the message to  $chatid: $::errorCode (encryptMSG)"
	}

	if { $status != 0 } {
		plugins_log Kryptonite "Failed to send the message to  $chatid: $res (encryptMSG)"

		if {[errorMessage $res $chatid $error_code 1] == 0} {
			set msg ""			 			
		}
		::Kryptonite::validate
		return	
	}		


}


if {[catch { set fileID_asc [open $filename_encrypted_text] } res]} {
	plugins_log Kryptonite "Failed To open file $filename_encrypted_text: $res (encryptMSG)"
	if {[errorMessage $res $chatid $error_code 1] == 0} {
		set msg ""			 			
	}

	return
}

if {[catch { set data [read $fileID_asc] } res]} {
	plugins_log Kryptonite "Failed to read file $filename_encrypted_text: $res (encryptMSG)"
	if {[errorMessage $res $chatid $error_code 1] == 0} {
		set msg ""			 			
	}

	if { [file exists $filename_encrypted_text] } {
		file delete $filename_encrypted_text
	}
	return	
}

if {[catch { close $fileID_asc } res]} {
	plugins_log Kryptonite "Failed to close file $filename_encrypted_text: $res (encryptMSG)"
	if {[errorMessage $res $chatid $error_code 1] == 0} {
		set msg ""			 			
	}

	if { [file exists $filename_encrypted_text] } {
		file delete $filename_encrypted_text
	}
	return		
}		


set encrypted_message [split $data \r]
set encrypted_message [string trim $encrypted_message "{}"]

if { [file exists $filename_plain_text] } {
	file delete $filename_plain_text
}

if { [file exists $filename_encrypted_text] } {
	file delete $filename_encrypted_text
}


return $encrypted_message

}






#  Error messages of encryption during sessions:
# 
# 0: Error when I receive the message
# 1: Error when I send a encrypted message


proc errorMessage { text chatid status type} {

	set win_name [::ChatWindow::MakeFor $chatid] 
	delSecureChat $chatid
	sendChatStatus $chatid $status


	if { $type == 0 } {
		if { $win_name != 0 } {
			::amsn::WinWrite $chatid "\n[trans decrypt_error $chatid $text]\n" red

	}
}

if {$type == 1 } {
	if { $win_name != 0 } {
		::amsn::WinWrite $chatid "\n[trans default_error $text]\n" red
	}		
	set answer [::amsn::messageBox "[trans send_noencrypt]" yesno question "[trans encrypt_error]"]
	if { $answer == "yes"} { 
		return 1
	} else {
		return 0
	}		
}		
}




# User Levels:
#
# Level 0: The contact hasn't an initiated session.
# Level 1: The contact has sent plugin information and he has a compatible plugin
# Level 2: The contact has an initiated session, previous exchange of correct fingerprints
#
proc getUserLevel { chatid } {
	variable users

	if {[info exists users($chatid)]} {
		return [set users($chatid)]
}
return 0

}


}

