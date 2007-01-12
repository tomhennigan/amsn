package require snit
package require sexytile
package provide dpbrowser 0.4


	

snit::widget dpbrowser {


	option -user -default "self" -configuremethod setConfig
	option -width -default 5 -readonly 1
		
	option -bg -default white -readonly 1
	option -bg_hl -default DarkBlue -readonly 1
	option -mode -default "properties" -readonly 1
	#modes "properties" where you right-click with actions and mode "selector" where left click sets as your image preview for new pic browser"

	# When using select mode, it's important to pass the name of a procedure through this option.
	# Otherwise, the parent window will not react to the change of selection.
	option -command
	option -showcurrent -default 1
	option -padding -default 5 -readonly 1
	option -createtempimg -default 0
		

	constructor { args } {
		#frame hull is created automatically

		#apply all options
		$self configurelist $args

#		$self fillWidgetForUser $options(-user)
		bind $self <Destroy> [list $self cleanUp]

	}

	method cleanUp { } {
		global tempimg

		if {$options(-createtempimg)} {
			#remove tempimg
			catch {image delete $tempimg}
		}
	}

	method fillWidgetForUser { email } {
		global HOME
		global selected

		set selected ""
puts "filling for user $email"
		#create the scroll-frame
		ScrolledWindow $self.sw -bg $options(-bg)
		ScrollableFrame $self.sw.sf -bg $options(-bg)
		$self.sw setwidget $self.sw.sf
		pack $self.sw -expand true -fill both
		set frame [$self.sw.sf getframe]

		set dps_per_row $options(-width)

		if {$email == "self"} {
			set shipped_dps [glob -nocomplain -directory [file join skins default displaypic] *.dat]
			set user_dps [glob -nocomplain -directory [file join $HOME displaypic] *.dat]
			set files [concat $shipped_dps $user_dps]
			set pic_in_use ""
		} else {
			set files [glob -nocomplain -directory [file join $HOME displaypic cache] *.dat]	
			set pic_in_use [::abook::getContactData $email displaypicfile ""]
		}



		#if no user is specified
		if {$email == ""} {		
			label $frame.nodps -text "\t[trans nouserspecified]" -bg $options(-bg)
			pack $frame.nodps			
		} else {
			if {$email == "all"} {
				set email ""
			}
		
			set i 0			
			foreach file $files {
				#exclude the image the user is currently using
				if { $options(-showcurrent) != 0 || [string first $pic_in_use $file] == -1 } {

				set fd [open $file]

				set greps [$self grep $fd $email]
				close $fd
				
				#if the image belongs to this user, add it
				if { [lindex $greps 0] } {

					#if a problem loading the image arises, go to next
					if { [catch { image create photo userDP_${email}_$i -file [filenoext $file].png -format cximage }] } { continue }
						
					::picture::ResizeWithRatio userDP_${email}_$i 96 96

						set entry $frame.${i}_tile

						sexytile $entry -type filewidget -text [lindex $greps 1]\
						 -icon userDP_${email}_$i -bgcolor $options(-bg) -onpress [list $self onClick $entry [filenoext $file].png]

						bind $entry <Destroy> "catch { image delete userDP_${email}_$i}"


					grid $entry \
						-row [expr {$i / $dps_per_row}] -column [expr {$i % $dps_per_row}] \
							-pady $options(-padding) -padx $options(-padding)
					incr i
					
				}
				}
			}
			if {$i == 0} {
				label $frame.nodps -text "\t[trans nocacheddps]" -bg $options(-bg)
				pack $frame.nodps
			 }
		}	
	
	
	
	}

	method onClick { entry filepath} {
		global selected
		global tempimg

		set oldwidget [lindex $selected 0]
		switch $options(-mode) {
			"selector" {
				#special actions for in selector mode

			}
			default {
				#this is for the "properties" mode

			}			
		}
			
		#deselect other dps in widget
		if {$selected != ""} { $oldwidget deSelect }


		#create tempimg if asked for
		if {$options(-createtempimg)} {
			#remove former tempimg
			catch {image delete $tempimg}
			set tempimg [image create photo [TmpImgName] -file $filepath]
			set selected [list $entry $filepath $tempimg]
		} else {
			set selected [list $entry $filepath]
	}
	

		eval $options(-command)
	
	}
		
	
	method getSelected {} {
		global selected

		return $selected	
	}



#FIXME: there seems to be an encoding issue with the shipped dps	
	method grep { chan id } {
		#first line is date or name (for shipped dps)
		#second line is id of the user or filename for shipped dps
		set dateorname [gets $chan]

		#if it's the user his dp's we want to show
		if { $id == "self"} {
				return [list 1 $dateorname]

		#otherwise, check if it's the right user
		} else {
			if {[regexp $id [gets $chan]]} {
				#ifso, return the date
				return [list 1 $dateorname]
			} else {
				#else, return 0
			return 0
		}
	}
	}
	
	method showtooltip {X Y imgfile} {
#to show the full size image	
	
	}

	method dp_popup_menu { X Y filename widget user} {
		global selected_image
		
#if user is self have another menu ?		
		
		# Create pop-up menu if it doesn't yet exists
		set the_menu .userDPs_menu
		catch {destroy $the_menu}
		menu $the_menu -tearoff 0 -type normal
		$the_menu add command \
			-label "[trans copytoclipboard [string tolower [trans filename]]]" \
			-command [list clipboard clear ; clipboard append $filename]
		$the_menu add command -label "[trans delete]" \
			-command [list $self deleteentry $filename $widget]
#		$the_menu add command -label "Set as custom display picture for this user" \
			-command [list ::amsn::messageBox "Sorry, not yet implemented" ok error [trans failed]]
		$the_menu add command -label "[trans setasmydp]" \
			-command [list set_displaypic $filename]
		tk_popup $the_menu $X $Y
	}

	
	

	method selectdp { file imgwidget } {
		if {$options(-disableselect) == "no" } {
			global selected_path
			if { [catch { image create photo my_pic -file $file -format cximage }] } { return }
			set selected_path $file
			# Highlight only the selected image
			for {set i 0} {[winfo exists [$self.sw.sf getframe].${i}_shell]} {incr i} {
				set entry [$self.sw.sf getframe].${i}_shell
				set entry_img $entry.img
				if { $entry_img != $imgwidget } {				
					$entry configure -background $options(-bg)
				} else {
					$entry configure -background $options(-bg_hl)
				}
			}
			# Execute the post-select procedure, sending the browser window as parameter
			if { $options(-post_select) != "" } {
				eval $options(-post_select) $self
			}
		}
	}

	method unselect_all { } {
		for {set i 0} {[winfo exists [$self.sw.sf getframe].${i}_shell]} {incr i} {
			set entry [$self.sw.sf getframe].${i}_shell
			$entry configure -background $options(-bg)
		}

	}
	
	method getselection {} {
		global selected_path
		return $selected_path
	}

	method deleteentry {filename widget} {
		global selected
#TODO:
puts "Deleting dps isn't implemented yet"
#		if {$selected_path == $filename} {
#			set selected_path ""
#		}
#		pictureDeleteFile $filename $widget
#		$self fill
		}
	
	method setConfig {option value} {
		set options($option) $value
		puts "Altering $option to $value"

		#actions after change or initial setting of options
		#the space was added so the option isn't passed to the switch command
		switch " $option" {
			" -bgcolor" {
				$hull configure -bg $value
	}
			" -width" {
				$hull configure -width $value
}
			" -height" {
				$hull configure -height $value
			}

			" -user" {
				#empty the widget and refill it for other user
				destroy $self.sw
				$self fillWidgetForUser $value
				puts "changed to user $value"
			}
		}
			
	}
	
	
}
