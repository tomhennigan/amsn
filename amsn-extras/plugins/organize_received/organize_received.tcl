# Organize Received Files
# Plugin for AMSN
#
# Author: Nilton Volpato <first-name dot last-name @ gmail.com>
# Time-stamp: <2006-01-23 11:03:05 nilton>
#
# Thanks to KaKaRoTo for help and support.
#
# Changelog:
# 2006-01-04: v0.4 There is no ::files_dir in amsn > v0.95, fixed to work in
#                  both versions
# 2006-01-04: v0.3 Fixed DeInit function parameters, more efficient methods
#                  for discovering the sender.
# 2006-01-01: v0.2 Fixed some problems, added configuration interface and 
#                  better description.
# 2005-12-31: v0.1 Initial version

namespace eval ::organize_received {
    variable plugin_name "Organize Received Files"

    variable loaded 0

    variable TheRealAcceptFT ::amsn::TheRealAcceptFT

    proc Init { dir } {
	variable plugin_name
	variable loaded
	variable TheRealAcceptFT

	if { $loaded == 1 } { return 0 }

	::plugins::RegisterPlugin $plugin_name

	# we wrap ::amsn::AcceptFT
	if { [info proc "::amsn::AcceptFT"] == "::amsn::AcceptFT" } {
	    rename ::amsn::AcceptFT $TheRealAcceptFT
	    proc ::amsn::AcceptFT { chatid cookie {varlist ""} } {
		# remove a or b from version to make it a number
		set ver [string map {"a" "" "b" ""} $::version]
		if { $ver > 0.95 } {
		    set old_filesdir [::config::getKey receiveddir]
		} else {
		    set old_filesdir $::files_dir
		}

		if { [lindex $varlist 0] != "" } {
		    # MSN6 protocol. We can get the sender from varlist
		    set email [lindex $varlist 0]
		} else {
		    # Old protocol. We use ::MSN::usersInChat
		    set email [::MSN::usersInChat $chatid]
		}

		set date [clock format [clock seconds] -format "%Y-%m-%d"]
		set subdir [::organize_received::parseDirFormat \
			    $::organize_received::config(subdir_fmt) $email $date]
		if { $ver > 0.95 } {
		    ::config::setKey receiveddir [file join [::config::getKey receiveddir] "$subdir"]
		    ::create_dir [::config::getKey receiveddir]
		} else {
		    set ::files_dir [file join "$::files_dir" "$subdir"]
		    ::create_dir "$::files_dir"
		}
		set retVal [uplevel 1 $::organize_received::TheRealAcceptFT $chatid $cookie [list $varlist]]
		if { $ver > 0.95 } {
		    ::config::setKey receiveddir $old_filesdir
		} else {
		    set ::files_dir $old_filesdir
		}
		return retVal
	    }
	}

	array set ::organize_received::config {
	    subdir_fmt "\$email/\$date"
	}

	set ::organize_received::configlist \
	    [list \
		 [list label "Format for subdirs:"] \
		 [list label "Parameters: \$email, \$date" lbl1] \
		 [list str "Subdir:" subdir_fmt] \
		]

	set loaded 1
	plugins_log $plugin_name "Plugin loaded"
	return 1
    }

    proc DeInit {} {
	variable plugin_name
	variable loaded
	variable TheRealAcceptFT

	if { $loaded == 0 } { return 0 }

	if { [info proc "$TheRealAcceptFT"] == "$TheRealAcceptFT" } {
	    rename ::amsn::AcceptFT ""
	    rename $TheRealAcceptFT ::amsn::AcceptFT
	}

	set loaded 0
	plugins_log $plugin_name "Plugin unloaded"
    }

    proc parseDirFormat { fmt email date } {
	# quote some chars
	set r [string map {"\\" "\\\\" "\$" "\\\$" "\(" "\\\("} $fmt]
	# unquote the needed variables
	set r [string map {"\\\$email" "\${email}" "\\\$date" "\${date}"} $r]
	# split into a list of subdirs
	set r [split [subst -nocommands $r] "/\\"]
	# apply file join so the correct dir separator is used
	return [eval [linsert $r 0 file join]]
    }

}
