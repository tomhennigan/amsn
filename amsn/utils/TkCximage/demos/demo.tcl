#!/usr/bin/wish

set dir [file dirname [info script]]
lappend auto_path "./"
lappend auto_path "../"
catch {package require TkCximage}


proc CheckLoaded { } {

	foreach lib [info loaded] {
		if { [lindex $lib 1] == "Tkcximage" } {
			return 1
		} 
	}
	return 0
}
proc chooseFileDialog { {title ""} {operation "open"} } {

	set initialfile ""
	set starting_dir $::start
	set parent "."
	set types {{ "Image file" {*.jpg *.gif *.png *.tga} } {"All Files" {*}}}
	
	if { $operation == "open" } {
		set selfile [tk_getOpenFile -filetypes $types -parent $parent -initialdir $starting_dir -initialfile $initialfile -title $title]
	} else {
		set selfile [tk_getSaveFile -filetypes $types -parent $parent -initialdir $starting_dir -initialfile $initialfile -title $title]
	}

	if { $selfile != "" } {
		set ::start [file dirname $selfile]
	}

	return $selfile
}

proc msg_box { msg } {
	toplevel .error 
	label .error.l -text "$msg"
	button .error.ok -text "Ok" -command "grab release .error; destroy .error"
	pack .error.l .error.ok -side top
	grab set .error
}

proc Load { } {
	set file [chooseFileDialog "Open Image" "open"]
	if { $file == "" }  { return } 

	if { [catch {image create photo -file $file} file] != 0} {
		msg_box "Error opening the file you selected : \n$file"
		return
	}

	catch {
		if { $::loaded != 0 } {
			image delete $::loaded
		}
		destroy .image
		
	}

	set ::loaded $file
	toplevel .image 
	label .image.img -image $::loaded
	pack .image.img


}

proc Save { } {

	if { $::loaded == 0 } {
		msg_box "You must first load an image before using this function"
		return
	}

	toplevel .format 
	radiobutton .format.gif -text "GIF File" -variable ::format -value "cxgif"
	radiobutton .format.png -text "PNG File" -variable ::format -value "cxpng"
	radiobutton .format.jpg -text "JPG File" -variable ::format -value "cxjpg"
	radiobutton .format.tga -text "TGA File" -variable ::format -value "cxtga"
	radiobutton .format.default -text "Choose from file extension" -variable ::format -value "cximage"	
	label .format.separator -text " "
	button .format.ok -text "Save" -command "grab release .format; destroy .format; Save2"
	pack .format.gif .format.png .format.jpg .format.tga .format.default .format.separator .format.ok -side top
	grab set .format
}

proc Save2 { } {

	set file [chooseFileDialog "Save Image" "save"]
	if { $file == "" }  { return } 

	if { [catch {$::loaded write $file -format $::format} file] != 0} {
		msg_box "Error Saving to the file you requested : \n$file"
		return
	}

}

proc Convert { } {

	msg_box "Please load the image to convert"

	tkwait window .error

	set file1 [chooseFileDialog "Open Image" "open"]
	if { $file1 == "" }  { return } 

	msg_box "Please Choose the destination file (filetype is determined by file extension)"

	tkwait window .error

	set file2 [chooseFileDialog "Save Image" "save"]
	if { $file2 == "" }  { return } 

	if { [catch {::CxImage::Convert $file1 $file2} res] != 0} {
		msg_box "Error opening the file you selected : \n$res"
		return
	}

}

proc Resize { } {
	if { $::loaded == 0 } {
		msg_box "You must first load an image before using this function"
		return
	}

	toplevel .resize
	frame .resize.f1
	label .resize.f1.lw -text "Width : "
	entry .resize.f1.w 
	frame .resize.f2
	label .resize.f2.lh -text "Height : "
	entry .resize.f2.h
	frame .resize.f3
	button .resize.f3.ok -text "Resize" -command "Resize2"
	button .resize.f3.cancel -text "Cancel" -command "grab release .resize; destroy .resize"

	pack .resize.f1.lw .resize.f1.w -side left
	pack .resize.f2.lh .resize.f2.h -side left
	pack .resize.f3.ok .resize.f3.cancel -side left
	pack .resize.f1 .resize.f2 .resize.f3 -side top
	grab set .resize
}

proc Resize2 { } {
	set w [.resize.f1.w get]
	set h [.resize.f2.h get]
	grab release .resize
	destroy .resize

	::CxImage::Resize $::loaded $w $h

}


proc Thumbnail { } {
	if { $::loaded == 0 } {
		msg_box "You must first load an image before using this function"
		return
	}
	toplevel .thumb
	frame .thumb.f1
	label .thumb.f1.lw -text "Width : "
	entry .thumb.f1.w 
	frame .thumb.f2
	label .thumb.f2.lh -text "Height : "
	entry .thumb.f2.h
	
	frame .thumb.f3
	label .thumb.f3.lc -text "Border Color : "
	entry .thumb.f3.c 
	checkbutton .thumb.alpha -text "Enable Alpha on border" -variable ::alpha -onvalue 1 -offvalue 0
	frame .thumb.f4
	label .thumb.f4.la -text "Alpha opacity for border (between 0 and 255)"
	entry .thumb.f4.a

	frame .thumb.f5
	button .thumb.f5.ok -text "Resize" -command "Thumbnail2"
	button .thumb.f5.cancel -text "Cancel" -command "grab release .thumb; destroy .thumb"

	pack .thumb.f1.lw .thumb.f1.w -side left
	pack .thumb.f2.lh .thumb.f2.h -side left
	pack .thumb.f3.lc .thumb.f3.c -side left
	pack .thumb.f4.la .thumb.f4.a -side left
	pack .thumb.f5.ok .thumb.f5.cancel -side left

	pack .thumb.f1 .thumb.f2 .thumb.f3 .thumb.alpha .thumb.f4 .thumb.f5 -side top
	grab set .thumb

}

