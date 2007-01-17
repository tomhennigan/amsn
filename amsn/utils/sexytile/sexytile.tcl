package require snit
package provide sexytile 0.1

snit::widgetadaptor sexytile {
	
	option -width -configuremethod setConfig
	option -height -configuremethod setConfig
	option -bgcolor -default white  -configuremethod setConfig

	#type can be: button, checkbutton, tilebutton, filewidget
	option -type -default "tilebutton" -configuremethod setConfig\
		-readonly 1
	#tilebutton has nog bgimage default, on hover it becomes a button and\
	  on press it's a pressed button

	#textorientation can be: n, e, s, w (north, east, south, west),\
	  default is east
#	option -textorientation -default "e" -configuremethod setConfig\
		-readonly 1
	
	option -bgimage_default  -readonly 1
	option -bgimage_hover -readonly 1
	option -bgimage_pressed -readonly 1

	option -icon -configuremethod setConfig
	
	option -text -configuremethod setConfig
	
	option -textcolor -default black -configuremethod setConfig
	
	option -border -default 5 -configuremethod setConfig -readonly 1
	
	option -padding -default 5  -configuremethod setConfig -readonly 1

	#command to execute when button is pressed or checkbutton is changed
	option -onpress -configuremethod setConfig
	
	#boolean value for checkbutton
	option -value -default 0 -configuremethod setConfig


	constructor { args } {

		#create the base canvas
		installhull using canvas -bg white -bd 0 -relief flat

		#set the chosen settings
		$self configurelist $args
		puts "created sexytile widget $self with arguments $args at $hull"

		#add the bg image
		image create photo bgimage_default
		$hull create image 0 0 -anchor nw -tag bgimage -image bgimage_default


		image create photo transp -file utils/sexytile/transp.png


		if {$options(-icon) != ""} {
			$hull create image 0 0 -image $options(-icon) -tag icon
		}
		if {$options(-text) != ""} {

			$hull create text 0 0 -fill $options(-textcolor) -text $options(-text) -tag text
		}


		#set widget default size and text properties accoring to type		
		switch $options(-type) {
			"filewidget" {
				if {$options(-width) == ""} {
					set options(-width) 100
				}
				if {$options(-height) == ""} {
					set options(-height) 120
				}
				$hull itemconfigure text -anchor n -justify center
			}
			default {
				#default is "tilebutton"
				if {$options(-width) == ""} {
					set options(-width) 150
				}
				if {$options(-height) == ""} {
					set options(-height) 70
				}
				$hull itemconfigure text -anchor w
			}
		}
		$hull configure -width $options(-width) -height $options(-height)
		
		
		#size the bgimages accoring to canvas size
		#$self resizeImages
		#not needed as happens with configure binding when packed
		
		#set bg and hover/pressed bindings, according to type
		switch $options(-type) {
			"button" {
				#hover bindings; bg becomes button
				bind $self  <Enter> "$hull itemconfigure bgimage\
					-image bgimage_hover"
				bind $self <Leave> "$hull itemconfigure bgimage\
					-image bgimage_default"
				#change image while button pressed
				bind $self <ButtonPress-1> "$hull itemconfigure bgimage\
					-image bgimage_pressed"
				#reset image on release event and execute action
				bind $self <Button1-ButtonRelease> "$hull itemconfigure bgimage -image bgimage_hover; $self execAction"
			
			}
			"checkbutton" {
				puts "checkbutton is not supported"
			
			}
			"filewidget" {
#TODO!				#hover bindings; icon lights up (overlay with transp white image)
				bind $self  <Enter> ""
				bind $self <Leave> ""
				#singleclick selects; icon overlayed with color, text selected

				#action is triggered on doubleclick


				bind $self <ButtonPress-1> "$self setSelect"
				#execute action
				bind $self <Button1-ButtonRelease> "$self execAction"
			
			}
			default {
			#"tilebutton" is the default behaviour		
				#hover bindings; bg becomes button
				bind $self  <Enter> "$hull itemconfigure bgimage\
					-image bgimage_hover"
				bind $self <Leave> "$hull itemconfigure bgimage\
					-image bgimage_default"
				#change image while button pressed
				bind $self <ButtonPress-1> "$hull itemconfigure bgimage\
					-image bgimage_pressed"
				#reset image on release event and execute action
				bind $self <Button1-ButtonRelease> "$hull itemconfigure bgimage -image bgimage_hover; $self execAction"

			}
		}
		
		#configure binding (is triggered when widget is packed)
		bind $self <Configure> "$self widgetResized %w %h"
		bind $self <Destroy> "$self cleanUp"
	}
				
			
	method highLight { } {
	
	
	
	}

	method toggleSelection { } {
		if  {$options(-value) == 1} {
			$self deSelect			
		} else {
			$self setSelect		
		}
	}

	method setSelect {} {
		set selcolor red
		#this is for filewidget type only for now
		if {$options(-type) == "filewidget"} {
			#Select the text
			$hull create rectangle [$hull bbox text] -fill $selcolor -tag textsel
			$hull lower textsel

			#Select the image
			#TODO: overlay with color
		}
		set options(-value) 1
	}
	
	method deSelect {} {
		#this is for filewidget type only for now
		if {$options(-type) == "filewidget"} {
			#remove the selection of the text
			$hull delete textsel
		
			#TODO: remove the selection of the image
		}
		set options(-value) 0
	}

	method execAction {} {
		#execute the defined action
		#FIXME:  should be only if the mouse is still on the button
		if {[catch {eval $options(-onpress)} error] && $options(-onpress) != ""} {
			status_log "error running defined command for tile:\n$error" white
		}	


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
			" -type" {
				if {[lsearch [list "checkbutton" "tilebutton" "button"] $value] == -1} {
					#wrong option
#					puts "wrong option"
				}
			}
			" -text" {

			}
		}
			
	}
	
	method widgetResized {width height} {
		#resize the bgimages
		$self reloadImages $width $height

		#(re)place the text/icon
		switch $options(-type) {
			"tilebutton" {
			#eastern text for tilebuttons and listview filebrowsing
				set xcoord $options(-border)
				set ycoord [expr {$height/2}]
				if {$options(-icon) != ""} {
					#place the image; if no text, center the icon:
					if {$options(-text) == ""} {
						set xcoord [expr {$width/2}]
					} else {
						set xcoord [expr {$options(-border) +\
							[image width $options(-icon)]/2}]
					}
			
					$hull coords icon $xcoord $ycoord 
					
					set xcoord [expr {$options(-border) + [image width $options(-icon)] + $options(-padding)}]
				}
				set textwidth [expr {$width - $options(-border) - $xcoord}]
#puts "$xcoord $ycoord"
				#now the text placement:
				$hull coords text $xcoord $ycoord
				$hull itemconfigure text -width $textwidth
			}
			"filewidget" {
			#south text for instance for filebrowsers
				set ycoord $options(-border)
				set xcoord [expr {$width/2}]
				if {$options(-icon) != "null"} {
					#place the image
					#if no text, center the icon:
					if {$options(-text) == ""} {
						set ycoord [expr {$height/2}]
					} else {
						set ycoord [expr {$options(-border) +\
							[image height $options(-icon)]/2}]
					}
			
					$hull coords icon $xcoord $ycoord 
				
					set ycoord [expr {$options(-border) + [image height $options(-icon)] + $options(-padding)}]
				}
				set textwidth [expr {($width - 2*$options(-border))}]
	
				#now the text placement:
				$hull coords text $xcoord $ycoord
				$hull itemconfigure text -width $textwidth
			}
			default {
				puts "Only tilebutton and filewidget supported for now."
			
			}
			
			
		}	
	}
	
	method reloadImages {width height} {
		#size the bgimages accoring to canvas size
#		puts "\t* scaling images as requested to $width $height"		

		foreach photo [list bgimage_default bgimage_hover bgimage_pressed] {
			catch {image delete $photo}
			image create photo $photo
			if { $options(-$photo) != "" } {
				$photo copy $options(-$photo)
#TODO: instead of resize, rebuild images from pieces"
				if [catch {::picture::Resize $photo $width $height} error] {
					status_log "error in sexytile.tcl: $error"
				}
			}			
		}
	}
	
	method cleanUp {} {
#		puts "Cleaning up ..."
		foreach photo [list bgimage_default bgimage_hover bgimage_pressed] {
			catch {image delete $photo}
		}
	}

}
