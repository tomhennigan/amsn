#This is the TKCximage implementation inside aMSN
#By Jerome Gagnon-Voyer gagnonje5000 at mac.com

namespace eval ::picture {
catch {package require TkCximage}
			
set ::tkcximageloaded 0
	#Proc to check if tkcximage is loaded
	proc Loaded {} {
		global tcl_platform
		if {$::tkcximageloaded} {
			return 1
		} else {
			catch {package require TkCximage}
			#Fix a strange bug where sometimes package require TkCximage doesn't work
			if {![catch {tk windowingsystem} wsystem] && $wsystem == "aqua"} {
				catch {load [file join utils macosx TkCximage TkCximage.dylib]}
			} elseif { $tcl_platform(platform) == "windows"} {
				catch {load [file join utils TkCximage TkCximage.dll]}
			} else {
				catch {load [file join utils TkCximage TkCximage.so]}
			}
			
			foreach lib [info loaded] {
				if { [lindex $lib 1] == "Tkcximage" } {
					set ::tkcximageloaded 1
					return 1
				} 
			}
		}
	puts "Picture.tcl: TkCximage not loaded"
	return 0
	
	}
	
	#Convert a picture from a file to another file
	#The filename decide the new format
	proc Convert {original destination} {
		
		#Verify if the picture exists
		if { ![file exists $original] } {
			status_log "Picture.tcl: Tring to convert file $original that does not exist\n" red
			error "Picture.tcl: Tring to convert file $original that does not exist\n"
		}
		#Convert the picture
		if {[::picture::Loaded]} {
			#Use TkCxImage
			if { [catch { ::CxImage::Convert "$original" "$destination" } res ] } {
				status_log "Picture.tcl: Unable to convert picture with TkCximage \n$res" red
				error "Picture.tcl: Unable to convert picture with TkCximage \n$res"
			} else {
				return 1
			}
		} 
	}
	
	#Resize a picture from a photo
	#Strict resize, no ratio here
	proc Resize {photo width height} {
		if {[::picture::Loaded]} {
			if { [catch {::CxImage::Resize $photo $width $height } res] != 0 } {
				status_log "Picture.tcl: Unable to resize photo with TkCximage \n$res" red
				error "Picture.tcl: Unable to resize photo with TkCximage \n$res"
			}	else {
				return 1
			}
		}
	}
	
	#Reisze a picture from a file, output to another file (in option)
	proc ResizeFile {original width height {destination ""}} {
		if {$destination == ""} {
			set destination $original
		}
		if { ![file exists $original] } {
			status_log "Picture.tcl: Tring to resize file $original that does not exist\n" red
			error "Picture.tcl: Tring to resize file $original that does not exist\n"
		}
		if {[::picture::Loaded]} {
			#TkCximage
			if { [catch { 
				set photo [image create photo -file $original] 
				::CxImage::Resize $photo $width $height 
				$photo write $destination 
				image delete $photo
				} res ] } 	{
				status_log "Picture.tcl: Unable to resize picture with TkCximage \n$res" red
				error "Picture.tcl: Unable to resize picture with TkCximage \n$res"
			} else {
				return 1
			}
		}
	}
	
	#Thumbnail a picture, from a photo
	#Alpha opacity for border (between 0 and 255)	IT DOESNT SEEM TO WORK YET ?!
	#Default color for border is black
	proc Thumbnail { photo width height {bordercolor "black"} {alpha ""} } {
		if {[::picture::Loaded]} {
			if {$alpha == ""} {
			
				if { [catch {::CxImage::Thumbnail $photo $width $height $bordercolor} res] != 0 } {
					status_log "Picture.tcl: Unable to create thumbnail with TkCximage \n$res" red
					error "Picture.tcl: Unable to create thumbnail with TkCximage \n$res"
				}	else {
					return 1
				}
			} else {
				
				if { [catch {::CxImage::Thumbnail $photo $width $height $bordercolor -alpha $alpha} res ] != 0 } {
					status_log "Picture.tcl: Unable to create thumbnail with TkCximage \n$res" red
					error "Picture.tcl: Unable to create thumbnail with TkCximage \n$res"
				} else {
					return 1
				}
				
			}
		}	
	}
	
