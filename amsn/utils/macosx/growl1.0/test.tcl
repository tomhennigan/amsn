
lappend auto_path [pwd]

package require growl

set notifications [list "Test With Spaces" "NoSpace"]

growl register "Tcl Test App" ${notifications} ""

foreach notification ${notifications} {
	growl post ${notification} "Test Notification" "Testing notification \"${notification}\"..."
}

#puts "This notification shouldn't show..."
#growl post "__Unknown Notification__" "Title" "Message"
