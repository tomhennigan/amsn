# Now relies on guicontactlist's truncateText proc

::Version::setSubversionId {$Id$}

namespace eval ::MSNSPACES {
	variable storageAuthCache ""

	proc hasSpace { email } {
		return [::abook::getContactData $email space_access 0]
	}

	proc getContactCardCallback {callback email soap } {
		if { [$soap GetStatus ] == "success" } {
			set xml [$soap GetResponse]
			$soap destroy
			
			::abook::setContactData $email spaces_info_xml $xml

			#now we'll set the space as "read"
			::abook::setVolatileData $email space_updated 0
			::Event::fireEvent contactSpaceChange protocol $email

			if {[catch {eval $callback [list $xml]} result]} {
				bgerror $result
			}
		}  else {
			status_log "ERROR getting CCARD of $email - [$soap GetStatus ]: [$soap GetLastError]"
			$soap destroy
			if {[catch {eval $callback [list [list]]} result]} {
				bgerror $result
			}
		}
	}
	proc getContactCard { callback email } {
		$::sso RequireSecurityToken Spaces [list ::MSNSPACES::getContactCardSSOCB $callback $email]
	}

	proc getContactCardSSOCB { callback email ticket } {
		status_log "fetching ContactCard for user $email"

		if {[::MSNSPACES::hasSpace $email] } {
			set soap_req [SOAPRequest create %AUTO% \
					  -url "http://cc.services.spaces.live.com/contactcard/contactcardservice.asmx" \
					  -action "http://www.msn.com/webservices/spaces/v1/GetXmlFeed" \
					  -xml [::MSNSPACES::getContactCardXml $email $ticket] \
					  -callback [list ::MSNSPACES::getContactCardCallback $callback $email]]
			$soap_req SendSOAPRequest
			return
		}
		
		status_log "Error fetching ContactCard for user $email" red
		# This gets executed if the SOAP request is not sent.. serves as error handler
		if {[catch {eval $callback [list [list]]} result]} {
			bgerror $result
		}
	}

