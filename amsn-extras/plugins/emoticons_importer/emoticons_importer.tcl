###################################################################
#               aMSN Emoticon Importer Plugin                     #
#                    By Youness Alaoui                            #
#                        KaKaRoTo                                 #
#                                                                 #
###################################################################

namespace eval ::emoticons_importer {
	variable config
	variable configlist

	#######################################################################################
	#######################################################################################
	####            Initialization Procedure (Called by the Plugins System)            ####
	#######################################################################################
	#######################################################################################

	proc Init { dir } {
		variable config
		variable configlist

		::plugins::RegisterPlugin emoticons_importer

		array set config {}

		#Load lang files
		set langdir [file join $dir "lang"]
		set lang [::config::getGlobalKey language]
		load_lang en $langdir
		load_lang $lang $langdir

		set configlist [list [list frame ::emoticons_importer::populateframe ""] ]
	}
	proc populateframe { win } {
		set ::emoticons_importer::importdir ""
		# Show some kind of UI for choosing a directory and importing from it.
		frame $win.1
		frame $win.2
		pack $win.1 $win.2 -anchor w -side top -padx 0 -pady 5 -fill none
		label $win.1.path -text "[trans importdir] :" -padx 5 -font sboldf
		entry $win.1.importdir -width 45  -textvariable ::emoticons_importer::importdir
		button $win.1.browse -text [trans browse] -command "Browse_Dialog_dir ::emoticons_importer::importdir"

		grid $win.1.path -row 1 -column 1 -sticky w
		grid $win.1.importdir -row 1 -column 2 -sticky w
		grid $win.1.browse -row 1 -column 3 -sticky w

		button $win.2.import -text [trans import] -command "::emoticons_importer::importSmileys"
		pack $win.2.import -anchor w -side top -padx 0 -pady 5 -fill none
	}


	proc importSmileys { } {
		if {[info exists ::emoticons_importer::importdir] } {
			importSmileysFromDir $::emoticons_importer::importdir
		}
	}

	# Return value
	# 0 : success
	# -1 : directory not found or file not a directory
	proc importSmileysFromDir { directory } {
		if { ![file exists $directory]  || ![file isdirectory $directory] } {
			return -1
		}

		# Check for a kopete compatible emoticon pack
		if {[file exists [file join $directory emoticons.xml]]  &&
		    [file readable [file join $directory emoticons.xml]]} {
			if {[catch {
				set xml_fd [open [file join $directory emoticons.xml]]
				set xml [xml2list [read $xml_fd]]
				close $xml_fd

				plugins_log emoticons_importer "Found an emoticons.xml file in $directory"
				set i 0
				while { 1 } {
					set node [GetXmlNode $xml "messaging-emoticon-map:emoticon" $i]
					if {$node == "" } {
						break
					}
					incr i

					set file [GetXmlAttribute $node "emoticon" "file"]
					set triggers [list]
					set j 0
					while { 1 } {
						set string [GetXmlEntry $node "emoticon:string" $j]
						if {$string == "" } {
							break
						}
						incr j
						append triggers "$string "
					}

					set name [file rootname $file]
					set r [AddNewCustomEmoticon $name [file join $directory $file] $triggers]
					plugins_log emoticons_importer "Added custom emoticon : $name $file '$triggers' : $r"
				}
			} res ] } {
				plugins_log emoticons_importer "Error importing from emoticons.xml : $res"
			} else {
				return 0
			}
		}
		plugins_log emoticons_importer "Globing for files in $directory"
		set files [glob -nocomplain -tails -type f -directory $directory *]
		foreach file $files {
			set name [file rootname $file]
			set triggers "\[$name\]"
			set r [AddNewCustomEmoticon $name [file join $directory $file] $triggers]
			plugins_log emoticons_importer "Added custom emoticon : $name $file '$triggers' : $r"
		}
		return 0
	}

