# Now relies on guicontactlist's truncateText proc

::Version::setSubversionId {$Id$}

namespace eval ::MSNSPACES {
	variable storageAuthCache ""

	proc InitSpacesCallback { callbk soap } {
		variable storageAuthCache
		variable resources
		variable space_info

		if { [$soap GetStatus] == "success"  } {
			set list [$soap GetResponse]
			$soap destroy

			set storageAuthCache [GetXmlEntry $list "soap:Envelope:soap:Header:StorageUserHeader:UserAuthCache"]
			set i 0
			set users_with_space [list]
			while {1 } {
				set subxml [GetXmlNode $list "soap:Envelope:soap:Body:GetItemVersionResponse:GetItemVersionResult:SpaceVersion" $i]

				incr i
				if {$subxml == "" } {
					break
				}
				set has_new [GetXmlEntry $subxml "SpaceVersion:HasNewItem"]
				set last_modif [GetXmlEntry $subxml "SpaceVersion:LastModifiedDate"]
				set resourceID [GetXmlEntry $subxml "SpaceVersion:SpaceHandle:ResourceID"]
				set email [GetXmlEntry $subxml "SpaceVersion:SpaceHandle:Alias:Name"]


				if { [string length $resourceID] > 0} {
					lappend users_with_space $email
					set resources($email) $resourceID
					set space_info($email) [list $has_new $last_modif $resourceID]
					
					# Transform the last modification date to an acceptable date format... 
					# "2006-02-19T01:49:59-08:00" is not accepted, but "2006-02-19T01:49:59" is accepted
					if { [catch { 
						set idx [string last "+" $last_modif]
						if {$idx != -1 } {
							incr idx -1
							set last_modif [clock scan [string range $last_modif 0 $idx]]
						} else {
							set idx [string last "-" $last_modif]
							incr idx -1
							set last_modif [clock scan [string range $last_modif 0 $idx]]
						}
					}] } {
						if { [regexp {(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})([-+]\d{2}:\d{2})} $last_modif -> y m d h min s z] } {
							set last_modif [clock scan "${y}-${m}-${d} ${h}:${min}:${s}"]
						}
					}
					
					# Set the fact that they've got new data as volatile abook data
					if {$has_new == "true" } {
						::abook::setVolatileData $email space_updated 1
						::abook::setContactData $email spaces_info_xml [list]
						::abook::setContactData $email spaces_last_modif $last_modif
					} else {
						::abook::setVolatileData $email space_updated 0
						
						# Reset the known info if the last modified date has changed,
						# this means that the user fetched the spaces info from another client
						set old_date [::abook::getContactData $email spaces_last_modif 0]
						if { $last_modif > $old_date } {
							::abook::setContactData $email spaces_info_xml [list]
							::abook::setContactData $email spaces_last_modif $last_modif						
						}
					}
				} else {
					status_log "User $email has a space but no resource ID : $subxml" red
				}
				
			}

			#fire event to redraw contacts with changed space
			::Event::fireEvent contactSpaceChange protocol $users_with_space
		} else {
			status_log "InitSpaces: ERROR: [$soap GetLastError]"
			$soap destroy
		}
		
