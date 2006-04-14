package require snit
package provide dpbrowser 0.2

snit::widgetadaptor dpbrowser {

	option -user -default "" -configuremethod SetConfig
	option -width -default 5
#	option -height -default 500
	option -bg -default white -configuremethod SetConfig

#	option -addinuse -default 0 -configuremethod SetConfig


	constructor { args } {
		set color $options(-bg)
		#create the base frame
		installhull using frame -bg $color -bd 0 -relief flat
		$self configurelist $args
		
status_log "creating dpbrowser widget $self with arguments $args at $hull"


#ScrollableFrame $nbIdent.otherpics.sf
#		set mainFrame [$nbIdent.otherpics.sf getframe]
		ScrolledWindow $self.sw -bg $color
		ScrollableFrame $self.sw.sf -bg $color
		$self.sw setwidget $self.sw.sf
		pack $self.sw -expand true -fill both
		
		set frame [$self.sw.sf getframe]

		$self configurelist $args


		global HOME
		set email $options(-user)
		set cachefiles [glob -nocomplain -directory [file join $HOME displaypic cache] *.dat]
		
#TODO: set in order of time
#	use: [file atime $file]	(the last acces time in seconds from a fixed point > not available on FAT)	

		set gridxpad 5
		

		set i 0
		
		set dps_per_row $options(-width)
		#if we don't add the in_use pic, save its name so we can exclude it
#		if {!$options(-addinuse)} { 
			set pic_in_use [::abook::getContactData $email displaypicfile ""]
#		}


		if {$email != ""} {

			if {$email == "all"} {
				set email ""
			}
		
			foreach file $cachefiles {
				#exclude the image the user is currently using
				if { [string first $pic_in_use $file] == -1 } {
				set fd [open $file]



				set greps [$self grep $fd $email]
				#if the image belongs to this user, add it
				if { [lindex $greps 0] } {

					#if a problem loading the image arises, go to next
					if { [catch { image create photo userDP_${email}_$i -file [filenoext $file].png -format cximage }] } { continue }
					::picture::ResizeWithRatio userDP_${email}_$i 96 96
					set entry $frame.${i}_shell
					frame $entry -bg $color -bd 0 -relief flat

					label $entry.img -image userDP_${email}_$i -bg $color
					bind $entry <Destroy> "catch { image delete userDP_${email}_$i}"
					bind $entry.img <ButtonPress-3> \
						[list $self dp_popup_menu %X %Y [filenoext $file].png $entry.img]

	#TODO: a tooltip with the full size image
					bind $entry.img <Enter> ""
					bind $entry.img <Leave> ""

					label $entry.text -text [lindex $greps 1] -bg $color

					pack $entry.img $entry.text -side top				
					grid $entry \
						-row [expr {$i / $dps_per_row}] -column [expr {$i % $dps_per_row}] \
						-pady $gridxpad -padx $gridxpad
					incr i
					
				}
				close $fd
				}

			}
			if {$i == 0} {
				label $frame.nodps -text "\t[trans nocacheddps]" -bg $color
				pack $frame.nodps
			 }
		} else {
			label $frame.nodps -text "\t[trans nouserspecified]" -bg $color
			pack $frame.nodps		
		}
	



#		Configure all options off the widget
#		$self configurelist $args

	}


	method SetConfig {option value} {
		set options($option) $value

		#actions after change of options
		#the space was added so the option isn't passed to the switch command
#		switch " $option" {
#			" -blah" {
#				$self UpdateBlah
#			}			
#		}
			
	}
	
	method grep { chan id } {
		#skip the first line as the email is on the second
		set date [gets $chan]
		#check the second for $id
		if {[regexp $id [gets $chan]]} {
			return [list 1 $date]
		} else {
			return 0
		}
	}
	
	method showtooltip {X Y imgfile} {
	
	
	}

	method dp_popup_menu { X Y filename widget } {
		# Create pop-up menu if it doesn't yet exists
		set the_menu .userDPs_menu
		catch {destroy $the_menu}
		menu $the_menu -tearoff 0 -type normal
		$the_menu add command \
			-label "[trans copytoclipboard [string tolower [trans filename]]]" \
			-command "clipboard clear ; clipboard append $filename"
		$the_menu add command -label "[trans delete]" \
			-command "pictureDeleteFile $filename $widget"
#		$the_menu add command -label "Set as custom display picture for this user" \
			-command [list ::amsn::messageBox "Sorry, not yet implemented" ok error [trans failed]]
		$the_menu add command -label "Set as my display picture" \
			-command [list set_displaypic $filename]
		tk_popup $the_menu $X $Y
	}



}