	# Return value :
	# 0 : success
	# -1 : invalid field
	# -2 : smiley already exists with that name
	# -3 : could not find sound file
	# -4 : could not find the smiley file
	# -5 : file could not be loaded, wrong format or whatever
	# -6 : Error converting/resizing the file
	proc AddNewCustomEmoticon { name file text {casesensitive 0} {sound ""}} {
		global custom_emotions HOME
		
		#Check for needed fields
		if { $name == "" || $file == "" || $text == "" } {
			return -1
		}
		if { [info exists custom_emotions($name)] } {
			#Smiley exists
			return -2
		}

		#Check for sound, and copy it
		if { $sound != "" } {
			set filename [getfilename [::skin::GetSkinFile sounds $sound]]
			if { $filename == "null" } {
				return -3
			} else {
				create_dir [file join $HOME sounds]
				catch { file copy [::skin::GetSkinFile sounds $sound] [file join $HOME sounds]}
			}
			set emotion(sound) $filename
		}
		
		set filename [getfilename [::skin::GetSkinFile smileys $file]]
		if { $filename == "null" } {
			return -4
		} 
		
		create_dir [file join $HOME smileys]
		
		#Check for animation
		if { [ catch {set emotion(animated) [::picture::IsAnimated [::skin::GetSkinFile smileys $file] ] } res ] } {
			#There is an error with the file, wront format or doesn't exist
			return -5
		}
		if { $emotion(animated) == 0 } { unset emotion(animated) }
		
		if { ![info exists emotion(animated)] || $emotion(animated) == 0 } {
			image create photo tmp -file [::skin::GetSkinFile smileys $file]
			
			set filetail_noext [filenoext [file tail $file]]
			set destfile [file join $HOME smileys $filetail_noext]
			
			if { [image width tmp] > 50 || [image height tmp] > 50 } {
				#MSN can't show static smileys which are bigger than 50x50 so we resize it
				set file [convert_image_plus [::skin::GetSkinFile smileys $file] smileys 50x50]
			} else {
				#The smiley has size between 19x19 and 50x50 and user doesn't want to resize it so we just convert it to PNG
				set filetail_noext [filenoext [file tail $file]]
				set destfile [file join $HOME smileys $filetail_noext]
				::picture::Convert [::skin::GetSkinFile smileys $file] "${destfile}.png"
				set file "${destfile}.png"
			}

		    	# Don't forget to delete the temp image...!
		    	image delete tmp

			if { ![file exists $file] } { set file "" }
		} else {
			#We convert animated smiley to animated gif even if we can just load animated gif and save to animated gif
			#Don't care of extension : as the smiley is animated TkCximage will save to GIF format
			set filetail_noext [filenoext [file tail $file]]
			set destfile [file join $HOME smileys $filetail_noext]
			::picture::Convert [::skin::GetSkinFile smileys $file] "${destfile}.png"
			set file "${destfile}.png"
			if { ![file exists $file] } { set file "" }
		}
		
		if { $file == "" } {
			return -6
		}
		
		set emotion(file) $file
		set emotion(name) $name
		set emotion(reachable) 1
		
		#Create a list of symbols
		set emotion(text) [list]
		foreach symbol [split $text] {
			if { $symbol != "" } {
				lappend emotion(text) $symbol
			}
		}
		
		if { $casesensitive == 1} {
			set emotion(casesensitive) 1
		} else {
			if { [info exist emotion(casesensitive)] } {unset emotion(casesensitive)}
		} 
		
		
		
		set emotion(image_name) [image create photo emoticonCustom_std_$emotion(text) -file $emotion(file) -format cximage]
		set emotion(preview) [image create photo emoticonCustom_preview_$emotion(text)]
		$emotion(preview) copy emoticonCustom_std_$emotion(text)

		set custom_emotions($name) [array get emotion]

		#load_smileys
		if { [winfo exists .smile_selector]} {destroy .smile_selector}

		#After modifying, clear sortedemotions, could need sorting again
		if {[info exists ::smiley::sortedemotions]} { unset ::smiley::sortedemotions }
		
				
		#Immediately save settings.xml and update the UI
		save_config
		update

		return 0
	}

}
