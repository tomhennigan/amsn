
::Version::setSubversionId {$Id$}

namespace eval ::MSNCCARD {
	variable storageAuthCache ""

	proc InitCCardCallback { soap } {
		variable storageAuthCache
		variable resources
		variable space_info

		if { [$soap GetStatus] == "success"  } {
			set list [$soap GetResponse]
			$soap destroy

			set storageAuthCache [GetXmlEntry $list "soap:Envelope:soap:Header:StorageUserHeader:UserAuthCache"]
			set i 0
			set users_with_update [list]
			while {1 } {
				set subxml [GetXmlNode $list "soap:Envelope:soap:Body:GetItemVersionResponse:GetItemVersionResult:SpaceVersion" $i]

				if {$subxml == "" } {
					break
				}
				set has_new [GetXmlEntry $subxml "SpaceVersion:HasNewItem"]
				set last_modif [GetXmlEntry $subxml "SpaceVersion:LastModifiedDate"]
				set resourceID [GetXmlEntry $subxml "SpaceVersion:SpaceHandle:ResourceID"]
				set email [GetXmlEntry $subxml "SpaceVersion:SpaceHandle:Alias:Name"]
				set resources($email) $resourceID
				set space_info($email) [list $has_new $last_modif $resourceID]
				incr i
				
				# Set the fact that they've got new data as volatile abook data
				
				if {$has_new == "true" } {
					::abook::setVolatileData $email space_updated 1
					lappend users_with_update $email
				} else {
					#Check, if we have a ccard for this user and if all it's modifdate's are older then $last_modif, we have to refetch the ccard the update
					set ccard [::abook::getContactData $email ccardlist [list]]
					if {$ccard != [list]} {
						#search for the latest date, if it's older then $last_modif, refetch the ccard
						#this happens if the user fetched the ccard with another client.  the update
						#flag will be unset but we don't have the latest data yet
						#TODO: CODE ME!	
						
						#PSEUDO-CODE
						#	set dates [::MSNCCARD::getCcardDates $ccard]
						
						#set latest_date ...
						
						#	set latest_unixtime ...
						#	set modif_unixtime ...
						
						#	if {$modif_unixtime > $latest_unixtime } {
						#		::abook::setContactData $email [::MSNCCARD::getContactCard $email]
						#	}	
						
					}
					
					
					::abook::setVolatileData $email space_updated 0
				}
				
			}

			#fire event to redraw contacts with changed space
			::Event::fireEvent contactSpaceChange protocol $users_with_update
		} else {
			status_log "InitCCard: ERROR: [$soap GetLastError]"
			$soap destroy
		}
	}

	proc InitCCard { } {
		set users_with_space [list]
		set all_contacts [::abook::getAllContacts]
		foreach contact $all_contacts {
			set has_space [::abook::getVolatileData $contact HSB]
			if {$has_space == 1 } {
				lappend users_with_space $contact
			}
		}

		if { [llength $users_with_space] > 0 } {
			if { [info exists ::authentication_ticket] } {
				set cookies [split $::authentication_ticket &]
				foreach cookie $cookies {
					set c [split $cookie =]
					set ticket_[lindex $c 0] [lindex $c 1]
				}
				
				if { [info exists ticket_t] && [info exists ticket_p] } {
					set soap_req [SOAPRequest create %AUTO% \
							  -url "http://storage.msn.com/storageservice/schematizedstore.asmx" \
							  -action "http://www.msn.com/webservices/storage/w10/GetItemVersion" \
							  -headers [list "Cookie" "MSPAuth=${ticket_t}; MSPProf=${ticket_p}"] \
							  -xml [::MSNCCARD::getSchematizedStoreXml $users_with_space] \
							  -callback [list ::MSNCCARD::InitCCardCallback]]
					$soap_req SendSOAPRequest
					
				}
			}

		}
	}