	proc getContactCardXml { email ticket } {
		variable storageAuthCache

		set cid [::abook::getContactData $email cid]

		set xml {<?xml version="1.0" encoding="utf-8"?>}
		append xml {<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">}
		append xml {<soap:Header>}
		append xml {<AuthTokenHeader xmlns="http://www.msn.com/webservices/spaces/v1/">}
		append xml {<Token>}
		append xml [xmlencode $ticket]
		append xml {</Token>}
		append xml {</AuthTokenHeader>}
		append xml {</soap:Header>}
		append xml {<soap:Body>}
		append xml {<GetXmlFeed xmlns="http://www.msn.com/webservices/spaces/v1/">}
		append xml {<refreshInformation>}
		append xml {<cid xmlns="http://www.msn.com/webservices/spaces/v1/">}
		append xml $cid
		append xml {</cid>}
		append xml {<storageAuthCache>}
		append xml $storageAuthCache
		append xml {</storageAuthCache>}
		append xml {<market xmlns="http://www.msn.com/webservices/spaces/v1/">en-US</market>}
		append xml {<brand />}
		append xml {<maxElementCount xmlns="http://www.msn.com/webservices/spaces/v1/">6</maxElementCount>}
		append xml {<maxCharacterCount xmlns="http://www.msn.com/webservices/spaces/v1/">200</maxCharacterCount>}
		append xml {<maxImageCount xmlns="http://www.msn.com/webservices/spaces/v1/">6</maxImageCount>}
		append xml {</refreshInformation>}
		append xml {</GetXmlFeed>}
		append xml {</soap:Body>}
		append xml {</soap:Envelope>}

		return $xml
	}


	proc getIndexFor { ccard type } {
		# Type can be : SpaceTitle Blog Album Music
		set node_path "soap:Envelope:soap:Body:GetXmlFeedResponse:GetXmlFeedResult:contactCard:elements:element"
		set i 0
		set node [GetXmlNode $ccard $node_path $i]
		while { $node != "" } {
			set node [GetXmlNode $ccard $node_path $i]
			set cur_type [GetXmlAttribute $node ":element" type]
			if { $cur_type == $type } { return $i }
			incr i
		}
		# Hit the bottom, return nothing
		return -1
	}

	proc getUrlFor { ccard type } {
		if { $ccard != "" } {
			set index [getIndexFor $ccard $type]
			if { $index >= 0 } {
				return [GetXmlEntry $ccard "soap:Envelope:soap:Body:GetXmlFeedResponse:GetXmlFeedResult:contactCard:elements:element:url" $index]
			}
		} 
		# Hit the bottom, return nothing
		return ""
	}

	proc getTitleFor { ccard type } {
                if { $ccard != "" } {
                        set index [getIndexFor $ccard $type]
                        if { $index >= 0 } {
                                return [GetXmlEntry $ccard "soap:Envelope:soap:Body:GetXmlFeedResponse:GetXmlFeedResult:contactCard:elements:element:title" $index]
                        }
                }
                # Hit the bottom, return nothing
                return ""
	}

	proc getUnreadFor { ccard type } {
                if { $ccard != "" } {
                        set index [getIndexFor $ccard $type]
                        if { $index >= 0 } {
                                return [GetXmlEntry $ccard "soap:Envelope:soap:Body:GetXmlFeedResponse:GetXmlFeedResult:contactCard:elements:element:totalNewItems" $index]
                        }
                }
                # Hit the bottom, return nothing
                return ""
	}

	proc getAllPhotos { ccard } {
		# Should return a list :
		# { {description title url thumbnailUrl webReadyUrl albumName}
		#   {description title url thumbnailUrl webReadyUrl albumName}
		#   ... ... }
                set index [getIndexFor $ccard Album]
                set photos {}
                if { $index >= 0 } {
                        set path1 "soap:Envelope:soap:Body:GetXmlFeedResponse:GetXmlFeedResult:contactCard:elements:element"
                        set bignode [GetXmlNode $ccard $path1 $index]
                        set i 0
                        set node [GetXmlNode $bignode ":element:subElement" $i]
                        while { $node != "" } {
                                set desc [GetXmlEntry $node ":subElement:description" ]
                                set title [GetXmlEntry $node ":subElement:title" ]
                                set url [GetXmlEntry $node ":subElement:url"]
				set thumbnailUrl [GetXmlEntry $node ":subElement:thumbnailUrl" ]
				set webReadyUrl [GetXmlEntry $node ":subElement:webReadyUrl" ]
				set albumName [GetXmlEntry $node ":subElement:albumName" ]
                                lappend photos [list $desc $title $url $thumbnailUrl $webReadyUrl $albumName]
                                incr i
                                set node [GetXmlNode $bignode ":element:subElement" $i]
                        }
			return $photos
                }
	}
	proc  getAlbumImage {callback url } {
		$::sso RequireSecurityToken Spaces [list ::MSNSPACES::getAlbumImageSSOCB $callback $url]
	}

	proc getAlbumImageSSOCB {  callback url ticket } {
		set cookies [split $ticket &]
		foreach cookie $cookies {
			set c [split $cookie =]
			set ticket_[lindex $c 0] [lindex $c 1]
		}

		if { [catch { http::geturl $url -headers [list "Cookie" "RPSTAuth=${ticket_t}"]  -command [list ::MSNSPACES::getAlbumImageHTTPCB $callback]}] } {
			if {[catch {eval $callback [list ""]} result]} {
				bgerror $result
			}			
		}

		
	}
	proc getAlbumImageHTTPCB {  callback token } {
		set data ""

		if { [::http::status $token] == "ok" && 
		     [::http::ncode $token] >= 200 && [::http::ncode $token] < 300
		     || [::http::ncode $token] == 500} {
			set data [::http::data $token]
		} elseif { [::http::status $token] == "ok" } {
			upvar #0 $token state
			set meta $state(meta)

			array set meta_array $meta 
			if {[info exists meta_array(Location)]} {
				set url $meta_array(Location)
				::http::cleanup $token

				getAlbumImage $callback $url
				return
			} 
		} 
		::http::cleanup $token

		if {[catch {eval $callback [list $data]} result]} {
			bgerror $result
		}

	}


	proc getAllBlogPosts { ccard } {
		# Should return a list :
		# { { description title url} {description title url} ... }
		set index [getIndexFor $ccard Blog]
		set posts {}
		if { $index >= 0 } {
			set path1 "soap:Envelope:soap:Body:GetXmlFeedResponse:GetXmlFeedResult:contactCard:elements:element"
			set bignode [GetXmlNode $ccard $path1 $index]
			set i 0
			set node [GetXmlNode $bignode ":element:subElement" $i]
			while { $node != "" } {
				set desc [GetXmlEntry $node ":subElement:description"]
				set title [GetXmlEntry $node ":subElement:title"]
				set url [GetXmlEntry $node ":subElement:url"]
				lappend posts [list $desc $title $url]
				incr i
				set node [GetXmlNode $bignode ":element:subElement" $i]
			}
		}
		return $posts
	}

	proc getLiveThemeColor { data } {
		if { $data != ""} {
			set data [join [list "#" $data] ""]
		}
		return $data
	}

	proc getLiveThemeData { ccard } {
		# Should return an array with the theme colors and images
		set path "soap:Envelope:soap:Body:GetXmlFeedResponse:GetXmlFeedResult:contactCard:liveTheme"
		set node [GetXmlNode $ccard $path]
		if {$node != ""} {
			set node [GetXmlNode $ccard [join [list $path ":head"] ""]]
			set theme(head_fg) [::MSNSPACES::getLiveThemeColor [GetXmlAttribute $node ":head" textColor]]
			set theme(head_link) [::MSNSPACES::getLiveThemeColor [GetXmlAttribute $node ":head" linkColor]]
			set theme(head_bg) [::MSNSPACES::getLiveThemeColor [GetXmlAttribute $node ":head" backgroundColor]]
			set theme(head_bgimage) [GetXmlAttribute $node ":head" backgroundImage]
			set node [GetXmlNode $ccard [join [list $path ":body"] ""]]
			set theme(body_fg) [::MSNSPACES::getLiveThemeColor [GetXmlAttribute $node ":body" textColor]]
			set theme(body_link) [::MSNSPACES::getLiveThemeColor [GetXmlAttribute $node ":body" linkColor]]
			set theme(body_bg) [::MSNSPACES::getLiveThemeColor [GetXmlAttribute $node ":body" backgroundColor]]
			set theme(body_bgimage) [GetXmlAttribute $node ":body" backgroundImage]
			set theme(outline) [::MSNSPACES::getLiveThemeColor [GetXmlAttribute $node ":body" dividerColor]]
			set theme(hover) [::MSNSPACES::getLiveThemeColor [GetXmlAttribute $node ":body" accordionHoverColor]]
			return [array get theme]
		} else {
			return ""
		}
	}
	
	proc fetchSpace {email} {
		#if an update is available, we'll have to fetch it
		if {[::abook::getContactData $email spaces_info_xml [list]] == [list] } {
			::abook::setVolatileData $email fetching_space 1
			# fetch the ccard info and check if the user 
			::MSNSPACES::getContactCard [list ::MSNSPACES::fetchedSpace $email] $email 
		}
	}
	
	proc fetchedSpace { email xml} {
		global HOME
		variable token

		if { $xml != [list] } {
			set photos [::MSNSPACES::getAllPhotos $xml]
			set cachedir "[file join $HOME spaces $email]"
			create_dir $cachedir
			set count 0

			# TODO : use an http "Last-Modified" header and check if the server returns an "30X Not Modified" then use the cached file...
		# 	foreach photolist $photos {
# 				#download the thumbnail
# 				set thumbnailurl [lindex $photolist 3]
# 				set data [getAlbumImage $thumbnailurl]
# 				set filename "[file join $cachedir $count.jpg]"
# 				set fid [open $filename w]
# 				fconfigure $fid -translation binary
# 				puts -nonewline $fid "$data"
# 				close $fid
				
# 				incr count
# 			}		
		
		}

		::abook::setVolatileData $email fetching_space 0
		
		set display [::config::getKey spacesinfo "inline"]
		if { $display == "inline" } {
			::Event::fireEvent contactSpaceFetched protocol $email
		} elseif { $display == "ccard" } {
			::ccard::drawwindow $email 1
		} elseif { $display == "both" } {
			if {[::abook::getVolatileData $email SpaceShowed 0]} {
				::Event::fireEvent contactSpaceFetched protocol $email
			} elseif { [winfo exists .ccardwin] } {
				::ccard::drawwindow $email 1
			}
		}
	}

}



############################
# ::ccard                  #
#  All ccard related code  #
############################
namespace eval ::ccard {