	#Crop a picture, from a photo, to a new picture (should be improved)
	proc Crop {photo x1 y1 x2 y2} {

		set temp [image create photo]
		
		if {[::picture::Loaded]} {
			if { [catch {$temp copy $photo -from $x1 $y1 $x2 $y2} res] != 0 } {
				status_log "Picture.tcl: Unable to crop image with TkCxImage\n$res" red
				error "Picture.tcl: Unable to crop image with TkCxImage\n$res"
			} else {
				image create photo $photo
				$photo copy $temp
				return 1
			}
		}
	}
	
	#Resize a picture from photo to a specific size and keep the ratio
	proc ResizeWithRatio {photo width height} {
		if {[::picture::Loaded]} {
			#Actual size of the photo
			set origw [image width $photo]
			set origh [image height $photo]
			#status_log "picture.tcl: Image size is $origw $origh\n" red
			
			#Actual ratio of the photo
			set origratio [expr { 1.0*$origw / $origh } ]
			#New ratio
			set ratio [expr { 1.0*$height / $width} ]
			#status_log "picture.tcl: Original ratio is $origratio and new ratio: $ratio\n" red
			
			#Depending on ratio, resize to keep smaller dimension to XX pixels
			if { $origratio > $ratio} {
				set resizeh $height
				set resizew [expr {round($resizeh*$origratio)}]
			} else {
				set resizew $width
				set resizeh [expr {round($resizew/$origratio)}]
			}
			
			#Resize the picture
			if { $origw != $width || $origh != $height } {
				#status_log "picture.tcl : Will resize to $resizew x $resizeh \n" red	
				if {[catch {::picture::Resize $photo $resizew $resizeh} res] } {
					error $res
				}
				
			}
			
			#Now let's crop image from the center
			set centerx [expr { [image width $photo] /2 } ]
			set centery [expr { [image height $photo] /2 } ]
			set halfw [expr { $width / 2}]
			set halfh [expr { $height / 2}]
			set x1 [expr {$centerx-$halfw}]
			set y1 [expr {$centery-$halfh}]
			if { $x1 < 0 } {
				set x1 0
			}
			if { $y1 < 0 } {
				set y1 0
			}
			
			set x2 [expr {$x1+$width}]
			set y2 [expr {$y1+$height}]
			
			set neww [image width $photo]
			set newh [image height $photo]
			
			#status_log "picture.tcl: Resized image size is $neww $newh\n" red
			#status_log "picture.tcl: Center of image is $centerx,$centery, will crop from $x1,$y1 to $x2,$y2 \n" red
			
			if {[catch {::picture::Crop $photo $x1 $y1 $x2 $y2} res]} {
				error $res
			}
			
			return 1
			
		}
	}
	#Save a picture to a file, from a photo
	#Format supported: "cxgif" "cxpng" "cxjpg" "cxtga"
	proc Save {photo destination {format ""}} {
		if {[::picture::Loaded]} {
			if {$format != ""} {
				if { [catch {$photo write $destination -format $format} res] != 0} {
					status_log "Picture.tcl: Error Saving to the file with TkCximage : \n$res" red
					error "Picture.tcl: Error Saving to the file with TkCximage : \n$res"
				} else {
					return 1
				}
			} else {
				if { [catch {$photo write $destination} res] != 0} {
					status_log "Picture.tcl: Error Saving to the file with TkCximage : \n$res" red
					error "Picture.tcl: Error Saving to the file with TkCximage : \n$res"
				} else {
					return 1
				}
			}
		}
	}	

	#Get picture size and return it with width x height format
	proc GetPictureSize { filename } {

		if { ![file exists $filename] } {
			status_log "Picture.tcl: The file doesn't exists\n" red
			error "Picture.tcl: The file doesn't exists"
		}
	
		set img [image create photo -file $filename]
		set return "[image width $img]x[image height $img]"
		image delete $img
		return $return
	}
	
	#Convert a display picture from a user to another size
	proc ConvertDPSize {user win width height} {
		global HOME
		#Get the filename of the display picture of the user
		set filename [::abook::getContactData $user displaypicfile ""]
		#If he don't have any picture, end that
		if { $filename == "" } {
			status_log "No picture found to change size"
			return
		}
		
		if {[catch {
			image create photo user_pic_$user -file "[file join $HOME displaypic cache ${filename}].png"
			::picture::Resize user_pic_$user $width $height
		} res]} {
			msg_box $res
		}
	}
}