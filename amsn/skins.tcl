#!/usr/bin/wish
#########################################################
# skins.tcl v 1.0	2003/07/01   KaKaRoTo
#########################################################


proc GetSkinFile { type filename } {
    global program_dir env HOME

    set pwd ""
    if { [catch { set skin "[::config::get skin]" } ] != 0 } {
	set skin "default"
    }
    set defaultskin "default"

    if { [file readable  $filename] } {
	return "$filename"
    } elseif { [file readable [file join $pwd $program_dir skins $skin $type $filename]] } {
	return "[file join $pwd $program_dir skins $skin $type $filename]"
    } elseif { [file readable [file join $HOME $type $filename]] } {
	return "[file join $pwd $HOME $type $filename]"
    } elseif { [file readable [file join $pwd $program_dir skins $defaultskin $type $filename]] } {
	return "[file join $pwd $program_dir skins $defaultskin $type $filename]"
    } else {
	puts "File [file join $pwd $program_dir skins $skin $type $filename] not found!!!" 
	return "[file join $pwd $program_dir skins $defaultskin $type null]"
    }
	

}


proc skin_description {cstack cdata saved_data cattr saved_attr args} {
    global skin

    set skin(description) [string trim "$cdata"]
    return 0
}