	variable dset 0
	variable bgcolor #ebf1fa

	#This if is to have backwards-compatibility with aMSN 0.94.  Thanks to Arieh for pointing this out.
	#Code removed... the 0.97 version should be different
#	::skin::setPixmap ccard_bg ccard_bg.gif
#	::skin::setPixmap ccard_close ccard_close.gif
#	::skin::setPixmap ccard_close_hover ccard_close_hover.gif
#	::skin::setPixmap ccard_left ccard_left.gif
#	::skin::setPixmap ccard_left_hover ccard_left_hover.gif
#	::skin::setPixmap ccard_right ccard_right.gif
#	::skin::setPixmap ccard_right_hover ccard_right_hover.gif
#	::skin::setPixmap ccard_back_line ccard_line.gif
#	::skin::setPixmap ccard_chat ccard_chat.gif
#	::skin::setPixmap ccard_chat_hover ccard_chat_hover.gif
#	::skin::setPixmap ccard_email ccard_email.gif
#	::skin::setPixmap ccard_email_hover ccard_email_hover.gif
#	::skin::setPixmap ccard_nudge ccard_nudge.gif
#	::skin::setPixmap ccard_nudge_hover ccard_nudge_hover.gif
#	::skin::setPixmap ccard_mobile ccard_mobile.gif
#	::skin::setPixmap ccard_mobile_hover ccard_mobile_hover.gif 
#	::skin::setPixmap ccard_bpborder ccard_bpborder.gif
	::skin::setPixmap ccard_x ccard_x.png
	::skin::setPixmap ccard_x_hl ccard_x_hl.png
	::skin::setPixmap ccard_up ccard_up.png
	::skin::setPixmap ccard_dn ccard_dn.png



	#proc clLoaded { event evpar } {
        #        foreach contact [::abook::getAllContacts] {
        #                set has_space [::MSNSPACES::hasSpace $contact]
        #                if {$has_space == 1 } {
        #                        #lappend users_with_space $contact
#				set ccard [::MSNSPACES::getContactCard $contact]
#				set ccard_list [xml2list $ccard]
#				::abook::setVolatileData $contact ccard $ccard_list
#                        }
#               }
#
#	}



	#################################################
	# drawwindow( email side )                      #
	#  draws the wiccardndow with the specified side#
	#################################################
	proc drawwindow { email side } {
		variable old_email

		#set the name of the window to .ccarcwin_[numeric value of adres]
		set w .ccardwin
		
		set winw 226
		set winh 210

		#destroy the window if it already exists, with an animation
		#==========================================================
		if { [winfo exists $w] } {
			set geo [wm geometry $w]

			#If the window already existed and we redraw it, redraw it at the same position
			wm geometry $w $geo
			focus $w
			set canvas $w.card
			$canvas delete $old_email
			
		} else {
			#Define the window
			#=================
			set nocolor white
			toplevel $w -background $nocolor -borderwidth 0
			
			if {[OnMac]} {
				tk::unsupported::MacWindowStyle style $w floating {noTitleBar}
			}
			
			#if we draw the window for the first time, draw it at an intelligent position, with the right size (226x212)
			set mouse_x [winfo pointerx $w]
			set mouse_y [winfo pointery $w]
			set xpos [expr $mouse_x - [expr $winw/2]]
			set ypos [expr $mouse_y - [expr $winh/2]]
			#if the window gets out of the screen, move it inside the screen, $border away from the edge
			set border 10
			if {[expr $xpos + $winw] > [winfo vrootwidth $w]} {
				set xpos [expr [winfo vrootwidth $w] - $winw -$border]
			}
			if {[expr $ypos + $winh] > [winfo vrootheight $w]} {
				set ypos [expr [winfo vrootheight $w] - $winh -$border]
			}
			#migrate from oldstyle ccardgeometry to ccardpos.
			if {[::config::isSet ccardgeometry]} {
				if {[regexp {([\+|-]+)(\d+)([\+|-]+)(\d+)} [::config::getKey ccardgeometry] geo_match]} {
					::config::setKey ccardpos $geo_match
				}
				::config::unsetKey ccardgeometry
			}
			if {[::config::getKey rememberccardposition 1] && [::config::isSet ccardpos]} {
				wm geometry $w [::config::getKey ccardpos]
			} else {
				# Default geomtry is relative to the mouse position.
				wm geometry $w ${winw}x${winh}+$xpos+$ypos
			}
			
			#close the window when ESC is pressed, set focus so it can be closed with ESC
			bind $w <<Escape>> [list ::ccard::closewindow $w]
			focus $w
			
			#the overrideredirect makes it have no border and not draggable etc (no wm stuff)
			wm overrideredirect $w 1
			
			#Define the content of the window
			#================================
			#create the canvas where we will draw our stuff on
			set canvas $w.card
			canvas $canvas -width $winw -height $winh -bg $nocolor -highlightthickness 0 -relief flat -borderwidth 0
			
			#make it draggable
			bind $canvas <ButtonPress-1> [list ::ccard::buttondown $w]
			bind $canvas <B1-Motion> [list ::ccard::drag $w]
			bind $canvas <ButtonRelease-1> [list ::ccard::release $w]
		}

		set old_email $email

		#The body
		#--------
		drawCCard $canvas 0 0 $winw $winh $email
		$canvas bind close_btn <Button-1> [list ::ccard::closewindow $w]
		bind $canvas <Destroy> +[list ::ccard::delete_ccard_images]

		#pack the canvas into the window
		pack $canvas -side top -fill x
		
		#make it draggable
		bind $canvas <ButtonPress-1> [list ::ccard::buttondown $w]
		bind $canvas <B1-Motion> [list ::ccard::drag $w]
		bind $canvas <ButtonRelease-1> [list ::ccard::release $w]
	}

