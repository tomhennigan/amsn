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
	option -command -default ""

	option -showcurrent -default 1
	option -padding -default 5 -readonly 1
	option -createtempimg -default 0
	option -autoresize -default 1 -configuremethod setConfig

	variable selected ""
	variable tempimg ""
	variable pic_in_use ""
	variable custom_pic_in_use ""
	variable entry_in_use ""
	variable dps ""

	constructor { args } {
		#frame hull is created automatically

		#apply all options
		$self configurelist $args
		
		bind $self <Destroy> [list $self cleanUp]
	}

	# Remove the selected dp's temp image (if any)
	method cleanUp { } {
		if {$options(-createtempimg)} {
			#remove tempimg
			catch {image delete $tempimg}
		}
	}

	# Generate the dps list for the specified user and redraw the widget
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
				set image_name [::abook::getContactData $email displaypicfile ""]
				set custom_image_name [::abook::getContactData $email customdp ""]
				if {$image_name != ""} {
					set pic_in_use [file join $HOME displaypic cache [filenoext $image_name].png]
				} else {
					set pic_in_use ""
				}
				if { $custom_image_name != "" } {
					set custom_pic_in_use [file join $HOME displaypic cache [filenoext $custom_image_name].png]
				} else {
					set custom_pic_in_use $pic_in_use
				}
			} else {
				set pic_in_use [displaypicture_std_self cget -file]
				set custom_pic_in_use $pic_in_use
				set dps [linsert $dps 0 [list "" "nopic" "[trans nopic]"]]
			}
		}
		$self drawPics
	}

	# Redraw the widget
	method drawPics { } {
		global HOME

		#create the scroll-frame
		catch { destroy $self.nodps }
		catch { destroy $self.sw }
		ScrolledWindow $self.sw -bg $options(-bg)
		ScrollableFrame $self.sw.sf -bg $options(-bg)
		$self.sw setwidget $self.sw.sf
		pack $self.sw -expand true -fill both
		set frame [$self.sw.sf getframe]

		# if width is not consistent, calculate it
		if { $options(-width) < 1 } {
			$self autoWidth
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
			catch { destroy $self.sw }
			label $self.nodps -text "[trans nouserspecified]" -anchor center -pady 10
			pack $self.nodps -fill both -expand 1
		} else {
			foreach dp $dps {
				#exclude the image the user is currently using
				if { $options(-showcurrent) != 0 || [string first $pic_in_use [lindex $dp 0]] == -1 } {
					if {[lindex $dp 0] != ""} {
						set file [filenoext [lindex $dp 0]].png
						#if a problem loading the image arises, go to next
						if { [catch { set tempimage [image create photo [TmpImgName] -file $file -format cximage] }] } { continue }
					} else {
						set file ""
						set tempimage [image create photo [TmpImgName] -file [displaypicture_std_none cget -file] -format cximage]
					}

					::picture::ResizeWithRatio $tempimage 96 96

					set entry $frame.${i}_tile

					if {[lindex $dp 2] == ""} {
						set label [lindex $dp 1]
					} else {
						set label [lindex $dp 2]
					}

					sexytile $entry -type filewidget -text $label -icon $tempimage \
						-bgcolor $options(-bg) -onpress [list $self onClick $entry $file] \
						-disableselect $isSelectDisabled -padding 4
					
					if {$file == $custom_pic_in_use} {
						$self setSelected $entry $file
					}
					
					if {[regexp ^$HOME $file] && $file != $pic_in_use && $file != $custom_pic_in_use} {
						bind $entry <ButtonRelease-3> \
							[list $self popupMenu %X %Y $file $entry 1]
					} else {
						bind $entry <ButtonRelease-3> \
							[list $self popupMenu %X %Y $file $entry 0]
					}

					bind $entry <Destroy> "catch { image delete $tempimage }"
					grid $entry \
						-row [expr {$i / $dps_per_row}] -column [expr {$i % $dps_per_row}] \
						-pady $options(-padding) -padx $options(-padding)
					incr i
				}
			}
			if {$i == 0} {
				catch { destroy $self.sw }
				label $self.nodps -text "[trans nocacheddps]" -anchor center -pady 10
				pack $self.nodps -fill both -expand 1
			}
		}

		if {$i != 0} {
			bind $self.sw.sf <Expose> [list $self postDraw]
		}
	}
	
	# Execute operations after the widget has been drawn
	method postDraw {} {
		bind $self.sw.sf <Expose> ""
		catch { set pixelwidth [winfo width $self.sw.sf] }
		if {$options(-autoresize)} {
			bind $self.sw.sf <Configure> [list $self handleResize]
		}
		if { $selected != "" } {
			[lindex $selected 0] setSelect
		}
	}

	# Calculate the widget width (n of dps) from its pixel width
	method autoWidth { } {
		if {$options(-autoresize)} {
			if {[catch { set pixelwidth [winfo width $self.sw.sf] }]} {
				return 0
			}
			set padding $options(-padding)
			set new_width [ expr { int(floor($pixelwidth/(100+2*$padding))) } ]
			if { $new_width != $options(-width)} {
				if {$new_width > 0} {
					set options(-width) $new_width
					return 1
				} else {
					# Fix width if it's in inconsinstent state
					if {$options(-width) < 1} {
						set options(-width) 1
						return 1
					}
				}
			}
		}
		return 0
	}

	# Rearrange dps in the widget when it's resized
	method handleResize { } {
		if {[$self autoWidth]} {
			$self drawPics
		}
	}

	# Select the dp and eventually update the parent's preview
	method onClick { entry filepath } {
		if { $options(-mode) != "both" && $options(-mode) != "selector" } {
			return
		}
		# Backups old selected (deSelect erases it)
		set oldentry [lindex $selected 0]
		$self deSelect
		if {$entry != $oldentry } {
			$self setSelected $entry $filepath
		}
		eval $options(-command)
	}

	# Deselect all dps in the widget
	method deSelect {} {
		if {$options(-createtempimg)} {
			#remove former tempimg
			catch {image delete $tempimg}
		}
		if {$selected != ""} {
			[lindex $selected 0] deSelect
		}
		set selected ""
	}

	# Return the currently selected dp in the form of a list:
	# 0: Name of the entry that shows the selected dp
	# 1: Path of the file
	# 2: Temp image to use for previews (optional)
	method getSelected {} {
		return $selected
	}

	# Set the specified entry and file as selected
	method setSelected { entry filepath } {
		#create tempimg if asked for
		if {$options(-createtempimg)} {
			catch {image delete $tempimg}
			set tempimg [image create photo [TmpImgName] -file $filepath]
			set selected [list $entry $filepath $tempimg]
		} else {
			set selected [list $entry $filepath]
		}
	}

	# Return the list of the dps for an user
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

	# Parse informations contained in dps' descriptor files
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

	# Copy a dp in the clipboard
	method copyDpToClipboard { file } {
		clipboard clear
		clipboard append $file
	}

	# Show a popup menu to interact with a dp
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
			-command [list $self copyDpToClipboard $filename]
		if { $enable_delete } {
			$the_menu add command -label "[trans delete]" \
				-command [list $self deleteEntry $filename $widget]
		}
		$the_menu add command -label "[trans setasmydp]" \
			-command [list set_displaypic $filename]
		tk_popup $the_menu $X $Y
	}

	# Delete a dp from the hard disk
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

	# Configure the widget according to the options
	method setConfig {option value} {
		set options($option) $value
#		puts "Altering $option to $value"

		#actions after change or initial setting of options
		#the space was added so the option isn't passed to the switch command
		switch " $option" {
			" -user" {
				#empty the widget and refill it for other user
				$self fillWidget $value
#				puts "changed to user $value"
			}
			" -autowidth" {
				if {$value} {
					# discard the fixed width value
					set options(-width) 0
				}
			}

		}
	}

}