proc Thumbnail2 { } {
	set w [.thumb.f1.w get]
	set h [.thumb.f2.h get]
	set border [.thumb.f3.c get]
	set alpha [.thumb.f4.a get]
	grab release .thumb
	destroy .thumb

	if { $::alpha == 0 } {
		if { [catch {::CxImage::Thumbnail $::loaded $w $h $border} res] != 0 } {
			msg_box "Unable to create thumbnail\n$res"
		}
	} else {
		if { [catch {::CxImage::Thumbnail $::loaded $w $h $border -alpha $alpha} res ] != 0 } {
			msg_box "Unable to create thumbnail\n$res"
		}
	}
}

proc Crop { } {
	if { $::loaded == 0 } {
		msg_box "You must first load an image before using this function"
		return
	}
	toplevel .cr
	frame .cr.f1
	label .cr.f1.lx -text "Starting X : "
	entry .cr.f1.x1 
	frame .cr.f2
	label .cr.f2.ly -text "Starting Y : "
	entry .cr.f2.y1
	frame .cr.f3
	label .cr.f3.lx -text "Ending X : "
	entry .cr.f3.x2
	frame .cr.f4
	label .cr.f4.ly -text "Ending Y : "
	entry .cr.f4.y2

	frame .cr.f5
	button .cr.f5.ok -text "Crop" -command "Crop2"
	button .cr.f5.cancel -text "Cancel" -command "grab release .cr; destroy .cr"

	pack .cr.f1.lx .cr.f1.x1 -side left
	pack .cr.f2.ly .cr.f2.y1 -side left
	pack .cr.f3.lx .cr.f3.x2 -side left
	pack .cr.f4.ly .cr.f4.y2 -side left
	pack .cr.f5.ok .cr.f5.cancel -side left

	pack .cr.f1 .cr.f2 .cr.f3 .cr.f4 .cr.f5 -side top
	grab set .cr
}

proc Crop2 { } {
	set x1 [.cr.f1.x1 get]
	set y1 [.cr.f2.y1 get]
	set x2 [.cr.f3.x2 get]
	set y2 [.cr.f4.y2 get]

	grab release .cr
	destroy .cr

	set temp [image create photo]

	if { [catch {$temp copy $::loaded -from $x1 $y1 $x2 $y2} res ] != 0 } {
		msg_box "Unable to crop image\n$res"
		return
	}

	catch {
		if { $::loaded != 0 } {
			image delete $::loaded
		}
		destroy .image
		
	}

	set ::loaded $temp
	toplevel .image 
	label .image.img -image $::loaded
	pack .image.img
	
}

proc Blending { } {

	catch {destroy .alpha}

	msg_box "Please load an image that has Alpha blending enabled"

	tkwait window .error

	set file [chooseFileDialog "Open Image" "open"]
	if { $file == "" }  { return } 

	if { [catch {image create photo -file $file} img1] != 0} {
		msg_box "Error opening the file you selected : \n$img1"
		return
	}

	msg_box "Please load the background image"

	tkwait window .error

	set file2 [chooseFileDialog "Open Image" "open"]
	if { $file2 == "" }  { return } 

	if { [catch {image create photo -file $file2} img2] != 0} {
		msg_box "Error opening the file you selected : \n$img2"
		return
	}

	set w1 [image width $img1]
	set h1 [image height $img1]
	set w2 [image width $img2]
	set h2 [image height $img2]

	toplevel .alpha
	canvas .alpha.c -width [expr $w1 > $w2 ? $w1 : $w2] -height [expr $h1 > $h2 ? $h1 : $h2]
	.alpha.c create image [expr $w2 / 2] [expr $h2 / 2] -image $img2
	.alpha.c create image [expr $w1 / 2] [expr $h1 / 2] -image $img1
	pack .alpha.c
	
#	bind .alpha <Destroy> "image delete $img1; image delete $img2"

}
 


if { [CheckLoaded] == 0 } {
	catch {load ../TkCximage[info shared]}
	catch {load ./TkCximage[info shared]}
	if {[CheckLoaded] == 0 } {
		puts "Can't find the extension, please type \"make\" to compile it before testing it"
		exit
	}
}


cd $dir
set loaded 0
set ::start [pwd]
set ::format "cximage"
set ::alpha 0

wm title . "Commands"
button .load -text "Load" -command "Load"
button .save -text "Save" -command "Save"
button .convert -text "Convert" -command "Convert"
button .res -text "Resize" -command "Resize"
button .thumbnail -text "Thumbnail" -command "Thumbnail"
button .crop -text "Crop" -command "Crop"
button .blending -text "Test Alpha blending" -command "Blending"
button .exit -text "Exit" -command "exit"

pack .load .save .convert .res .thumbnail .crop .blending .exit -side top


