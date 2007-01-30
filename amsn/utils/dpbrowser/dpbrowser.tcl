package require snit
package require sexytile
package provide dpbrowser 0.4


snit::widget dpbrowser {

	option -user -default "self" -configuremethod setConfig
	option -width -default 5

	option -bg -default white -readonly 1
	option -bg_hl -default DarkBlue -readonly 1
	option -mode -default "viewonly" -readonly 1
	# Available modes:
	# "viewonly" - no interaction with images
	# "properties" - popup menu on right click
	# "selector" - select the image to update an eventual preview
	# "both" - both behaviors
	# Any other mode will behave as "viewonly".

	# When using selector mode, it's important to pass the name of a procedure through this option.
	# Otherwise, the parent window will not react to the change of selection.
	option -command

	option -showcurrent -default 1
	option -padding -default 5 -readonly 1
	option -createtempimg -default 0
	option -autoresize -default 1 -configuremethod setConfig

	variable selected ""
	variable tempimg ""
	variable pic_in_use ""
	variable dps ""
	variable enable_draw 0

	constructor { args } {
		#frame hull is created automatically

		#apply all options
		set enable_draw 0
		$self configurelist $args
		# We are delaying drawing the content to make sure that
		# all options have been correctly stored
		set enable_draw 1
		$self drawPics

#		$self fillWidgetForUser $options(-user)
		bind $self <Destroy> [list $self cleanUp]
	}

	method cleanUp { } {
		if {$options(-createtempimg)} {
			#remove tempimg
			catch {image delete $tempimg}
		}
	}

	method fillWidget { email } {
		global HOME

		set selected ""
#puts "filling for user $email"

		if {$email != ""} {
		#if no user is specified
			if {$email == "all"} {
				set email ""
			}

			set shipped_dps [lsort -index 1 [$self getDpsList [glob -nocomplain -directory [file join skins default displaypic] *.dat] $email 1]]
			if {$email == "self"} {
				# Delete dat files for non-existing png files
				set dat_files [glob -nocomplain -directory [file join $HOME displaypic] *.dat]
				set png_files [glob -nocomplain -directory [file join $HOME displaypic] *.png]
				foreach file $dat_files {
					if {[lsearch $png_files "[filenoext $file].png"] == -1} {
						file delete $file
					}
				}
				# Create dat files for new png files
				foreach file $png_files {
					if {[lsearch $dat_files "[filenoext $file].dat"] == -1} {
						set desc_file "[filenoext $file].dat"
						set fd [open $desc_file w]
						status_log "Writing description to $desc_file\n"
						if {[catch {set mtime [file mtime $file]}]} {
							set mtime [clock seconds]
						}
						puts $fd "$mtime\n[file tail $file]"
						close $fd
					}
				}
				set user_dps [lsort -index 1 -decreasing [$self getDpsList [glob -nocomplain -directory [file join $HOME displaypic] *.dat] $email]]
			} else {
				set user_dps [lsort -index 1 -decreasing [$self getDpsList [glob -nocomplain -directory [file join $HOME displaypic cache] *.dat] $email]]
			}
			set dps [concat $shipped_dps $user_dps]

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
				set dps [linsert $dps 0 [list "" "nopic" "[trans nopic]"]]
			}
		}
		if {$enable_draw} {
			$self drawPics
		}
	}

	method drawPics { } {
		global HOME

		#create the scroll-frame
		catch { destroy $self.sw }
		ScrolledWindow $self.sw -bg $options(-bg)
		ScrollableFrame $self.sw.sf -bg $options(-bg)
		$self.sw setwidget $self.sw.sf
		pack $self.sw -expand true -fill both
		set frame [$self.sw.sf getframe]

		if {$options(-autoresize)} {
			$self autoWidth
			bind $self <Configure> [list $self handleResize]
		}

		set email $options(-user)
		set dps_per_row $options(-width)
		
		if { $dps_per_row < 1} {
			return
		}
		
		set i 0

		if { $options(-mode) != "both" && $options(-mode) != "selector" } {
			set isSelectDisabled 1
		} else {
			set isSelectDisabled 0
		}

		if {$email == ""} {
			label $frame.nodps -text "\t[trans nouserspecified]" -bg $options(-bg)
			pack $frame.nodps
		} else {
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

					sexytile $entry -type filewidget -text $label -icon userDP_${email}_$i\
						-bgcolor $options(-bg) -onpress [list $self onClick $entry $file]\
						-disableselect $isSelectDisabled -padding 4

					if {[regexp ^$HOME $file]} {
						bind $entry <ButtonRelease-3> \
							[list $self popupMenu %X %Y $file $entry 1]
					} else {
						bind $entry <ButtonRelease-3> \
							[list $self popupMenu %X %Y $file $entry 0]
					}

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

	method autoWidth { } {
		if {$options(-autoresize)} {
			set pixelwidth [winfo width $self.sw.sf]
			set padding $options(-padding)
			set new_width [ expr { int(floor($pixelwidth/(100+2*$padding))) } ]
			if { $new_width != $options(-width)} {
				if {$new_width > 0} {
					set options(-width) $new_width
				}
			}
		}
	}

	method handleResize { } {
		set old_width $options(-width)
		$self autoWidth
		if {$old_width != $options(-width)} {
			$self drawPics
		}
	}

	method onClick { entry filepath} {
		if { $options(-mode) != "both" && $options(-mode) != "selector" } {
			return
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
				catch {set readable_date [clock format $date -format %x]}
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

	method popupMenu { X Y filename widget enable_delete} {
		if { $options(-mode) != "both" && $options(-mode) != "properties" } {
			return
		}
		# Create pop-up menu if it doesn't yet exists
		set the_menu .userDPs_menu
		catch {destroy $the_menu}
		menu $the_menu -tearoff 0 -type normal
		$the_menu add command \
			-label "[trans copytoclipboard [string tolower [trans filename]]]" \
			-command [list clipboard clear ; clipboard append $filename]
		if { $enable_delete } {
			$the_menu add command -label "[trans delete]" \
				-command [list $self deleteEntry $filename $widget]
		}
		$the_menu add command -label "[trans setasmydp]" \
			-command [list set_displaypic $filename]
		tk_popup $the_menu $X $Y
	}

	method deleteEntry {filename widget} {
		if {[lindex $selected 0] != $widget} {
			$self deSelect
			eval $options(-command)
		}
		catch { file delete $filename }
		catch { file delete [filenoext $filename].dat }
		# remove the entry from the list
		set i 0
		foreach dp $dps {
			if {[lindex $dp 0] == $filename} {
				set dps [lreplace $dps $i $i]
				continue
			}
			incr i
		}
		# refill the widget
		$self drawPics
	}

	method setConfig {option value} {
		set options($option) $value
#		puts "Altering $option to $value"

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
				$self fillWidget $value
#				puts "changed to user $value"
			}
		}
	}

}
