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
		
	variable selected ""
	variable tempimg

	constructor { args } {
		#frame hull is created automatically

		#apply all options
		$self configurelist $args

#		$self fillWidgetForUser $options(-user)
		bind $self <Destroy> [list $self cleanUp]
	}

	method cleanUp { } {
		if {$options(-createtempimg)} {
			#remove tempimg
			catch {image delete $tempimg}
		}
	}

	method fillWidgetForUser { email } {
		global HOME

		set selected ""
puts "filling for user $email"
		#create the scroll-frame
		ScrolledWindow $self.sw -bg $options(-bg)
		ScrollableFrame $self.sw.sf -bg $options(-bg)
		$self.sw setwidget $self.sw.sf
		pack $self.sw -expand true -fill both
		set frame [$self.sw.sf getframe]

		set dps_per_row $options(-width)

		if {$email == ""} {		
			label $frame.nodps -text "\t[trans nouserspecified]" -bg $options(-bg)
			pack $frame.nodps			
		} else {
		#if no user is specified
			if {$email == "all"} {
				set email ""
			}

			set shipped_dps [lsort -index 1 [$self getDpsList [glob -nocomplain -directory [file join skins default displaypic] *.dat] $email 1]]
			if {$email == "self"} {
				set user_dps [lsort -index 1 -decreasing [$self getDpsList [glob -nocomplain -directory [file join $HOME displaypic] *.dat] $email]]
			} else {
				set user_dps [lsort -index 1 -decreasing [$self getDpsList [glob -nocomplain -directory [file join $HOME displaypic cache] *.dat] $email]]
			}
			set dps [linsert [concat $shipped_dps $user_dps] 0 [list "" "nopic" "[trans nopic]"]]

			if { $email != "self" } {
				if { [::abook::getContactData $email customdp ""] != "" } {
					set image_name [::abook::getContactData $email customdp ""]
				} else {
					set image_name [::abook::getContactData $email displaypicfile ""]
				}
				if {$image_name != ""} {
					set pic_in_use [file join $HOME displaypic cache [filenoext $image_name].png]
				} else {
					set pic_in_use ""
				}
			} else {
				set pic_in_use [displaypicture_std_self cget -file]
			}

			set i 0
			
			foreach dp $dps {
				#exclude the image the user is currently using
				if { $options(-showcurrent) != 0 || [string first $pic_in_use [lindex $dp 0]] == -1 } {
					if {[lindex $dp 0] != ""} {
						set file [filenoext [lindex $dp 0]].png
						#if a problem loading the image arises, go to next
						if { [catch { image create photo userDP_${email}_$i -file $file -format cximage }] } { continue }
					} else {
						set file ""
						image create photo userDP_${email}_$i -file [displaypicture_std_none cget -file] -format cximage
					}
						
					::picture::ResizeWithRatio userDP_${email}_$i 96 96

					set entry $frame.${i}_tile

					if {[lindex $dp 2] == ""} {
						set label [lindex $dp 1]
					} else {
						set label [lindex $dp 2]
					}

					sexytile $entry -type filewidget -text $label\
						 -icon userDP_${email}_$i -bgcolor $options(-bg) -onpress [list $self onClick $entry $file]
						
						
					bind $entry <Destroy> "catch { image delete userDP_${email}_$i}"


					grid $entry \
						-row [expr {$i / $dps_per_row}] -column [expr {$i % $dps_per_row}] \
							-pady $options(-padding) -padx $options(-padding)
							
					incr i
				}
			}
			if {$i == 0} {
				label $frame.nodps -text "\t[trans nocacheddps]" -bg $options(-bg)
				pack $frame.nodps
			}
		}	
	
	
	
	}

	method onClick { entry filepath} {
		switch $options(-mode) {
			"selector" {
				#special actions for in selector mode
			}
			default {
				#this is for the "properties" mode
			}			
		}
		# Backups old selected (deSelect erases it)
		set oldentry [lindex $selected 0]
		$self deSelect
		if {$options(-createtempimg)} {
			#remove former tempimg
			catch {image delete $tempimg}
		}
		if {$entry != $oldentry } {
			#create tempimg if asked for
			if {$options(-createtempimg)} {
				set tempimg [image create photo [TmpImgName] -file $filepath]
				set selected [list $entry $filepath $tempimg]
			} else {
				set selected [list $entry $filepath]
			}
		}
		eval $options(-command)
	}
		
	method deSelect {} {
		if {$selected != ""} {
			[lindex $selected 0] deSelect
		}
		set selected ""
	}

	
	method getSelected {} {
		return $selected
	}

	method getDpsList { dat_list email {isShipped 0} } {
		set dps_list ""
		foreach dat $dat_list {
			if {$isShipped} {
				set file [::skin::GetSkinFile displaypic [file tail $dat]]
			} else {
				set file $dat
			}
			set fd [open $file]
			set greps [$self grep $fd $email]
			close $fd
			if {[lindex $greps 0]} {
				set date [lindex $greps 1]
				set readable_date ""
				status_log "$date"
				catch {set readable_date [clock format $date -format %x]} error_var
				status_log "$error_var"
				lappend dps_list [list $file $date $readable_date]
			}
		}
		return $dps_list
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
#		global selected_image
		
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

	
	method deleteentry {filename widget} {
#		global selected
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
