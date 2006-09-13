namespace eval ::chameleon::entry {

   proc entry_customParseConfArgs {w parsed_options args } {
     	array set options $args
	array set ttk_options $parsed_options

       if { [info exists options(-width)] } {
	   if {$options(-width) == 0} {
	       set ttk_options(-width) [list]
	   } else {
	       set ttk_options(-width) $options(-width)
	   }
       }

	return [array get ttk_options]
    }

    proc init_entryCustomOptions { } {
 	variable entry_widgetOptions
 	variable entry_widgetCommands 

 	array set entry_widgetOptions {
		-background -styleOption
		-bd -styleOption
		-bg -styleOption
		-borderwidth -styleOption
		-cursor -cursor
		-disabledbackground -ignore
		-disabledforeground -ignore
		-exportselection -exportselection
		-fg -styleOption
		-font -styleOption
		-foreground -styleOption
		-highlightbackground -ignore
		-highlightcolor -ignore
		-highlightthickness -ignore
		-insertbackground -ignore
		-insertborderwidth -ignore
		-insertofftime -ignore
		-insertontime -ignore
		-insertwidth -ignore
		-invalidcommand -invalidcommand
		-invcmd -invalidcommand
		-justify -justify
		-readonlybackground -ignore
		-relief -styleOption
		-selectbackground -ignore
		-selectborderwidth -ignore
		-selectforeground -ignore
		-show -show
		-state -state
		-takefocus -takefocus
		-text -textvariable
		-textvariable -textvariable
		-validate -validate
		-validatecommand -validatecommand
		-vcmd -validatecommand
		-width -width
		-xscrollcommand -xscrollcommand 
	}

	
 	array set entry_widgetCommands {
		bbox {1 {$w bbox}} 
		delete {1 {$w delete}}
		get {1 {$w get}}
		icursor {2 {$w icursor}}
		index {3 {$w index}}
		insert {3 {$w insert}}
		scan {2 {entry_scan $w}}
		selection {2 {entry_selection $w}}
		validate {1 {$w validate}}
		xview {1 {$w xview}}
	}
	    
    }

   proc entry_scan { w args } {
	   #TODO implement scan
	   #TODO implement the 'anchor' index somehow...
	   
   }
   proc entry_selection { w option args } {
	   if { $option == "clear" || $option == "present" || $option == "range"} {
	       return [eval [list $w] selection $option $args]
	   }
   }

}