	proc getSchematizedStoreXml {contacts} {
		set xml {<?xml version="1.0" encoding="utf-8"?><soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"><soap:Header><StorageApplicationHeader xmlns="http://www.msn.com/webservices/storage/w10"><ApplicationID>Messenger Client 7.0</ApplicationID></StorageApplicationHeader><StorageUserHeader xmlns="http://www.msn.com/webservices/storage/w10"><Puid>0</Puid><UserAuthCache></UserAuthCache><IPAddress/></StorageUserHeader></soap:Header><soap:Body><GetItemVersion xmlns="http://www.msn.com/webservices/storage/w10"><spaceVersionRequests>}
		foreach contact $contacts {
			append xml {<SpaceVersionRequest><SpaceHandle><RelationshipName>MySpace</RelationshipName><Alias><NameSpace>MyStuff</NameSpace><Name>}
			append xml $contact
			append xml {</Name></Alias></SpaceHandle><LastModifiedDate>2004-01-01T00:00:00.0000000-08:00</LastModifiedDate></SpaceVersionRequest>}
		}
		append xml {</spaceVersionRequests><spaceRequestFilter><SpaceFilterAttributes>Annotation</SpaceFilterAttributes><FilterValue>1</FilterValue></spaceRequestFilter></GetItemVersion></soap:Body></soap:Envelope>}
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

	proc getContactCard { email } {
		variable resources
		variable contactcards

		# TODO Is this check useful ? in theory, with MSNP12, the servers sends no HSB for *some* users who have a space...
		if {[::abook::getVolatileData $email HSB] == 1 } {
			if { ![info exists resources($email)] } {
				InitCCard
				if  { ![info exists resources($email)] } {
					return ""
				}
			}
			if { [info exists ::authentication_ticket] } {
				set cookies [split $::authentication_ticket &]
				foreach cookie $cookies {
					set c [split $cookie =]
					set ticket_[lindex $c 0] [lindex $c 1]
				}
				
				if { [info exists ticket_t] && [info exists ticket_p] && [info exists resources($email)] } {
					set soap_req [SOAPRequest create %AUTO% \
							  -url "http://services.spaces.msn.com/contactcard/contactcardservice.asmx" \
							  -action "http://www.msn.com/webservices/spaces/v1/GetXmlFeed" \
							  -xml [::MSNCCARD::getContactCardXml [set resources($email)]] \
							  -headers [list "Cookie" "MSPAuth=${ticket_t}; MSPProf=${ticket_p}"]]
					$soap_req SendSOAPRequest
					if { [$soap_req  GetStatus ] == "success" } {
						set xml [$soap_req GetResponse]
						$soap_req destroy
						return $xml
					}  else {
						status_log "ERROR getting CCARD of $email - $resources($email): [$soap_req  GetLastError]"
						$soap_req destroy
					}
				}
			} 
			
		}
		return ""
	}

	proc getContactCardXml { resourceID } {
		variable storageAuthCache
		set xml {<?xml version="1.0" encoding="utf-8"?> <soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"><soap:Body><GetXmlFeed xmlns="http://www.msn.com/webservices/spaces/v1/"><refreshInformation><spaceResourceId xmlns="http://www.msn.com/webservices/spaces/v1/">}
		append xml $resourceID
		append xml {</spaceResourceId><storageAuthCache>}
		append xml $storageAuthCache
		append xml {</storageAuthCache><market xmlns="http://www.msn.com/webservices/spaces/v1/">en-US</market><brand></brand><maxElementCount xmlns="http://www.msn.com/webservices/spaces/v1/">5</maxElementCount><maxCharacterCount xmlns="http://www.msn.com/webservices/spaces/v1/">200</maxCharacterCount><maxImageCount xmlns="http://www.msn.com/webservices/spaces/v1/">6</maxImageCount></refreshInformation></GetXmlFeed></soap:Body></soap:Envelope>}

		return $xml
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
	::skin::setPixmap ccard_bg ccard_bg.gif
	::skin::setPixmap ccard_close ccard_close.gif
	::skin::setPixmap ccard_close_hover ccard_close_hover.gif
	::skin::setPixmap ccard_left ccard_left.gif
	::skin::setPixmap ccard_left_hover ccard_left_hover.gif
	::skin::setPixmap ccard_right ccard_right.gif
	::skin::setPixmap ccard_right_hover ccard_right_hover.gif
	::skin::setPixmap ccard_back_line ccard_line.gif
	::skin::setPixmap ccard_chat ccard_chat.gif
	::skin::setPixmap ccard_chat_hover ccard_chat_hover.gif
	::skin::setPixmap ccard_email ccard_email.gif
	::skin::setPixmap ccard_email_hover ccard_email_hover.gif
	::skin::setPixmap ccard_nudge ccard_nudge.gif
	::skin::setPixmap ccard_nudge_hover ccard_nudge_hover.gif
	::skin::setPixmap ccard_mobile ccard_mobile.gif
	::skin::setPixmap ccard_mobile_hover ccard_mobile_hover.gif 
	::skin::setPixmap ccard_bpborder ccard_bpborder.gif



	#proc clLoaded { event evpar } {
        #        foreach contact [::abook::getAllContacts] {
        #                set has_space [::abook::getVolatileData $contact HSB]
        #                if {$has_space == 1 } {
        #                        #lappend users_with_space $contact
#				set ccard [::MSNCCARD::getContactCard $contact]
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


			#if we draw the window for the first time, draw it at an intelligent position, with the right size (300x210)
			set winw 300
			set winh 210			
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
			if {[::config::getKey rememberccardposition "1"] && [::config::isSet ccardgeometry]} {
				wm geometry $w [::config::getKey ccardgeometry]
			} else {
				# Default geomtry is relative to the mouse position.
				wm geometry $w ${winw}x${winh}+$xpos+$ypos
			}
			
			#close the window when ESC is pressed, set focus so it can be closed with ESC
			bind $w <<Escape>> "::ccard::closewindow $w"
			focus $w
			
			#the overrideredirect makes it have no border and not draggable etc (no wm stuff)
			wm overrideredirect $w 1
			
			#Define the content of the window
			#================================
			#create the canvas where we will draw our stuff on
			set canvas $w.card
			canvas $canvas -width $winw -height $winh -bg $nocolor -highlightthickness 0 -relief flat -borderwidth 0
			
			#draw the "backgroundpicture"
			$canvas create image 0 0 -anchor nw -image [::skin::loadPixmap ccard_bg]
			
			#make it draggable
			bind $canvas <ButtonPress-1> "::ccard::buttondown $w"
			bind $canvas <B1-Motion> "::ccard::drag $w"
			bind $canvas <ButtonRelease-1> "::ccard::release $w"
		}

		set old_email $email

		#The top buttons
		#---------------		
		CreateTopButtons $w $canvas $email $side

		#The body
		#--------
		drawbody $canvas $email $side 

		#The bottom buttons
		#---------------		
		CreateBottomButtons $w $canvas $email $side

		#pack the canvas into the window
		pack $canvas -side top -fill x
	}

	#################################################
	# closewindow( window )                         #
	#  closes the wiccardndow						#
	#################################################
	proc closewindow { {window ".ccardwin"} } {
		if {[winfo exists $window]} {
			::config::setKey ccardgeometry "300x210+[winfo rootx $window]+[winfo rooty $window]"
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
			set ycoord 185
		}
		$canvas create image $xcoord $ycoord  -anchor nw -image $image -activeimage $hover_image -tag [list $tagname $email]
		$canvas bind $tagname <ButtonPress-1> $command
		tooltip $canvas $tagname "$tooltip"

	}

	#create the buttons on top of the window
	proc CreateTopButtons {w canvas email side} {
		#Set the coordinate on the right where the buttons should be drawn form (to the left)
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
		variable xbegin 1

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



	}


	##################################################
	# drawbody( canvas email side )                  #
	#  defines the data that will be in the body of  #
	#  the contactcard, depending on the emailaddres #
	#  (id) of the contact and the side to display   #
	##################################################
	proc drawbody { canvas email side } {

		if {$side == 1} {
		#======================
		#This is the front side
		#======================
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
			$canvas create text 114 22 -text [::abook::getNick $email] -font bigfont -width 170 -justify left -anchor nw -fill black -tags [list dp $email]
			::guiContactList::drawSpacesInfo $canvas 114 50 $email [list $email space_info contact]
			tooltip $canvas tt "$email\n[trans status] : [trans [::MSN::stateToDescription [::abook::getVolatileData $email state]]]\n[trans lastmsgedme] : [::abook::dateconvert "[::abook::getContactData $email last_msgedme]"]"

			
			
		} else {
		#=====================
		#This is the back side
		#=====================
			set backtextcolor #616060
			set xcoord 12

			$canvas create text $xcoord 30 -text "[trans email]:\t$email" -font bplainf -width 280 -justify left -anchor nw -fill $backtextcolor -tags $email

			$canvas create image 10 66 -anchor nw -image [::skin::loadPixmap ccard_back_line] -tags $email

			$canvas create text $xcoord 80 -text "[trans home]:\t[::abook::getContactData $email phh]" -font bplainf -width 280 -justify left -anchor nw -fill $backtextcolor  -tags $email
			$canvas create text $xcoord 100 -text "[trans work]:\t[::abook::getContactData $email phw]" -font bplainf -width 280 -justify left -anchor nw -fill $backtextcolor -tags $email
			$canvas create text $xcoord 120 -text "[trans mobile]:\t[::abook::getContactData $email phm]" -font bplainf -width 280 -justify left -anchor nw -fill $backtextcolor -tags $email

		}
	}

	##################################################
	# changeside( email side )                       #
	#  redraws the window with the other side        #
	##################################################
	proc changeside {email side} {
		if {$side == 1} {
			drawwindow $email 2
		} else {
			drawwindow $email 1
		}
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
	}
	proc release {w} {
		variable dset
		#set 'button is released'
		set dset 0
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

}
