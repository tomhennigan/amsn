package require snit
package require sexytile
package provide dpbrowser 0.4


snit::widget dpbrowser {

	option -user -default "self" -configuremethod setConfig
	option -width -default 5

	option -bg -default white -readonly 1
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
	option -invertmatch -default 0
	option -firstselect -default "" -readonly 1

	variable selected ""
	variable tempimg ""
	variable pics_in_use ""
	variable entry_in_use ""
	variable dps ""
	variable first_draw 1

	constructor { args } {
		#frame hull is created automatically

		#apply all options
		$self configurelist $args
		$self drawPics
		set first_draw 0
		
		bind $self <Destroy> [list $self cleanUp]
	}

	# Remove the selected dp's temp image (if any)
	method cleanUp { } {
		if {$options(-createtempimg)} {
			#remove tempimg
			catch {image delete $tempimg}
		}
	}

	# Generate the dps list for the specified users
	method fillWidget { } {
		global HOME

		set selected ""

		set email_list $options(-user)
		set n_email [llength $email_list]

		if {$email_list != ""} {
		#if no user is specified
			if {$email_list == "all"} {
				set email_list ""
			}

			set shipped_dps ""
			set user_dps ""
			set cached_dps ""
			
			set self_index [lsearch -sorted $email_list "self"]
			
			if {$self_index != -1 && !($options(-invertmatch))} {
				set email_list [lreplace $email_list $self_index $self_index]
				set shipped_dps [lsort -index 1 [$self getDpsList [glob -nocomplain -directory [file join skins default displaypic] *.dat] "self" 1]]
				set shipped_dps [linsert $shipped_dps 0 [list "" "nopic" "[trans nopic]"]]
				# Delete dat files for non-existing png files
				set dat_files [lsort [glob -nocomplain -directory [file join $HOME displaypic] *.dat]]
				set png_files [lsort [glob -nocomplain -directory [file join $HOME displaypic] *.png]]
				foreach file $dat_files {
					if {[lsearch -sorted $png_files "[filenoext $file].png"] == -1} {
						file delete $file
					}
				}
				# Create dat files for new png files
				foreach file $png_files {
					if {[lsearch -sorted $dat_files "[filenoext $file].dat"] == -1} {
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
				set user_dps [lsort -index 1 -decreasing [$self getDpsList [glob -nocomplain -directory [file join $HOME displaypic] *.dat] "self"]]
			}
			if {$email_list != ""} {
				set cached_dps [lsort -index 1 -decreasing [$self getDpsList [glob -nocomplain -directory [file join $HOME displaypic cache] *.dat] $email_list]]
			}
						
			set dps [concat $shipped_dps $user_dps $cached_dps]
			
			set pics_in_use ""
			if {$self_index != -1} {
				set image_name [::config::getKey displaypic]
				if {$image_name != "nopic.gif"} {
					lappend pics_in_use [file join $HOME displaypic [filenoext $image_name].png]
				}
			}
			foreach email $email_list {
				set image_name [::abook::getContactData $email displaypicfile ""]
				set custom_image_name [::abook::getContactData $email customdp ""]
				if {$image_name != ""} {
					lappend pics_in_use [file join $HOME displaypic cache [filenoext $image_name].png]
				}
				if { $custom_image_name != "" && $custom_image_name != $image_name } {
					lappend pics_in_use [file join $HOME displaypic cache [filenoext $custom_image_name].png]
				}
			}
			set pics_in_use [lsort -unique $pics_in_use]
		}
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

		set email_list $options(-user)
		set n_email [llength $email_list]
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

		if {$email_list == ""} {
			catch { destroy $self.sw }
			label $self.nodps -text "[trans nouserspecified]" -anchor center -pady 10
			pack $self.nodps -fill both -expand 1
		} else {
			foreach dp $dps {
				if {[lindex $dp 0] != ""} {
					set file [filenoext [lindex $dp 0]].png
				} else {
					set file ""
				}

				#exclude the image the users are currently using
				set isinuse [lsearch -sorted $pics_in_use $file]
				
				if { $options(-showcurrent) != 0 || $isinuse == -1 } {
					set first_select 0
					if {$first_draw && $n_email == 1 && $file == $options(-firstselect)} {
						set first_select 1
					}
					if { $file != "" } {
						#if a problem loading the image arises, go to next
						if { [catch { set tempimage [image create photo [TmpImgName] -file $file -format cximage] }] } { continue }
					} else {
						set tempimage [image create photo [TmpImgName] -file [[::skin::getNoDisplayPicture] cget -file] -format cximage]
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
					
					if {!($isSelectDisabled) && $first_select} {
						$self setSelected $entry $file
					}

					if {[regexp ^$HOME $file] && $isinuse == -1} {
						bind $entry <ButtonRelease-3> \
							[list $self popupMenu %X %Y $file $entry 1]
						if {[OnMac]} {
							bind $entry <Command-ButtonRelease> \
								[list $self popupMenu %X %Y $file $entry 1]
							bind $entry <Control-ButtonRelease> \
								[list $self popupMenu %X %Y $file $entry 1]
						}
					} else {
						bind $entry <ButtonRelease-3> \
							[list $self popupMenu %X %Y $file $entry 0]
						if {[OnMac]} {
							bind $entry <Control-ButtonRelease> \
								[list $self popupMenu %X %Y $file $entry 0]
							bind $entry <Command-ButtonRelease> \
								[list $self popupMenu %X %Y $file $entry 1]
						}
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

	# Return the list of the dps for a list of users
	method getDpsList { dat_list email_list {isShipped 0} } {
		set dps_list ""
		foreach dat $dat_list {
			if {$isShipped} {
				set file [::skin::GetSkinFile displaypic [file tail $dat]]
			} else {
				set file $dat
			}
			
			set fd [open $file]
			#first line is date or name (for shipped dps)
			#second line is id of the user or filename for shipped dps
			set date [gets $fd]
			set id [gets $fd]
			close $fd
			
			if {$email_list == "self" || ([lsearch -sorted $email_list $id] != -1)} {
				set found_match 1
			} else {
				set found_match 0
			}
			if {$found_match != $options(-invertmatch)} {
				set readable_date [$self convertdate $date]
				lappend dps_list [list $file $date $readable_date]
			}
		}
		return $dps_list
	}

	# Convert a date in the format the user has specified in the preferences
	method convertdate { date } {
		if {[catch {clock format $date -format %D}]} {
			return ""
		}
		set day [clock format $date -format %d]
		set month [clock format $date -format %m]
		set year [clock format $date -format %Y]
		switch "[::config::getKey dateformat]" {
			"MDY" {
				return "$month/$day/$year"
			}
			"DMY" {
				return "$day/$month/$year"
			}
			"YMD" {
				return "$year/$month/$day"
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
		if {[lindex $selected 0] == $widget} {
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

		#actions after change or initial setting of options
		switch -- $option {
			-user {
				set options(-user) [lsort -unique $value]
				#empty the widget and refill it for other user
				$self fillWidget
				if {!($first_draw)} {
					$self drawPics
				}
			}
			-autowidth {
				if {$value} {
					# discard the fixed width value
					set options(-width) 0
					$self autoWidth
				}
			}

		}
	}

}
