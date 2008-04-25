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
	variable drawlock ""

	constructor { args } {
		#frame hull is created automatically

		#apply all options
		$self configurelist $args
		$self drawPics
		
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
		global HOME HOME2

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
				if { [catch { set skin [::config::getGlobalKey skin] } ] != 0 || $skin == ""} {
					set skin "default"
				}
				set default_dps [glob -nocomplain -directory [file join skins default displaypic] *.dat]
				if { $skin != "default" } {
					set locations [list [set ::program_dir] $HOME2 $HOME [file join $HOME2 amsn-extras]]
					set skin_dps [list]
					foreach dir $locations {
						if { [file exists [file join $dir skins $skin]] } {
							set skin_dps [glob -nocomplain -directory [file join $dir skins $skin displaypic] *.dat]
							break
						}
					}
					set shipped_dp_list [list]
					foreach file [concat $default_dps $skin_dps] {
						set fname [file tail $file]
						if { [lsearch $shipped_dp_list $fname] == -1 } {
							lappend shipped_dp_list $fname
						}
					}					
				} else {
					set shipped_dp_list $default_dps
				}

				set shipped_dps [lsort -index 1 [$self getMyDpsList $shipped_dp_list 1]]
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
				set user_dps [lsort -index 1 -decreasing [$self getMyDpsList [glob -nocomplain -directory [file join $HOME displaypic] *.dat]]]
			}
			if {$email_list != ""} {
				$self OrderDPs
				set cached_dps [lsort -index 1 -decreasing [$self getDpsList $email_list]]
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
					lappend pics_in_use [file join $HOME displaypic cache $email [filenoext $image_name].png]
				}
				if { $custom_image_name != "" && $custom_image_name != $image_name } {
					lappend pics_in_use [file join $HOME displaypic cache $email [filenoext $custom_image_name].png]
				}
			}
			set pics_in_use [lsort -unique $pics_in_use]
		}
	}

	# Redraw the widget - wrapper method for concurrent drawing implementation
	method drawPics { } {
		if {$drawlock != ""} {
			after cancel $drawlock
		}
		set drawlock [after 0 [list $self drawPics_core]]
	}

	# (almost) universal mouse wheel scrolling procedures
	# i think it would be better to put them in the ::gui namespace
	
	proc doMWScroll { w d {reverse 0} } {
		if {[winfo exists $w]} {
			if { [OnMac] } {
				set d [expr {-($d)}]
			}
			if { [OnWin] } {
				set d [expr {$d/-120}]
			}
			$w yview scroll $d units
		}
	}

	proc unSelectMWScroll { w } {
		if {[winfo exists $w]} {
			if { [OnMac] || [OnWin]} {
				bind [winfo toplevel $w] <MouseWheel> ""
			} elseif { [OnX11] } {
				bind [winfo toplevel $w] <4> ""
				bind [winfo toplevel $w] <5> ""
			}
		}
	}

	proc selectMWScroll { w } {
		if {[winfo exists $w]} {
			set top_w [winfo toplevel $w]
			if { [OnMac] || [OnWin] } {
				bind $top_w <MouseWheel> [list ::dpbrowser::doMWScroll $w %D]
			} elseif { [OnX11] } {
				bind $top_w <5> [list ::dpbrowser::doMWScroll $w 1]
				bind $top_w <4> [list ::dpbrowser::doMWScroll $w -1]
			}
		}
	}

	proc addMWScrolling { w } {
		if {[winfo exists $w]} {
			bind $w <Enter> "+::dpbrowser::selectMWScroll $w"
			bind $w <Leave> "+::dpbrowser::unSelectMWScroll $w"
		}
	}

	# Redraw the widget - the true method
	method drawPics_core { } {
		global HOME

		#create the scroll-frame
		catch { destroy $self.nodps }
		catch { destroy $self.sw }
		ScrolledWindow $self.sw -bg $options(-bg)
		ScrollableFrame $self.sw.sf -bg $options(-bg)
		$self.sw setwidget $self.sw.sf
		pack $self.sw -expand true -fill both
		set frame [$self.sw.sf getframe]
		addMWScrolling $self.sw.sf

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
			pack configure $self -expand 0
			if {$first_draw} {
				set first_draw 0
			}
		} else {
			foreach dp $dps {
				if {($i % $dps_per_row) == 0} {
					if {!([info exists j])} {
						set j 0
					} else {
						pack $row -side top -fill x
						incr j
					}
					set row $frame.${j}_row
					frame $row -background $options(-bg)
				}
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

					set entry $row.${i}_tile

					if {[lindex $dp 2] == ""} {
						set label [lindex $dp 1]
					} else {
						set label [lindex $dp 2]
					}
					
					sexytile $entry -type filewidget -text $label -icon $tempimage \
						-bgcolor $options(-bg) -onpress [list $self onClick $i $file] \
						-disableselect $isSelectDisabled -padding 4
					
					if {!($isSelectDisabled) && $first_select} {
						$self setSelected $i $file
					}
					
					if {[regexp ^$HOME $file] && $isinuse == -1} {
						bind $entry <ButtonRelease-3> \
							[list $self popupMenu %X %Y $file $i 1]
						if {[OnMac]} {
							bind $entry <Command-ButtonRelease> \
								[list $self popupMenu %X %Y $file $i 1]
							bind $entry <Control-ButtonRelease> \
								[list $self popupMenu %X %Y $file $i 1]
						}
					} else {
						bind $entry <ButtonRelease-3> \
							[list $self popupMenu %X %Y $file $i 0]
						if {[OnMac]} {
							bind $entry <Control-ButtonRelease> \
								[list $self popupMenu %X %Y $file $i 0]
							bind $entry <Command-ButtonRelease> \
								[list $self popupMenu %X %Y $file $i 1]
						}
					}
					
					bind $entry <Destroy> "catch { image delete $tempimage }"
					pack $entry -padx $options(-padding) -pady $options(-padding) -side left -anchor nw
					incr i
				}
			}
			if {[info exists row]} {
				pack $row -side top -fill x
			}
			if {$i == 0} {
				catch { destroy $self.sw }
				label $self.nodps -text "[trans nocacheddps]" -anchor center -pady 10
				pack $self.nodps -fill both -expand 1
				pack configure $self -expand 0
				if {$first_draw} {
					set first_draw 0
				}
			}
		}
		if {$i != 0} {
			pack configure $self -expand 1
			bind $self.sw.sf <Expose> [list $self postDraw]
		}
		# delete the lock
		set drawlock ""
	}
	
	# Execute operations after the widget has been drawn
	method postDraw {} {
		# wait if we are still drawing
		while {$drawlock != ""} {
			vwait $drawlock
		}
		bind $self.sw.sf <Expose> ""
		if {$options(-autoresize)} {
			bind $self.sw.sf <Configure> [list $self handleResize]
		}
		if {$first_draw} {
			set first_draw 0
		}
		catch { set pixelwidth [winfo width $self.sw.sf] }
		if { $selected != "" } {
			[$self getEntryFromIndex [lindex $selected 0]] setSelect
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

	# Return the entry path name from the index
	method getEntryFromIndex { i } {
		set frame [$self.sw.sf getframe]
		set dps_per_row $options(-width)
		set j [expr {int($i / $dps_per_row)}]
		return $frame.${j}_row.${i}_tile
	}

	# Select the dp and eventually update the parent's preview
	method onClick { i filepath } {
		if { $options(-mode) != "both" && $options(-mode) != "selector" } {
			return
		}
		# Backups old selected (deSelect erases it)
		set old_i [lindex $selected 0]
		$self deSelect
		if {$i != $old_i} {
			$self setSelected $i $filepath
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
			[$self getEntryFromIndex [lindex $selected 0]] deSelect
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
	method setSelected { i filepath } {
		#create tempimg if asked for
		if {$options(-createtempimg)} {
			catch {image delete $tempimg}
			set tempimg [image create photo [TmpImgName] -file $filepath]
			set selected [list $i $filepath $tempimg]
		} else {
			set selected [list $i $filepath]
		}
	}


	# This proc is used to move dps that there are in "displaypic cache" in "displaypic cache $email"
	# This proc is called everytime we show the dp_browser, but only the first time it (should) order(s) all DPs.
	method OrderDPs {} {
		global HOME

 		set dat_list [glob -nocomplain -directory [file join $HOME displaypic cache] *.dat]

		foreach dat_file $dat_list {
			
			set fd [open $dat_file]
			#first line is date or name (for shipped dps)
			#second line is id of the user or filename for shipped dps
			set date [gets $fd]
			set id [gets $fd]
			close $fd

			set dir [file join $HOME displaypic cache $id]
			create_dir $dir
			;# we are sure that *.dat exists, while *.png cound not exist
			catch { file rename -force $dat_file $dir }
			catch { file rename -force "[filenoext $dat_file].png" $dir }

		}
	}

	# Return the list of the dps for a list of users
	method getDpsList { email_list } {
		global HOME
		set dps_list ""
		foreach email $email_list {

			set dat_list [glob -nocomplain -directory [file join $HOME displaypic cache $email] *.dat]

			foreach dat_file $dat_list {
				set fd [open $dat_file]
				#first line is date or name (for shipped dps)
				#second line is id of the user or filename for shipped dps
				set date [gets $fd]
				set id [gets $fd]
				close $fd
				
				set readable_date [$self convertdate $date]
				lappend dps_list [list $dat_file $date $readable_date]
			}
		}
		return $dps_list
	}

	# Return the list of our dps.
	method getMyDpsList { dat_list {isShipped 0} } {
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
			
			set readable_date [$self convertdate $date]
			lappend dps_list [list $file $date $readable_date]
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
	method popupMenu { X Y filename i enable_delete} {
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
				-command [list $self deleteEntry $filename $i]
		}
		$the_menu add command -label "[trans setasmydp]" \
			-command [list set_displaypic $filename]
		$the_menu add command -label "[trans save]" \
			-command [list $self saveFile $filename]
		tk_popup $the_menu $X $Y
	}

	method saveFile {filename} {
		set name [file tail $filename]
		set newfilename [chooseFileDialog "$name" "[trans save]" "" "" save]
		catch {file copy $filename $newfilename}
	}

	# Delete a dp from the hard disk
	method deleteEntry {filename i} {
		if {[lindex $selected 0] == $i} {
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