	#################################################
	# closewindow( window )                         #
	#  closes the wiccardndow						#
	#################################################
	proc closewindow { {window ".ccardwin"} } {
		if {[winfo exists $window]} {
			::config::setKey ccardpos "+[winfo x ${window}]+[winfo y ${window}]"
			kill_balloon
			destroy $window
		}
		return
	}

	########################################################
	# Procs used by drawwindow                             #
	#   CreateButtons, CreateTopButton, CreateBottomButton #   		
	########################################################

	#create a button in the contactcard
	proc CreateButton {canvas tagname image hover_image xcoord command tooltip place email} {
		variable xbegin
		if {$place == "top"} {
			set xbegin [expr $xcoord - [image width $image]]
			set ycoord 0
		} else {
			set xbegin [expr $xcoord + [image width $image]]
			set ycoord [expr {200 - [image height $image]}]
		}
		$canvas create image $xcoord $ycoord  -anchor nw -image $image -activeimage $hover_image -tag [list $tagname $email]
		$canvas bind $tagname <ButtonPress-1> $command
		tooltip $canvas $tagname "$tooltip"

	}

	#create the buttons on top of the window
	proc CreateTopButtons {w canvas email side} {
		#Set the coordinate on the right where the buttons should be drawn from (to the left)
		variable xbegin 270

		CreateButton $canvas closebutton [::skin::loadPixmap ccard_close] \
			[::skin::loadPixmap ccard_close_hover] $xbegin \
			"::ccard::closewindow $w" "[trans close]" top $email

		CreateButton $canvas rightbutton [::skin::loadPixmap ccard_right] \
			[::skin::loadPixmap ccard_right_hover] $xbegin \
			"::ccard::changeside $email $side" "Turn the card" top $email

		CreateButton $canvas leftbutton [::skin::loadPixmap ccard_left] \
			[::skin::loadPixmap ccard_left_hover] $xbegin \
			"::ccard::changeside $email $side" "Turn the card" top $email

	}

	#create the buttons on the bottom of the window
	proc CreateBottomButtons {w canvas email side} {
		variable xbegin 10

		#only show the "send message" button if the contact is online
		if { [::abook::getVolatileData $email state FLN] != "FLN" } {
			CreateButton $canvas chatbutton [::skin::loadPixmap ccard_chat] \
				[::skin::loadPixmap ccard_chat_hover] $xbegin \
				"::amsn::chatUser ${email}" "[trans sendmsg]" bottom $email
		}

		CreateButton $canvas mailbutton [::skin::loadPixmap ccard_email] \
			[::skin::loadPixmap ccard_email_hover] $xbegin \
			"launch_mailer $email" "[trans sendmail]" bottom $email


		#if the user has a mobile set up, put a button to send mobile msgs
		if { [::abook::getContactData $email MOB] == "Y" } {

			CreateButton $canvas mobilebutton [::skin::loadPixmap ccard_mobile] \
			[::skin::loadPixmap ccard_mobile_hover] $xbegin  \
			"::MSNMobile::OpenMobileWindow ${email}" "[trans sendmobmsg]" bottom $email

		}


		#when a wink plugin is available, put a wink button here

		#nudge button only if plugin is loaded and the contact is online
		if { [::abook::getVolatileData $email state FLN] != "FLN" } {
			set pluginidx [lindex [lsearch -all $::plugins::loadedplugins "*Nudge*"] 0]
			if { $pluginidx != "" } {

				CreateButton $canvas nudgebutton [::skin::loadPixmap ccard_nudge] \
				[::skin::loadPixmap ccard_nudge_hover] $xbegin  \
				"::Nudge::ClSendNudge $email" "$::Nudge::language(send_nudge)" bottom $email

			}
		}

		set dock_img [::skin::loadPixmap spaces_dock]
		set xbegin [expr {290 - [image width $dock_img]}]
		CreateButton $canvas spaces_dock $dock_img $dock_img $xbegin \
		    "[list after 2000 ::ccard::closewindow]; [list ::guiContactList::toggleSpaceShown $email]" "[trans spaces_dock]" bottom $email


	}


	proc delete_ccard_images {} {
		if {[ImageExists ccard_head_bg]} {
			image delete ccard_head_bg
		}
		if {[ImageExists ccard_body_bg]} {
			image delete ccard_body_bg
		}
		set count 0
		while {[ImageExists tempspacethumb$count]} {
			image delete tempspacethumb$count
			incr count
		}
	}

