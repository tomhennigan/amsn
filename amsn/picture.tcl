#This is the TKCximage implementation inside aMSN
#By Jerome Gagnon-Voyer gagnonje5000 at mac.com

namespace eval ::picture {
catch {package require TkCximage}
			
set ::tkcximageloaded 0
	#Proc to check if tkcximage is loaded
	proc Loaded {} {

		if {$::tkcximageloaded} {
			return 1
		} else {
			catch {package require TkCximage}
			foreach lib [info loaded] {
				if { [lindex $lib 1] == "Tkcximage" } {
					set ::tkcximageloaded 1
					return 1
				} 
			}
		}
	status_log "Picture.tcl: TkCximage not loaded" red
	return 0
	
	}
	
	#Convert a picture from a file to another file
	#The filename decide the new format
	proc Convert {original destination} {
		
		#Verify if the picture exists
		if { ![file exists $original] } {
			status_log "Picture.tcl: Tring to convert file $original that does not exist\n" red
			return 0
		}
		#Convert the picture
		if {[::picture::Loaded]} {
			#Use TkCxImage
			if { [catch { ::CxImage::Convert "$original" "$destination" } res ] } {
				status_log "Picture.tcl: Unable to convert picture with TkCximage \n$res" red
				return 0
			} else {
				return $destination
			}
		} 
	}
	
	#Resize a picture from a photo
	#Strict resize, no ratio here
	proc Resize {photo width height} {
		if {[::picture::Loaded]} {
			if { [catch {::CxImage::Resize $photo $width $height } res] != 0 } {
				status_log "Picture.tcl: Unable to resize photo with TkCximage \n$res" red
				return 0
			}	else {
				return $photo
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
			return 0
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
				return 0
			} else {
				return $destination
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
					return 0
				}	else {
					return $photo
				}
			} else {
				
				if { [catch {::CxImage::Thumbnail $photo $width $height $bordercolor -alpha $alpha} res ] != 0 } {
					status_log "Picture.tcl: Unable to create thumbnail with TkCximage \n$res" red
					return 0
				} else {
					return $photo
				}
				
			}
		}	
	}
	
	#Crop a picture, from a photo, to a new picture (should be improved)
	proc Crop {photo x1 y1 x2 y2} {

		set temp [image create photo]
		
		if {[::picture::Loaded]} {
			if { [catch {$temp copy $photo -from $x1 $y1 $x2 $y2} res ] != 0 } {
				status_log "Picture.tcl: Unable to crop image with TkCxImage\n$res" red
				return 0
			} else {
				return $temp
			}
		}
	}
	
	#Save a picture to a file, from a photo
	#Format supported: "cxgif" "cxpng" "cxjpg" "cxtga"
	proc Save {photo destination {format ""}} {
		if {[::picture::Loaded]} {
			if {$format != ""} {
				if { [catch {$photo write $destination -format $format} res] != 0} {
					status_log "Picture.tcl: Error Saving to the file with TkCximage : \n$res" red
					return 0
				} else {
				return $destination
				}
			} else {
				if { [catch {$photo write $destination} res] != 0} {
					status_log "Picture.tcl: Error Saving to the file with TkCximage : \n$res" red
					return 0
				} else {
					return $destination
				}
			}
		}
	}	
	
	#I don't remember why I coded that :S
	proc GetSkinFile {directory file {format "gif"}} {
		#Verify if the picture exists
		if { ![file exists $file] } {
			status_log "Picture.tcl: Tring to GetSkinFile for $file that does not exist\n" red
			return 0
		}
		if {[::picture::Loaded]} {
			#With TkCximage
			set photo [image create photo -file [::skin::GetSkinFile "$directory" "[filenoext [file tail $file]].$format"]]
			return $photo
		} 
	}
}