########################################################################
# SendRecents plugin for aMSN
#  Version: 1.1a (9-October-2008)
#  Author: MurDoK <murdok.lnx at gmail>
# Send your feedback, bugs or wishes!
#
########################################################################
# CHANGELOG:
#   - Version: 1.1a (9-October-2008) - Added lithuanian translation (thanks to Tadas Masiulionis)
#   - Version: 1.1 (23-January-2008) - Added italian translation (thanks to GREGORIO)
#   - Version: 1.0 (01-June-2007) - First release
#
########################################################################
# KNOWN BUGS:
#   - When you send a file, menus are not updated until you close and reopen the window
#


namespace eval ::sendrecents {

	proc init { dir } {
		set langdir [file join $dir "lang"]
		load_lang en $langdir
		load_lang [::config::getGlobalKey language] $langdir

		::plugins::RegisterPlugin "SendRecents"
		::plugins::RegisterEvent "SendRecents" chatmenu addmenus
                ::plugins::RegisterEvent "SendRecents" sent_ft_invite filesend

                ::sendrecents::conf

	}

#################
        proc conf { } {
		array set ::sendrecents::config {
			ns {10}
		}

                set ::sendrecents::configlist [list \
                        [list str "[trans filesshowed]:" ns] \
                        [list ext "[trans emptyrecents]" flushlist] \
                ]

        }

#################
        proc flushlist { } {
                ::config::setKey recentfiles ""
        }

#################
        proc addmenus { event evpar } {
		upvar 2 $evpar newvar

                set recentsmenu $newvar(menu_name).actions.recents
                menu $recentsmenu -tearoff 0 -type normal

                while { [llength [::config::getKey recentfiles]] > $::sendrecents::config(ns) } {
                        set nu [expr $::sendrecents::config(ns) - 1]
                        ::config::setKey recentfiles [lreplace [::config::getKey recentfiles] $nu $nu]
                }

                if { [llength [::config::getKey recentfiles]] == 0 } {
                        $recentsmenu add command -label "([trans empty])"
                } else {
                        for {set i 0} {$i < [llength [::config::getKey recentfiles]]} {incr i} {
                                $recentsmenu add command -label "[file tail [lindex [::config::getKey recentfiles] $i]]" \
                                -command "::amsn::FileTransferSend \[::ChatWindow::getCurrentTab $newvar(window_name)\] \"[lindex [::config::getKey recentfiles] $i]\""
                        }
                }

		$newvar(menu_name).actions add separator
                $newvar(menu_name).actions add cascade -label "[trans sendrecent]" -menu $recentsmenu

        }

################

        proc filesend { event evpar } {
                upvar 2 $evpar newvar
                set filename $newvar(filename)
                set n [lsearch [::config::getKey recentfiles] $filename]

                #already exists
                if { n != -1 } {
                        ::config::setKey recentfiles [lreplace [::config::getKey recentfiles] $n $n]
                }

                if { [llength [::config::getKey recentfiles]] == $::sendrecents::config(ns) } {
                        set nu [expr $::sendrecents::config(ns) - 1]
                        ::config::setKey recentfiles [lreplace [::config::getKey recentfiles] $nu $nu]
                }

                ::config::setKey recentfiles [linsert [::config::getKey recentfiles] 0 $filename]
        }
}


################################################################################################	