	##################################################
	# drawbody( canvas email side )                  #
	#  defines the data that will be in the body of  #
	#  the contactcard, depending on the emailaddres #
	#  (id) of the contact and the side to display   #
	##################################################
	proc drawbody { canvas email side } {

		if {$side == 1} {
		#==========================
		#This is the front side (1)
		#==========================
			set filename [::abook::getContactData $email displaypicfile ""]
			global HOME
			if { [file readable "[file join $HOME displaypic cache ${filename}].gif"] } {
				catch {image create photo user_pic_$email -file "[file join $HOME displaypic cache ${filename}].gif"}
			} else {
				image create photo user_pic_$email -file [::skin::GetSkinFile displaypic "nopic.gif"]
			}
			set bp_x 8
			set bp_y 26
			$canvas create image $bp_x $bp_y -anchor nw -image [::skin::getDisplayPicture $email] -tags $email
			$canvas create image [expr $bp_x -1 ]  [expr $bp_y -1 ] -anchor nw -image [::skin::loadPixmap ccard_bpborder] -tags [list tt $email]

			set nick [::abook::getNick $email]
			if {[font measure bboldf -displayof $canvas $nick] > 180} {
				set nick [::guiContactList::truncateText $nick 180 bboldf "..."]
			}
			$canvas create text 114 24 -text $nick -font bboldf -justify left -anchor nw -fill black\
					-tags [list $email nickname] 

			set psm [::abook::getpsmmedia $email]
			if {[font measure bitalf -displayof $canvas $psm] > 180} {
				set psm [::guiContactList::truncateText $psm 180 bitalf "..."]
			}
			$canvas create text 114 40 -text $psm -font bitalf -justify left -anchor nw -fill black\
					-tags [list $email psm]

						
			drawSpacesInfo $canvas 114 70 $email [list $email space_info contact]
			tooltip $canvas tt "$email\n[trans status]: [trans [::MSN::stateToDescription [::abook::getVolatileData $email state]]]\n[trans lastmsgedme] : [::abook::dateconvert "[::abook::getContactData $email last_msgedme]"]"

		} else {
		#=========================
		#This is the back side (0)
		#=========================
			set backtextcolor #616060
			set xcoord 12

			$canvas create text $xcoord 30 -text "[trans email]:\t$email" -font bplainf -width 280 -justify left -anchor nw -fill $backtextcolor -tags $email

			$canvas create image 10 66 -anchor nw -image [::skin::loadPixmap ccard_back_line] -tags $email

			$canvas create text $xcoord 80 -text "[trans home]:\t[::abook::getContactData $email phh]" -font bplainf -width 280 -justify left -anchor nw -fill $backtextcolor  -tags $email
			$canvas create text $xcoord 100 -text "[trans work]:\t[::abook::getContactData $email phw]" -font bplainf -width 280 -justify left -anchor nw -fill $backtextcolor -tags $email
			$canvas create text $xcoord 120 -text "[trans mobile]:\t[::abook::getContactData $email phm]" -font bplainf -width 280 -justify left -anchor nw -fill $backtextcolor -tags $email

		}
		#draw the email on each side of the card
		$canvas create text 5 1 -text "$email" -fill white -anchor nw -font splainf -tags $email
	}

	##################################################
	# changeside( email side )                       #
	#  redraws the window with the other side        #
	##################################################
	proc changeside {email side} {
		drawwindow $email [expr {1-$side}]
	}


	#Tooltips on canvas items, looked at guicontactlist.tcl
	proc tooltip {canvas item msg} {
		$canvas bind $item <Enter> [list balloon_enter %W %X %Y $msg]
		$canvas bind $item <Leave> "kill_balloon"
	}


	##################################################
	# Following procedures make the dragging of the  #
	# Contactcard possible.  Credits to the creator  #
	# of the winskin plugin, as the code was allmost #
	# integrally token from it                       #
	##################################################
	proc buttondown {w} {
		#define global vars
		variable dset
		variable dx
		variable dy
		variable width
		variable height
		#store the coords of the mouse
		set mousex [winfo pointerx $w]
		set mousey [winfo pointery $w]
		#set the coords/geometry of the window
		scan [wm geometry $w] "%dx%d%*1\[+-\]%d%*1\[+-\]%d" width height wx wy
		#set 'button is down'
		set dset 1
		#where is the mouse in the window ?
		set dx [expr {$wx-$mousex}]
		set dy [expr {$wy-$mousey}]
		#raise the ccard
		raise $w
	}
	proc release {w} {
		variable dset
		#set 'button is released'
		set dset 0
		#raise the ccard
		raise $w
	}
	proc drag {w} {
		variable dset
		variable dx
		variable dy
		variable width
		variable height
		if { $dset } {
			set x [winfo pointerx $w]
			set y [winfo pointery $w]
			wm geometry $w "${width}x${height}+[expr {$dx + $x}]+[expr {$dy + $y}]"
		}
	}


	proc drawSpacesImageCB { img data} {
		if {$data != "" } {
			catch {
				set temp [image create photo -data $data]
				::picture::ResizeWithRatio $temp [$img cget -width] [$img cget -height]
				$img blank
				$img copy $temp
				image delete $temp
			} res
		}
		
	}
	#///////////////////////////////////////////////////////////////////////////////
	#Draws info of MSN Spaces on chosen coordinate on a choosen canvas
	proc drawSpacesCL { canvas email base_tag marginx marginy } {

		set stylestring [list ]

		if { [::abook::getVolatileData $email fetching_space 0] } {
			#draw a "please wait .." message, will be replaced when fetching is done
			lappend stylestring [list "colour" "grey"]
			lappend stylestring [list "font" "sitalf"]
			#Fetching data ...
			lappend stylestring [list "text" [trans fetching]]

		} else {
			#show the data we have in abook

			set ccard [::abook::getContactData $email spaces_info_xml [list]]

			# Store the titles in a var
			foreach i [list SpaceTitle Blog Album Music] {
				set $i [::MSNSPACES::getTitleFor $ccard $i]
			}

			lappend stylestring [list "trunc" 1 "..."]
				
			#for now show a message if no blogs or photos, for debugging purposes
			if {$Blog == "" && $Album == ""} {
				lappend stylestring [list "colour" "grey"]
				lappend stylestring [list "font" "sitalf"]
				#Nothing to see here
				lappend stylestring [list "text" [trans nospace]]
			} else {
	
				#First show the spaces title:
				if {$SpaceTitle != ""} {
					lappend stylestring [list "colour" "black"]
					lappend stylestring [list "font" "bboldf"]
					lappend stylestring [list "text" $SpaceTitle]
					lappend stylestring [list "margin" [expr {$marginx+10}] $marginy]
				}
	
				#blogposts
				if {$Blog != ""} {
					# seems like a blog without title doesn't exist, so we don't have to check if there are any posts
					set blogposts [::MSNSPACES::getAllBlogPosts $ccard]
					lappend stylestring [list "newline" "\n"]
					#add a title
					lappend stylestring [list "colour" "#78797e"]
					lappend stylestring [list "font" "sboldf"]
					lappend stylestring [list "text" $Blog]
	
					lappend stylestring [list "colour" "black"]
					lappend stylestring [list "font" "sitalf"]
					lappend stylestring [list "tag" "clickable"]
	
					set count 0
					foreach i $blogposts {
						set itemtag ${base_tag}_bpost_${count}
	
						#check if there's a title
						set title [lindex $i 1]
	
						if {$title == ""} {
							set title [trans untitled]
						}
	
						lappend stylestring [list "newline" "\n"]
	
						lappend stylestring [list "space" 10]
						lappend stylestring [list "tag" "$itemtag"]
						lappend stylestring [list "text" $title]
						lappend stylestring [list "tag" "-$itemtag"]
	
						$canvas bind $itemtag <Button-1> [list ::hotmail::gotSHA1URL "[lindex $i 2]" 73625]
	
						incr count
					}
	
					lappend stylestring [list "tag" "-clickable"]
				}
	
				
				#photos
				if {$Album != ""} {
					set photos [::MSNSPACES::getAllPhotos $ccard]
					lappend stylestring [list "newline" "\n"]
					#add a title
					lappend stylestring [list "colour" "#78797e"]
					lappend stylestring [list "font" "sboldf"]
					lappend stylestring [list "text" $Album]
					lappend stylestring [list "newline" "\n"]
					lappend stylestring [list "space" 10]
	
					lappend stylestring [list "tag" "clickable"]
	
					set count 0
					foreach i $photos {
						set itemtag ${base_tag}_bpost_${count}
						if { [lindex $i 0] != "" } {
	
							if {[lindex $i 3] != "" } {
								set img [image create photo tempspacethumb$email$count -width 35 -height 35]
								::MSNSPACES::getAlbumImage [list ::ccard::drawSpacesImageCB $img] [lindex $i 3]
	
								lappend stylestring [list "tag" "$itemtag"]
								lappend stylestring [list "image" $img "w"]
								lappend stylestring [list "tag" "-$itemtag"]
	
								lappend stylestring [list "space" 3]
								
								bind $canvas <Destroy> +[list image delete tempspacethumb$email$count]
							}
							$canvas bind $itemtag <Button-1> \
								[list ::hotmail::gotSHA1URL "[lindex $i 2]" 73625]
	
							incr count
						}
					}
					lappend stylestring [list "tag" "-clickable"]
				}
	
				lappend stylestring [list "margin" $marginx $marginy]
				lappend stylestring [list "trunc" 0]
				lappend stylestring [list "newline" "\n"]
			}
		}

		return $stylestring
	}

