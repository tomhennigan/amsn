namespace eval ::debug {


	proc help {} {
		foreach proc [info commands ::debug::*] {
			puts $proc
		}
	}

	proc printenvs {} {
		global env
		foreach env_var [array names env] { puts "$env_var  =  $env($env_var)"}

	}

	proc imgnrs {} {
		puts "loaded pixmaps: [llength [array names ::skin::loaded_pixmaps]]"
		puts "pixmap names:   [llength [array names ::skin::pixmaps_names]]"
		puts "image names:   [llength [image names]]"
	}


	proc sysinfo {} {
		global HOME2 tcl_platform tk_patchLevel tcl_patchLevel
		puts "aMSN version: $::version from $::date"
		puts "TCL  TK version: $tcl_patchLevel $tk_patchLevel"
		puts "Tcl platform: [array get tcl_platform]"		
	}	

	proc memuse { {about ""} } {
		if {$about == ""} {
			puts "Nr of TCL commands: [llength [info commands]]"
			puts "  ->  nr invoked  : [llength [info cmdcount]]"
#			puts "Nr of variables   : [llength [info vars]]"
			puts "Nr of global vars : [llength [info globals]]"
			puts "Packages loaded with"
			puts " 'load'           : [llength [info loaded]]"
			puts " 'package require': [llength [package names]]"
			puts "Nr of images      : [llength [image names]]"
		}
		#here we could have stats about 1 namespace for example
		
	}
	
	
}
