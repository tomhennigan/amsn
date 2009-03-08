
::Version::setSubversionId {$Id$}
	
global wchannel
if {![info exists wchannel]} {
	set wchannel stdout
}


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
		global tcl_platform tk_patchLevel tcl_patchLevel
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
		global wchannel

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

	proc printStackTrace2 { } {
		for { set i [info level] } { $i > 0 } { incr i -1} { 
			puts "Level $i : [info level $i]"
			puts "Called from within : "
		}
		puts ""
	}


	proc findSockets { {namespace "::" } } {
		set result [list]
		foreach v [info vars "${namespace}::*"] {
			set content ""
			if { [catch {set content [set $v]}] } {
				foreach {key val} [array get $v] {
					set content $val
					if {[string first "sock" $content] == 0 &&
					    ![catch {eof $content}]} {
						lappend result $content
						puts "Found socket $content in variable ${v} ($key)"
					}
					
				}
			} else {
				if {[string first "sock" $content] == 0  &&
				    ![catch {eof $content}] } {
					lappend result $content
					puts "Found socket $content in variable ${v}"
				}
			}
		}
		foreach n [namespace children $namespace] {
			set res [findSockets $n]
			set result [concat $result $res]
		}

		return $result
	}


#Aid procs	
	proc output {data} {
		global wchannel
		variable force
		set force 1

		#if we're writing to the file, also write to stdout
		#.. better not :D
		#if {$wchannel != "stdout"} {
		#	puts $data
		#}
		puts $wchannel $data
		
		catch {if {$force == 1} {
			catch {flush $wchannel}
		} }
	}

	# adapted from: http://wiki.tcl.tk/15193
	proc get_proc_full { name {level 2} } {
		if {![string match ::* $name]} {
			set ns [uplevel $level namespace current]
			if { $ns != "::" } {
				set name "${ns}::${name}"
			}
		}
		return $name
	}

	proc stack_procs_enter { args } {
		puts "Enter: [lindex $args 0]"
	}
	
	proc stack_procs_leave { args } {
		set ret [lindex $args 2]
		if { $ret ==  {} } {
			set ret "{}"
		}
		puts "Leave: $ret <- [lindex $args 0]"
	}

	proc enable_hook {} {
		rename proc ::tk::proc
		uplevel #0 {
			::tk::proc proc { name args body } {
				set name [::debug::get_proc_full $name]
				
				::tk::proc $name $args $body 
				
				trace add execution $name enter ::debug::stack_procs_enter
				trace add execution $name leave ::debug::stack_procs_leave
			}
		}
	}

	proc disable_hook {} {
		uplevel #0 {
			catch {
				rename proc {}
				rename ::tk::proc proc
			}
		}
	}

	# This will not work with upvar or uplevel!
	# We must hook them to and increment the level!
	proc stack_procs { {filename {}} } {
		::debug::enable_hook
		if { [catch {
			if { $filename == {} } {
				reload_files
			} else {
				source $filename
			}
		} res ] } {
			puts "Error when loading files: $res"
		}
		::debug::disable_hook
	}

}



