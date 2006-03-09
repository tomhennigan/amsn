namespace eval ::debug {


	proc help {} {
		foreach proc [info commands ::debug::*] {
			::debug::output $proc
		}
	}

	proc printenvs {} {
		global env
		foreach env_var [array names env] { ::debug::output "$env_var  =  $env($env_var)"}

	}

	proc imgstats {} {
		::debug::output "loaded pixmaps: [llength [array names ::skin::loaded_pixmaps]]"
		::debug::output "pixmap names:   [llength [array names ::skin::pixmaps_names]]"
		::debug::output "image names:   [llength [image names]]"
	}


	proc sysinfo {} {
		global HOME2 tcl_platform tk_patchLevel tcl_patchLevel
		::debug::output "aMSN version: $::version from $::date"
		::debug::output "TCL  TK version: $tcl_patchLevel $tk_patchLevel"
		::debug::output "Tcl platform: [array get tcl_platform]"		
	}	

	proc memuse { {about ""} } {
		if {$about == ""} {
			::debug::output "Nr of TCL commands: [llength [info commands]]"
			::debug::output "  ->  nr invoked  : [llength [info cmdcount]]"
#			::debug::output "Nr of variables   : [llength [info vars]]"
			::debug::output "Nr of global vars : [llength [info globals]]"
			::debug::output "Packages loaded with"
			::debug::output " 'load'           : [llength [info loaded]]"
			::debug::output " 'package require': [llength [package names]]"
			::debug::output "Nr of images      : [llength [image names]]"
		}
		#here we could have stats about 1 namespace for example
		
	}
	
	
	proc varsize { {namespace ""}} {
		if {$namespace != ""} {
			set namespaces [list $namespace]
		} else {
			set namespaces [namespace children ::]
		}

		foreach namespace $namespaces {
			::debug::output "Namespace $namespace\n----------"
			foreach var [info vars  "${namespace}::*"] {
				::debug::output "$var : "
				catch { ::debug::output "\t[string length [set $var]]\n"}
				catch { ::debug::output "\t[string length [array get $var]]"} 
			}
		}
	}

	proc writeOn {} {
		global HOME2
		variable debugfile
		variable wchannel

		set debugfile [file join $HOME2 debug.log]
		#open the file for writing at the end of it
		set wchannel [open $debugfile a+]

	}
	
	proc writeOff {} {
		global wchannel
		flush $wchannel
		close $wchannel
		set wchannel stdout
	}
		



	proc printStackTrace { } {
		::debug::output "Stacktrace:"
		for { set i [info level] } { $i > 0 } { incr i -1} {
			::debug::output "Level $i : [info level $i]"
			::debug::output "Called from within : "
		}
		::debug::output ""
	}






#Aid procs	
	proc output {data} {
		global wchannel
		variable force
		set force 1

		#if we're writing to the file, also write to stdout
		if {$wchannel != "stdout"} {
			puts $data
		}
		puts $wchannel $data
		
		catch {if {$force == 1} {
			catch {flush $wchannel}
		} }
	}





}



