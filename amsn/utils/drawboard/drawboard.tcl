##Drawboard widget by Karel Demeyer
#
#    NAME
#
#       drawboard - Create and manipulate drawboard widgets
#
#   SYNOPSIS
#
#       drawboard pathName ?options? 
#
#   STANDARD OPTIONS
#
#       ...
#
#   WIDGET-SPECIFIC OPTIONS
#
#       -grid, grid, Grid 
#       -drawmode, drawmode, Drawmode 
#       -color, color, Color 
#       -pencil, pencil, Pencil
#       -width, width, Width
#       -height, height, Height
#
#   WIDGET COMMAND
#
#       pathName cget option 
#       pathName configure ?option? ?value option value ...? 


#TODO: 
# -gridimg option
# provide 1 default pencil and 1 default gridimg
# Improved Saving
# Loading
# fixed dimensions (-width / -height doesn't work yet properly)
# remove amsn plus button
# review cutting .. it has bugs


package require snit
package provide drawboard 0.2

snit::widgetadaptor drawboard {

	option -grid -default 1 -configuremethod SetConfig
	option -drawmode -default free
	option -color -default black -configuremethod SetConfig
	option -pencil -default pencil1 -configuremethod SetConfig
	option -width -default 100
	option -height -default 100
#	option -gridimg

	
	variable buttondown
	variable oldx
	variable oldy
	variable endx
	variable endy
	variable gridsourceimg
	variable strokes_list
	variable curStroke


	constructor { args } {
		installhull using canvas -bg white -relief flat -highlightthickness 0 -width $options(-width) -height $options(-height)
				
status_log "creating drawboard widget $self"

		$self configurelist $args
#		if {$options(-gridimg) == ""} {
#			set gridsourceimg [$self LoadImage drawboardgrid grid.png]
#		} else {
#			set gridsourceimg $options(-gridimg)
#		}

		set gridsourceimg [::skin::loadPixmap grid]

#		#give the grid a color
		::picture::Colorize $gridsourceimg blue


		#create the image where we will copy the grid on (tiled)
		image create photo grid$self
		#put the grid-image (initially empty) on the canvas
		$hull create image 0 0 -anchor nw -image grid$self -tag grid
		
		#create the initial drawboard img
		set drawboard [image create photo] ;# -width $width -height $height]
		#put the drawboard-img on the canvas
		$hull create image 0 0 -anchor nw -image $drawboard -tag drawboard

		#make it possible to disable coloring of pencils, for "stamps" (like using smileys as pencil)
		$self SetConfig coloring 1

		$self UpdatePencil
		
		set endx 0
		set endy 0
	
		set strokes_list [list]

		#bindings
		bind $self <ButtonPress-1> "$self ButtonDown"

		bind $self <B1-Motion> "$self MouseMove"

		bind $self <ButtonRelease-1> "$self ButtonRelease"
		
		bind $self <Configure> "$self Configure"

		$self configurelist $args

	}


	method LoadImage { imagename filename} {
		return [image create photo $imagename -file $filename.gif]
	}


	###############################################
	# When mousebutton pressed                    #
	###############################################
	method ButtonDown {} {

		set drawboard [$hull itemcget drawboard -image]

		#change the buttondown-flag
		set buttondown 1
		
		#set initial coordinates of the mouse on the drawboard
		set oldx [expr {[winfo pointerx $self] - [winfo rootx $self]}]

		set oldy [expr {[winfo pointery $self] - [winfo rooty $self]}]

		set curStroke [list $oldx $oldy]

		$self DrawDot $oldx $oldy

		$self SetEnds $oldx $oldy		
		
	}
	


	###############################################
	# When mousebutton is released                #
	###############################################
	method ButtonRelease {} {

		if { $options(-drawmode) == "line"} {
			set drawboard [$hull itemcget drawboard -image]

			set newx [expr {[winfo pointerx $self] - [winfo rootx $self]}]

			set newy [expr {[winfo pointery $self] - [winfo rooty $self]}]

			$self DrawLine  $oldx $oldy $newx $newy

			$self SetEnds $newx $newy

			lappend curStroke $newx $newy

		}

		lappend strokes_list $curStroke

		#change the buttondown-flag
		set buttondown 0
			
		unset oldx oldy

	}
	
	###############################################
	# When the mouse is moved                     #
	###############################################
	method MouseMove {} {
		
		if { $options(-drawmode) == "free" } {
			#If we're dragging, draw
			if {$buttondown} {
				#Get the names of the items
				set drawboard [$hull itemcget drawboard -image]		
		
				#find the coordinates of the mouse on the selfas (drawboard)
				set posx [expr {[winfo pointerx $self] - [winfo rootx $self]}]

				set posy [expr {[winfo pointery $self] - [winfo rooty $self]}]

				#if the coords made a jump, draw a line between 'm, otherwise just draw a dot
				if {[expr abs($oldx - $posx)] > 2 || [expr abs($oldy - $posy)] > 2} {
					$self DrawLine $oldx $oldy $posx $posy
				} else {
					$self DrawDot $posx $posy
				}
				#remember where we were
				set oldx $posx
				set oldy $posy
				
				lappend curStroke $oldx $oldy

				$self SetEnds $posx $posy
			}
		}
	}

	
	###############################################
	# Draws a dot with the pencil on given coords #
	###############################################
	method DrawDot { x y } {

		set drawboard [$hull itemcget drawboard -image]

		set x [expr {$x - [image width pencil_$self]/2}]
		set y [expr {$y - [image height pencil_$self]/2}]

		#only draw if on the drawboard
		if {$x > 0 && $y > 0 && $x < [$drawboard cget width] && $y < [$drawboard cget height]} {
			$drawboard copy pencil_$self -to $x $y 
		}
	}

	###############################################
	# Draws a line between 2 given coord-pairs    #
	#  with the pencil                            #
	###############################################
	method DrawLine { x1 y1 x2 y2 } {

		set drawboard [$hull itemcget drawboard -image]
		
		set xsize [$drawboard cget width]
		set ysize [$drawboard cget heigth]

		#if we end off the board, end on the edge
		if {$x2 < 0} { set x2 0}
		if {$y2 < 0} { set y2 0}
		if { $x2 > $xsize } { set x2 $xsize }
		if { $y2 > $ysize } { set y2 $ysize }

		#calculate the x and y distance
		set xdist [expr {($x1 - $x2)*1.0}]
		set ydist [expr {($y1 - $y2)*1.0}]
		#also get there absolute values
		set absxdist [expr {abs($xdist)}]
		set absydist [expr {abs($ydist)}]
		#calculate the x and y diffs
		if {$absxdist > $absydist} {
			set absdist $absxdist
		} else {
			set absdist $absydist
		}		
		if {$absdist == 0} { 
			set xdiff 0
			set ydiff 0
		} else { 
			set xdiff [expr {$xdist / $absdist}]
			set ydiff [expr {$ydist / $absdist}]
		}
		set steps $absdist
		#draw the line
		for {set idx 0} { $idx < $steps } {incr idx } {

			set x1 [expr {$x1 - $xdiff}]
			set y1 [expr {$y1 - $ydiff}]

			$self DrawDot [expr int($x1)] [expr int($y1)]
		}
	}

	method Configure {} {

		#get the new dimensions
		set width [winfo width $self]
		set height [winfo height $self]

		if { $height < $endy } {
			set endy $height
		}
		if { $width < $endx } {
			set endx $width
		}
			

		set drawboard [$hull itemcget drawboard -image]	
		$drawboard configure -width $width -height $height
		$self UpdateGrid		
	}

	method UpdateGrid { } {
		if { $options(-grid) == 1 } {
			set width  [winfo width $self]
			set height [winfo height $self]
			grid$self copy $gridsourceimg -to 0 0 $width $height -shrink			
		} else {
			catch {grid$self blank}
		}
	}
		

	method SetEnds {x y} {
		set farx [expr $x + [image width pencil_$self]]
		set fary [expr $x + [image height pencil_$self]]

		if { $farx > $endx } {
			set endx $farx
		}
		if { $fary > $endy } {
			set endy $fary
		}
	}
	
	

	method ClearDrawboard {} {
		[$hull itemcget drawboard -image] blank
		set endx 0
		set endy 0
		
		set strokes_list [list]
		set curStroke_x [list]
		set curStroke_y [list]

	}
	
	
#TODO:
	method LoadDrawing { filename } {
#		$self ClearDrawboard	



		#draw loaded image
		set drawboard [$hull itemcget drawboard -image]	
		set loadedimg [image create photo -file $filename]
		$drawboard copy $loadedimg
		
		$self SetEnds [image width $loadedimg] [image height $loadedimg]
	
		$self Configure
	}
	

#TODO: needs 'path'/'filename' vars where it will save, now in pwd, as "inktosend.gif"
	method SaveDrawing {filename {gifFortified 0}} {

		set drawboard [$hull itemcget drawboard -image]	
		
		#to make sure the ends are not to far and all is right
		set boardh [image height $drawboard]
		set boardw [image width $drawboard]
		if {$boardh < $endy} {
			set endy $boardh
		}
		if {$boardw < $endx} {
			set endx $boardw
		}
		
		#only save to the most far used coordinates
		image create photo temp

		temp copy $drawboard -from 0 0 $endx $endy
		image create photo $drawboard
		$drawboard copy temp
		
		#put the drawboard on a white background
		image create photo copytosend ;# -width [image width $drawboard] -height [image height $drawboard]

		#fix the "cannot save empty file" bug
		if { $endx == 0 || $endy == 0 } {
			copytosend put {#ffffff} -to 1 1 [image width $drawboard] [image height $drawboard]
		} else {
			copytosend put {#ffffff} -to 0 0 [image width $drawboard] [image height $drawboard]
		}

		copytosend copy $drawboard

		set endx 0
		set endy 0
	
		::picture::Save copytosend $filename cxgif

		# Fortify the GIF with the strokes_list
		if {$gifFortified && ![catch {package require tclISF}]} {
			if {[catch {[tclISF_save $filename $strokes_list]} err]} {
				status_log "\[SaveDrawing\] saving to file $filename. Got Error : $err" red
				status_log "$strokes_list" red
			}
		}

		image delete copytosend
		image delete temp		

#status_log "::MSN::SendInk [lindex [::MSN::SBFor $contact] 0] inktosend.gif"
#		::MSN::SendInk [lindex [::MSN::SBFor $contact] 0] inktosend.gif
		
	}



	method ToggleGrid {} {
		if { $options(-grid) == 1} {
			$self SetConfig -grid 0
		} else {
			$self SetConfig -grid 1
		}
	}	


	method SetConfig {option value} {
		set options($option) $value

		#actions after change of options
		#the space was added so the option isn't passed to the switch command
		switch " $option" {
			" -grid" {
				$self UpdateGrid
			}
			" -pencil" {
				$self UpdatePencil
			}
			" -color" {
				$self UpdatePencil
			}			
		}
			
	}

	method UpdatePencil { } {
		set pencilname $options(-pencil) 
		
		#if the pencil img already exists, delete it first before we (re)make it
		catch { image delete pencil_$self }

		set  pencilimg [::skin::loadPixmap $pencilname]

		#get the dimensions for the pencil-image
		set width [image width $pencilimg]
		set height [image height $pencilimg]

		#create the pencil image 
		image create photo pencil_$self -width $width -height $height
		
		#copy the source-img on the new (still empty) pencil image
		pencil_$self copy $pencilimg			

		if {$options(-color) != "white" && $options(-color) != "FFFFFF"} {
			#color the pencil
			::picture::Colorize pencil_$self $options(-color)
		}
	}		



}