	proc getDefaultLiveTheme { } {
		# Should return an array with the default theme colors and images
		#TODO: make skinnable
		set theme(head_fg) "#444444"
		set theme(head_link) "#0066a7"
		set theme(head_bg) "#f5fafc"
		set theme(head_bgimage) ""
		set theme(body_fg) "#444444"
		set theme(body_link) "#0066a7"
		set theme(body_bg) "#ffffff"
		set theme(body_bgimage) ""
		set theme(outline) "#e9eaf1"
		set theme(hover) "#d6effc"
		return [array get theme]
	}

	#///////////////////////////////////////////////////////////////////////////////
	#Gets info of MSN Spaces and puts them into an array
	proc getSpacesInfo { email } {
		set xml_data [::abook::getContactData $email spaces_info_xml [list]]
		foreach i [list SpaceTitle Blog Album Music] {
			set spaces_info($i) [::MSNSPACES::getTitleFor $xml_data $i]
		}
		if {$spaces_info(Blog) != ""} {
			set spaces_info(BlogPosts) [::MSNSPACES::getAllBlogPosts $xml_data]
		}
		if {$spaces_info(Album) != ""} {
			set spaces_info(Photos) [::MSNSPACES::getAllPhotos $xml_data]
		}
		return [array get spaces_info]
	}

	#///////////////////////////////////////////////////////////////////////////////
	#Gets the MSN Live Theme and puts it into an array
	proc getLiveTheme { email } {
		set xml_data [::abook::getContactData $email spaces_info_xml [list]]
		set live_theme [::MSNSPACES::getLiveThemeData $xml_data]
		if {$live_theme == ""} {
			set live_theme [::ccard::getDefaultLiveTheme]
		}
		return $live_theme
	}