		if {$callbk != "" } {
			eval $callbk
		}
	}

	proc InitSpaces { {callbk ""} } {
		set users_with_space [list]
		set all_contacts [::MSN::sortedContactList]

		if { [llength $all_contacts] > 0 } {
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
							  -xml [::MSNSPACES::getSchematizedStoreXml $all_contacts] \
							  -callback [list ::MSNSPACES::InitSpacesCallback $callbk]]
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

	proc hasSpace { email } {
		variable resources
		return [info exists resources($email)]
	}

	proc getContactCardCallback { email callback soap } {
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
			variable resources
			status_log "ERROR getting CCARD of $email - $resources($email) - [$soap GetStatus ]: [$soap GetLastError]"
			$soap destroy
			if {[catch {eval $callback [list [list]]} result]} {
				bgerror $result
			}
		}
	}
	proc getContactCard { email callback } {
		variable resources
		variable contactcards
		
		status_log "fetching ContactCard for user $email"

		if {[::MSNSPACES::hasSpace $email] } {
			if  {[info exists ::authentication_ticket] } {
				set cookies [split $::authentication_ticket &]
				foreach cookie $cookies {
					set c [split $cookie =]
					set ticket_[lindex $c 0] [lindex $c 1]
				}
				
				if { [info exists ticket_t] && [info exists ticket_p] } {
					set soap_req [SOAPRequest create %AUTO% \
							  -url "http://cc.services.spaces.msn.com/contactcard/contactcardservice.asmx" \
							  -action "http://www.msn.com/webservices/spaces/v1/GetXmlFeed" \
							  -xml [::MSNSPACES::getContactCardXml [set resources($email)]] \
							  -headers [list "Cookie" "MSPAuth=${ticket_t}; MSPProf=${ticket_p}"] \
							  -callback [list ::MSNSPACES::getContactCardCallback $email $callback]]
					$soap_req SendSOAPRequest
					return
				}
			} 
		}
		
		status_log "Error fetching ContactCard for user $email" red
		# This gets executed if the SOAP request is not sent.. serves as error handler
		if {[catch {eval $callback [list [list]]} result]} {
			bgerror $result
		}
	}

	proc getContactCardXml { resourceID } {
		variable storageAuthCache

		set xml {<?xml version="1.0" encoding="utf-8"?> <soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">}
		append xml {<soap:Header><AuthTokenHeader xmlns="http://www.msn.com/webservices/spaces/v1/"><Token>}
		append xml [::sxml::xmlreplace $::authentication_ticket]
		append xml {</Token></AuthTokenHeader></soap:Header>}
		append xml {<soap:Body><GetXmlFeed xmlns="http://www.msn.com/webservices/spaces/v1/"><refreshInformation><spaceResourceId xmlns="http://www.msn.com/webservices/spaces/v1/">}
		append xml $resourceID
		append xml {</spaceResourceId><storageAuthCache>}
		append xml $storageAuthCache
		append xml {</storageAuthCache><market xmlns="http://www.msn.com/webservices/spaces/v1/">en-US</market><brand></brand><maxElementCount xmlns="http://www.msn.com/webservices/spaces/v1/">5</maxElementCount><maxCharacterCount xmlns="http://www.msn.com/webservices/spaces/v1/">200</maxCharacterCount><maxImageCount xmlns="http://www.msn.com/webservices/spaces/v1/">6</maxImageCount></refreshInformation></GetXmlFeed></soap:Body></soap:Envelope>}

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
	proc getAlbumImage { url } {
		set data ""
		if { [info exists ::authentication_ticket] } {
			set cookies [split $::authentication_ticket &]
			foreach cookie $cookies {
				set c [split $cookie =]
				set ticket_[lindex $c 0] [lindex $c 1]
			}
			
			if { [info exists ticket_t] && [info exists ticket_p] } {
				set token [http::geturl $url -headers [list "Cookie" "MSPAuth=${ticket_t}; MSPProf=${ticket_p}"] ]
				set data [::http::data $token]
				::http::cleanup $token
			}
		}
		return $data
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

		
	proc fetchSpace {email} {
		#if an update is available, we'll have to fetch it
		if {[::abook::getContactData $email spaces_info_xml [list]] == [list] } {
			::abook::setVolatileData $email fetching_space 1
			# fetch the ccard info and check if the user 
			::MSNSPACES::getContactCard $email [list ::MSNSPACES::fetchedSpace $email]
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
			foreach photolist $photos {
				#download the thumbnail
				set thumbnailurl [lindex $photolist 3]
				set data [getAlbumImage $thumbnailurl]
				set filename "[file join $cachedir $count.jpg]"
				set fid [open $filename w]
				fconfigure $fid -translation binary
				puts -nonewline $fid "$data"
				close $fid
				
				incr count
			}		
		
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
		#------------------
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
			tooltip $canvas tt "$email\n[trans status] : [trans [::MSN::stateToDescription [::abook::getVolatileData $email state]]]\n[trans lastmsgedme] : [::abook::dateconvert "[::abook::getContactData $email last_msgedme]"]"

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
	
						$canvas bind $itemtag <Button-1> [list ::hotmail::gotURL "[lindex $i 2]"]
	
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
								set imageData [::MSNSPACES::getAlbumImage [lindex $i 3]]
								if {$imageData != "" } {
									set img [image create photo tempspacethumb$count -data $imageData]
									::picture::ResizeWithRatio $img 22 22
	
									lappend stylestring [list "tag" "$itemtag"]
									lappend stylestring [list "image" $img "w"]
									lappend stylestring [list "tag" "-$itemtag"]
	
									lappend stylestring [list "space" 3]
	
									bind $canvas <Destroy> +[list image delete tempspacethumb$count]
								}
							}
							$canvas bind $itemtag <Button-1> \
								[list ::hotmail::gotURL "[lindex $i 2]"]
	
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

	#///////////////////////////////////////////////////////////////////////////////
	#Draws info of MSN Spaces on chosen coordinate on a choosen canvas
	proc drawSpacesInfo { canvas xcoord ycoord email taglist } {


		#todo: use bbox or something to calculate height
		set height 0
		#todo: calculate height of a line the right way
		set lineheight 12
		set photooffset 0

		if { [::abook::getVolatileData $email fetching_space 0] } {
			#draw a "please wait .." message, will be replaced when fetching is done
			$canvas create text $xcoord $ycoord -font sitalf -text [trans fetching] -tags $taglist -anchor nw -fill grey

			#adjust $height, adding 1 line
			set height [expr {$height + $lineheight + 4}]

		} else {
			#show the data we have in abook

			set ccard [::abook::getContactData $email spaces_info_xml [list]]

			# Store the titles in a var
			foreach i [list SpaceTitle Blog Album Music] {
				set $i [::MSNSPACES::getTitleFor $ccard $i]
#				puts "$i = [set $i]"
			}
			
			#First show the spaces title:
			if {$SpaceTitle != ""} {
				if {[font measure bboldf -displayof $canvas $SpaceTitle] > 175} {
					set SpaceTitle [::guiContactList::truncateText $SpaceTitle 175 bboldf "..."]
				}
				$canvas create text $xcoord [expr {$ycoord + $height}] -font bboldf -text $SpaceTitle\
					-tags $taglist -anchor nw -fill black
				
				#adjust $ychange, adding 1 line
				set height [expr {$height + $lineheight + 4 }]
				#set everything after this title a bit to the right
				set xcoord [expr {$xcoord + 10}]
			}

			#blogposts
			if {$Blog != ""} {
				# seems like a blog without title doesn't exist, so we don't have to check if there are any posts
				set blogposts [::MSNSPACES::getAllBlogPosts $ccard]
				#add a title
				$canvas create text $xcoord [expr {$ycoord + $height}] -font sboldf -text "$Blog" \
					-tags $taglist -anchor nw -fill #78797e
				#adjust $ychange, adding 1 line
				set height [expr {$height + $lineheight}]

				set count 0
				foreach i $blogposts {
					set itemtag [lindex $taglist 0]_bpost_${count}
					#check if there's a title
					set title [lindex $i 1]
					if {$title != ""} {
						if {[font measure sitalf -displayof $canvas $title] > 155} {
							set SpaceTitle [::guiContactList::truncateText $title 155 sitalf "..."]
						}
						$canvas create text [expr {$xcoord + 10}] [expr {$ycoord + $height} ] \
							-font sitalf -text $title -tags [linsert $taglist end $itemtag clickable]\
							-anchor nw -fill black
					} else {
						$canvas create text [expr {$xcoord + 10}] [expr {$ycoord + $height} ] \
							-font sitalf -text "[trans untitled]"\
							-tags [linsert $taglist end $itemtag clickable]  -anchor nw -fill black
					}
					
					$canvas bind $itemtag <Button-1> [list ::hotmail::gotURL "[lindex $i 2]"]

					#update ychange
					set height [expr {$height + $lineheight}]
					incr count
				}
			}

			
			#photos
			if {$Album != ""} {
				set photos [::MSNSPACES::getAllPhotos $ccard]
				#add a title
				$canvas create text $xcoord [expr {$ycoord + $height}] -font sboldf -text "$Album" \
					-tags $taglist -anchor nw -fill #78797e
				#adjust $ychange, adding 1 line
				set height [expr {$height + 4}]

				set count 0
				foreach i $photos {
					set itemtag [lindex $taglist 0]_bpost_${count}
#puts "Photo: $i"
					if { [lindex $i 0] != "" } {

						if {[lindex $i 3] != "" } {
							set imageData [::MSNSPACES::getAlbumImage [lindex $i 3]]
							if {$imageData != "" } {
								set img [image create photo tempspacethumb$count -data $imageData]
								::picture::ResizeWithRatio $img 22 22
								set imgx [expr {$xcoord + 10 + $photooffset}]
								set imgy [expr {$ycoord + $height + $lineheight}]
								$canvas create image $imgx $imgy -image $img \
								    -tags [linsert $taglist end $itemtag clickable] -anchor nw
								$canvas create rectangle $imgx $imgy  [expr {$imgx + 22}] [expr {$imgy + 22}] -outline #576373 -tags [linsert $taglist end $itemtag clickable]
								set photooffset [expr {$photooffset + 25}]
								bind $canvas <Destroy> +[list image delete tempspacethumb$count]
							}
						}
						$canvas bind $itemtag <Button-1> \
							[list ::hotmail::gotURL "[lindex $i 2]"]
						#update ychange
#						set height [expr {$height + $lineheight } ]
						incr count
					}
				}
				set height [expr {$height + $lineheight } ]
			}
			#for now show a message if no blogs or photos, for debugging purposes
			if {$Blog == "" && $Album == ""} {
				$canvas create text $xcoord [expr $ycoord + $height] -font sitalf \
					-text [trans nospace] -tags $taglist -anchor nw -fill grey

				#adjust $ychange, adding 1 line
				set height [expr {$height + $lineheight } ]
			}
		}
		$canvas bind clickable <Enter> +[list $canvas configure -cursor hand2]
		$canvas bind clickable <Leave> +[list $canvas configure -cursor left_ptr]
		
		
			
		return $height	
	}
	

}
