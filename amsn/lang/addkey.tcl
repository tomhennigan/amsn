#!/usr/bin/env tclsh
# Written by:   Alexandre Hamelin (ahamelin users sourceforge net)
# Date:         Sept 2, 2003
# Usage:        ./addkey.tcl
#
# Small utility to add a new message key to a language file. When the key is
# added, the language file is sorted before it is written back to the disk.
# If the key already exists in the target language file, the associated message
# will be replaced. In the latter case, the old message will be printed on
# screen first.

proc prompt {msg} {
    puts -nonewline "$msg"
    flush stdout
    return [gets stdin]
}

proc die {msg} {
    puts "error: $msg"
    exit 1
}

set key  [prompt "Specify a key (^C to abort): "]
set lang [prompt "Language for this key (en, fr_ca, etc.): "]

if {[catch {open lang$lang "r"} fd]} {
    puts "TIP: This utility should be run from within the lang directory."
    die $fd
}

# Read the content of the language file.
set lines [list]
gets $fd version
while { [gets $fd line] >= 0 } {
    lappend lines $line
}
close $fd

# See whether the key exists or not.
set k [lsearch $lines "$key *"]
if {$k > -1} {
    # Print the old message if the key existed.
    set keytext [lindex $lines $k]
    puts "-- Old message: [string repeat "-" 54]"
    puts [string range $keytext [expr [string first " " $keytext]+1] end]
    puts [string repeat "-" 70]
}

set msg [prompt "Enter the text for this key (<Enter> to end):\n"]

if {$k > -1} {
    # Replace the text of an existing key.
    lset lines $k "$key $msg"
} else {
    # Add a new key.
    lappend lines "$key $msg"
}

# Sort the content.
set lines [lsort $lines]

#puts stderr "WARNING: Original language file (lang$lang) will be truncated."
#puts stderr "         Please press enter to continue."
#gets stdin

# Write the new language file.
if {[catch {open lang$lang "w"} fd]} {
    die "$fd"
}
puts $fd $version
puts $fd [join $lines "\n"]
close $fd