	#///////////////////////////////////////////////////////////////////////////////
	#Draws the ccard on chosen coordinate on a choosen canvas
	proc drawCCard { canvas xcoord ycoord width height email } {
		array set live_theme [::ccard::getLiveTheme $email]
		
		#create the outer border
		$canvas create rectangle 0 0 [expr {$width - 1}] [expr {$height - 1}] -outline "#999999" -tags $email
		$canvas create rectangle 1 1 [expr {$width - 2}] [expr {$height - 2}] -outline "#ffffff" -tags $email

		set head_ratio [expr {222.0 / 88.0}]

		### HEAD AREA ###
		#calculate the header area size
		set head_w [expr {$width - 4}]
		set head_h [expr {int(round($head_w / $head_ratio))}]

		set lineheight 16

		set xpos [expr {$xcoord + 2}]
		set ypos [expr {$ycoord + 2}]

		#draw the header background
		if {[ImageExists ccard_head_bg]} {
			image delete ccard_head_bg
		}
		if {$live_theme(head_bgimage) != ""} {
			# background image
			image create photo ccard_head_bg -width $head_w -height $head_h
			::MSNSPACES::getAlbumImage [list ::ccard::drawSpacesImageCB ccard_head_bg] $live_theme(head_bgimage)
			$canvas create image $xpos $ypos -anchor nw -image ccard_head_bg -tags $email
		} else {
			#solid background
			$canvas create rectangle $xpos $ypos [expr {$xpos + $head_w}] [expr {$ypos + $head_h}] \
				-outline "" -fill $live_theme(head_bg) -tags $email
		}
		
		#calculate the dp frame and the dp position
		set frame_h [image height [::skin::loadPixmap mystatus_bg]]
		set pad [expr {int(round( ($head_h - $frame_h)/2 ))}]
		
		incr xpos 4
		incr ypos $pad
		
		set dp_x [expr {$xpos + [::skin::getKey x_dp_top]}]
		set dp_y [expr {$ypos + [::skin::getKey y_dp_top]}]
		
		#draw the dp
		if {[getpicturefornotification $email]} {
			$canvas create image $dp_x $dp_y -anchor nw -image displaypicture_not_$email -tags $email
		} else {
			if {[ImageExists displaypicture_not_none]} {
				image create photo displaypicture_not_none -file [::skin::GetSkinFile displaypic "nopic.gif"]
				::picture::resizeWithRatio displaypicture_not_none 50 50
			}
			$canvas create image $dp_x $dp_y -anchor nw -image displaypicture_not_none -tags $email
		}

		#draw the dp frame
		$canvas create image $xpos $ypos -anchor nw -image [::skin::loadPixmap mystatus_bg] -tags $email

		incr xpos [image width [::skin::loadPixmap mystatus_bg]]
		incr xpos 4
		set ypos $dp_y

		set limit [expr {$head_w - $xpos - 6}]

		#draw the nickname
		set nick [::abook::getNick $email]
		if {[font measure bboldf -displayof $canvas $nick] > $limit} {
			set nick [::guiContactList::truncateText $nick $limit bboldf "..."]
		}
		$canvas create text $xpos $ypos -text $nick -font bboldf -justify left -anchor nw -fill $live_theme(head_fg)\
			-tags [list $email nickname] 

		incr ypos $lineheight

		#draw the personal status message
		set psm [::abook::getpsmmedia $email]
		if {[font measure bitalf -displayof $canvas $psm] > $limit} {
			set psm [::guiContactList::truncateText $psm $limit bitalf "..."]
		}
		$canvas create text $xpos $ypos -text $psm -font bitalf -justify left -anchor nw -fill $live_theme(head_fg)\
			-tags [list $email psm]

		incr ypos $lineheight

		#draw the email link
		$canvas create text $xpos $ypos	-text $email -font sitalf -anchor nw -fill $live_theme(head_link)\
			-tags [list $email email_address clickable]
		$canvas bind email_address <Button-1> [list launch_mailer $email]
		
		set xpos [expr {$xcoord + $head_w - 14}]
		set ypos [expr {$ycoord + 8}]

		#draw the close button
		$canvas create image $xpos $ypos -anchor nw -image [::skin::loadPixmap ccard_x] \
			-activeimage [::skin::loadPixmap ccard_x_hl] -tags [list $email close_btn clickable]
		
		### BODY AREA ###
		set body_w $head_w
		set body_h [expr {$height - $head_h - 5}]

		set xpos [expr {$xcoord + 2}]
		set ypos [expr {$ycoord + $head_h + 3}]
		
		#draw the body background
		if {[ImageExists ccard_body_bg]} {
			image delete ccard_body_bg
		}
		if {$live_theme(body_bgimage) != ""} {
			# background image
			image create photo ccard_body_bg -width $body_w -height $body_h
			::MSNSPACES::getAlbumImage [list ::ccard::drawSpacesImageCB ccard_body_bg] $live_theme(body_bgimage)
			$canvas create image $xpos $ypos -anchor nw -image ccard_body_bg -tags $email
		} else {
			#solid background
			$canvas create rectangle $xpos $ypos [expr {$xpos + $body_w}] [expr {$ypos + $body_h}] \
				-outline "" -fill $live_theme(body_bg) -tags $email
		}
		
		#the separator reduces the amount of available body space
		set body_h [expr {$body_h - 20}]

		#draw the separator
		set sw_btn_y1 $ypos
		set sw_btn_y2 [expr {$ypos + $body_h + 1}]
		$canvas create rectangle $xpos $ypos [expr {$xpos + $body_w}] [expr {$ypos + 19}] \
			-outline "" -fill $live_theme(body_bg) -tags [list separator separator_tile clickable $email]
		incr ypos
		incr xpos 4
		#the title will be added when we draw the spaces info
		#in case of accidents, we put a fallbacl title
		$canvas create text $xpos $ypos -text "[trans untitled_space]" -font bboldf -justify left -anchor nw -fill $live_theme(body_fg)\
			-tags [list space_title separator clickable $email]

		#draw the switch button
		incr ypos 2
		set xpos [expr {$xcoord + $body_w - 14}]
		$canvas create image $xpos $ypos -anchor nw -image [::skin::loadPixmap ccard_dn] \
			-tags [list separator switch_btn clickable $email]
		$canvas bind separator <Button-1>  [list ::ccard::switchContent $canvas $sw_btn_y1 $sw_btn_y2]
		$canvas bind separator <Enter> [list $canvas itemconfigure separator_tile -fill $live_theme(hover)]
		$canvas bind separator <Leave> [list $canvas itemconfigure separator_tile -fill $live_theme(body_bg)]
		
		#draw the contact info
		set xpos [expr {$xcoord + 2}]
		set ypos [expr {$ycoord + $head_h + 3}]
		::ccard::drawContactInfo $canvas $xpos $ypos $body_w $body_h $email [list contact_info $email]

		#draw the spaces info
		incr ypos 20
		::ccard::drawSpacesInfo $canvas $xpos $ypos $body_w $body_h $email [list spaces_info $email]

		#draw the outlines
		set xpos [expr {$xcoord + 2}]
		set ypos [expr {$ycoord + $head_h + 2}]
		$canvas create line $xpos $ypos [expr {$xpos + $head_w}] $ypos \
			-fill $live_theme(outline) -tags $email
		incr ypos 20
		$canvas create line $xpos $ypos [expr {$xpos + $body_w}] $ypos \
			-fill $live_theme(outline) -tags [list spaces_info $email]
		set ypos [expr {$ypos + $body_h - 19}]
		$canvas create line $xpos $ypos [expr {$xpos + $body_w}] $ypos \
			-fill $live_theme(outline) -tags [list contact_info $email]

		#hide the contact info
		$canvas itemconfigure contact_info -state hidden

		#change pointer on clickables
		$canvas bind clickable <Enter> +[list $canvas configure -cursor hand2]
		$canvas bind clickable <Leave> +[list $canvas configure -cursor left_ptr]
	}

	proc switchContent { canvas y1 y2 } {
		set y [lindex [$canvas coords separator] 1]
		if {$y == $y1} {
			$canvas move separator 0 [expr {$y2 - $y1}]
			$canvas itemconfigure spaces_info -state hidden
			$canvas itemconfigure contact_info -state normal
			$canvas itemconfigure switch_btn -image [::skin::loadPixmap ccard_up]
		} elseif {$y == $y2} {
			$canvas move separator 0 [expr {$y1 - $y2}]
			$canvas itemconfigure contact_info -state hidden
			$canvas itemconfigure spaces_info -state normal
			$canvas itemconfigure switch_btn -image [::skin::loadPixmap ccard_dn] 
		}
	}

	#///////////////////////////////////////////////////////////////////////////////
	#Draws info of contact on chosen coordinate on a choosen canvas
	proc drawContactInfo { canvas xcoord ycoord width height email taglist} {
		array set live_theme [::ccard::getLiveTheme $email]

		set xpos [expr {$xcoord + 4}]
		set ypos [expr {$ycoord + 4}]
		set lineheight 20
		
		$canvas create text $xpos $ypos -text "[trans userdata]" -font bboldf -justify left -anchor nw -fill $live_theme(body_fg)\
			-tags $taglist
		incr ypos $lineheight
		
		$canvas create text $xpos $ypos -text "[trans home]:\t[::abook::getContactData $email phh]" \
			-font bplainf -width $width -justify left -anchor nw -fill $live_theme(body_fg) -tags $taglist
		incr ypos $lineheight

		$canvas create text $xpos $ypos -text "[trans work]:\t[::abook::getContactData $email phw]" \
			-font bplainf -width $width -justify left -anchor nw -fill $live_theme(body_fg) -tags $taglist
		incr ypos $lineheight

		$canvas create text $xpos $ypos -text "[trans mobile]:\t[::abook::getContactData $email phm]" \
			-font bplainf -width $width -justify left -anchor nw -fill $live_theme(body_fg) -tags $taglist
		incr ypos $lineheight
	}
	
	#///////////////////////////////////////////////////////////////////////////////
	#Draws info of MSN Spaces on chosen coordinate on a choosen canvas
	proc drawSpacesInfo { canvas xcoord ycoord width height email taglist } {

		#todo: use bbox or something to calculate height
		set xpos [expr {$xcoord + 4}]
		set ypos [expr {$ycoord + 4}]
		#todo: calculate height of a line the right way
		set lineheight 16
		set photooffset 0

		if { [::abook::getVolatileData $email fetching_space 0] } {
			#draw a "please wait .." message, will be replaced when fetching is done
			$canvas create text $xpos $ypos -font sitalf -text [trans fetching] -tags $taglist -anchor nw -fill grey

			#adjust $height, adding 1 line
			incr ypos $lineheight
			incr ypos 4

		} else {
			#show the data we have in abook

			array set spaces_info [::ccard::getSpacesInfo $email]
			array set live_theme [::ccard::getLiveTheme $email]

			set limit [expr {$width - 18}]

			if {$spaces_info(SpaceTitle) != ""} {
				if {[font measure bboldf -displayof $canvas $spaces_info(SpaceTitle)] > $limit} {
					set SpaceTitle [::guiContactList::truncateText $spaces_info(SpaceTitle) $limit bboldf "..."]
				} else {
					set SpaceTitle $spaces_info(SpaceTitle)
				}
				$canvas itemconfigure space_title -text $SpaceTitle				
			}
			
			incr limit 10

			#blogposts
			if {$spaces_info(Blog) != ""} {
				# seems like a blog without title doesn't exist, so we don't have to check if there are any posts
				#add a title
				$canvas create text $xpos $ypos -font sboldf -text "$spaces_info(Blog)" \
					-tags $taglist -anchor nw -fill $live_theme(body_fg)
				#adjust $ychange, adding 1 line
				incr ypos $lineheight
				incr xpos 10

				set count 0
				foreach i $spaces_info(BlogPosts) {
					set itemtag [lindex $taglist 0]_bpost_${count}
					#check if there's a title
					set title [lindex $i 1]
					if {$title != ""} {
						if {[font measure sitalf -displayof $canvas $title] > $limit} {
							set title [::guiContactList::truncateText $title $limit sitalf "..."]
						}
						$canvas create text $xpos $ypos \
							-font sitalf -text $title -tags [linsert $taglist end $itemtag clickable]\
							-anchor nw -fill $live_theme(body_link)
					} else {
						$canvas create text $xpos $ypos \
							-font sitalf -text "[trans untitled]"\
							-tags [linsert $taglist end $itemtag clickable]  -anchor nw -fill $live_theme(body_link)
					}
					
					$canvas bind $itemtag <Button-1> [list ::hotmail::gotSHA1URL "[lindex $i 2]" 73625]

					#update ychange
					incr ypos $lineheight
					incr count
				}
			}

			set xpos [expr {$xpos - 10}]
			
			#photos
			if {$spaces_info(Album) != ""} {
				#add a title
				$canvas create text $xpos $ypos -font sboldf -text "$spaces_info(Album)" \
					-tags $taglist -anchor nw -fill $live_theme(body_fg)
				#adjust $ychange, adding 1 line
				set ypos [expr {$ypos + $lineheight + 4}]
				incr xpos 10

				set count 0
				foreach i $spaces_info(Photos) {
					set itemtag [lindex $taglist 0]_bpost_${count}
					if { [lindex $i 0] != "" } {

						if {[lindex $i 3] != "" } {
							set img [image create photo tempspacethumb$count -width 35 -height 35]
							::MSNSPACES::getAlbumImage [list ::ccard::drawSpacesImageCB $img] [lindex $i 3]
							$canvas create image $xpos $ypos -image $img \
							    -tags [linsert $taglist end $itemtag clickable] -anchor nw
							$canvas create rectangle $xpos $ypos [expr {$xpos + 35}] [expr {$ypos + 35}] \
								-outline $live_theme(body_link) -tags [linsert $taglist end $itemtag clickable]
							incr xpos 25
						}
						$canvas bind $itemtag <Button-1> \
							[list ::hotmail::gotSHA1URL "[lindex $i 2]" 73625]
						incr count
					}
				}
				incr ypos $lineheight
			}
			#for now show a message if no blogs or photos, for debugging purposes
			if {$spaces_info(Blog) == "" && $spaces_info(Album) == ""} {
				set xpos [expr {$xcoord + 4}]
				$canvas create text $xpos $ypos -font sitalf \
					-text [trans nospace] -tags $taglist -anchor nw -fill grey

				#adjust $ychange, adding 1 line
				incr ypos $lineheight
			}
		}
		return [expr {$ypos - $ycoord}]
	}
	

}
