

namespace eval ::devel {
	namespace export plugins
	variable develwin
	variable plugins
	variable w
	variable plugins
	#variable loadedplugins
	variable selection
	variable mF
	variable packloaded
	variable namespaces
	variable procs
	variable console
	
	proc InitPlugin { dir } {
		variable develwin
		variable packloaded
		variable namespaces
		variable procs
		variable console
		#RegisterPlugin
		::plugins::RegisterPlugin "Devel"

		#Register events
		#::devel::RegisterEvent
		#Set default values for config
		::devel::ConfigArray
		#Add items to configure window
		::devel::ConfigList
		set develwin ".develwin"
		set console ".develconsole"
		#bind . <Alt-d> ::devel::drawMainWindow
		if {![catch {tk windowingsystem} wsystem] && $wsystem == "aqua"} {
			bind . <Option-d> ::devel::drawMainWindow
		} else {
			bind . <Alt-d> ::devel::drawMainWindow
		}
		set packloaded [list "Package list not created"]
		set procs [list "Proc list not created"]
		log "Generating package list"
		generatePackageList ""
		log "generating proc list"
		generateProcList ""
	}
	proc recursiveNamespace { namespaces } {
		log "recu: $namespaces"
		return recuriveNamespace [namespace children $namespaces]
	}

	proc DeInit { } {
		variable packloaded
		variable namespaces
		variable procs
		variable console
		unset $packloaded
		unset $namespaces
		unset $procs
		interp delete $console
		if {![catch {tk windowingsystem} wsystem] && $wsystem == "aqua"} {
			bind . <Option-d> ""
		} else {
			bind . <Alt-d> ""
		}
	}

	proc ConfigArray {} {
		array set ::devel::config {
			help {0}
		}
	}

	proc ConfigList {} {
		set ::devel::configlist [list \
			[list label "To activate the devel menu, hit alt-d" help] \
		]
	}

	proc RegisterEvent {} {
	}

	proc drawMainWindow { } {
		variable develwin
		toplevel $develwin
		::devel::buildForms
		moveinscreen $develwin 200
	}

#####################################################################
#
#  Les onglets
#
#
#####################################################################
	proc buildForms { } {
		variable develwin

		frame $develwin.nb -class Degt

		set develNb $develwin.nb

		NoteBook $develNb.nn

		$develNb.nn insert end varlist -text "Var list"
		#$develNb.nn insert end varsearch -text "Vars"
		$develNb.nn insert end procs -text "Procs"
		$develNb.nn insert end plugins -text "Plugins"
		$develNb.nn insert end memstats -text "Memory"
		$develNb.nn insert end dock -text "Dock"
		$develNb.nn insert end packages -text "Packages"
		$develNb.nn insert end images -text "Images"
		$develNb.nn insert end pixmaps -text "Pixmaps"
		$develNb.nn insert end svn -text "Svn"
		#$develNb.nn insert end config -text "[trans config]"
		$develNb.nn insert end console -text "Console"
		$develNb.nn insert end logs -text "Logs"
		$develNb.nn insert end about -text "[trans about]"


		#  .------.
		# _| list |_____________
		set frm [ $develNb.nn getframe varlist]
		#ScrolledWindow $frm.sw
		#ScrollableFrame $frm.sw.sf -constrainedwidth 1
		#$frm.sw setwidget $frm.sw.sf
		#pack $frm.sw -anchor n -side top -expand true -fill both
		
		#set frm [ $frm.sw.sf getframe ]
		::devel::buildFormList $frm

		$develNb.nn compute_size
		#[$develNb.nn getframe varlist].sw.sf compute_size
		#[$develNb.nn getframe varlist] compute_size


		##  .--------.
		## _| search |______
		#set frm [$develNb.nn getframe varsearch]
		#ScrolledWindow $frm.sw
		#ScrollableFrame $frm.sw.sf -constrainedwidth 1
		#$frm.sw setwidget $frm.sw.sf
		#pack $frm.sw -anchor n -side top -expand true -fill both
		#set frm [ $frm.sw.sf getframe ]
		#::devel::buildFormSearch $frm

		#$develNb.nn compute_size
		#[$develNb.nn getframe varsearch ].sw.sf compute_size

		#  .---------.
		# _| procs   |____________
		set frm [$develNb.nn getframe procs]
		#ScrolledWindow $frm.sw
		#ScrollableFrame $frm.sw.sf -constrainedwidth 1
		#$frm.sw setwidget $frm.sw.sf
		#pack $frm.sw -anchor n -side top -expand true -fill both
		#set frame [ $frm.sw.sf getframe ]
		::devel::buildProcs $frm

		#$develNb.nn compute_size
		#[$develNb.nn getframe procs ].sw.sf compute_size


		## mem
		set frm [$develNb.nn getframe memstats]
		ScrolledWindow $frm.sw
		ScrollableFrame $frm.sw.sf -constrainedwidth 1
		$frm.sw setwidget $frm.sw.sf
		pack $frm.sw -anchor n -side top -expand true -fill both
		set frame [ $frm.sw.sf getframe ]
		::devel::buildMemStats $frame
		$develNb.nn compute_size
		[$develNb.nn getframe memstats ].sw.sf compute_size

		#  .-----------.
		# _| plugins   |_________
		set frm [$develNb.nn getframe plugins]
		#ScrolledWindow $frm.sw
		#ScrollableFrame $frm.sw.sf -constrainedwidth 1
		#$frm.sw setwidget $frm.sw.sf
		#pack $frm.sw -anchor n -side top -expand true -fill both
		#set frm [ $frm.sw.sf getframe ]
		
		::devel::plugins $frm

		#$develNb.nn compute_size
		#[$develNb.nn getframe plugins].sw.sf compute_size


		#  .-----.
		# _| svn |_____
		set frm [$develNb.nn getframe svn]
		ScrolledWindow $frm.sw
		ScrollableFrame $frm.sw.sf -constrainedwidth 1
		$frm.sw setwidget $frm.sw.sf
		pack $frm.sw -anchor n -side top -expand true -fill both
		set frm [ $frm.sw.sf getframe ]

		::devel::svnGetVersion $frm

		#pack [button $frm.b -command exit -text Exit]
		#load_console
		button $frm.svnuptbtn -text "[trans update] svn" -command "::devel::svnUpdate $frm"
		text $frm.svntext

		$develNb.nn compute_size
		[$develNb.nn getframe svn].sw.sf compute_size

		#  .------.
		# _| dock |___
		set frm [$develNb.nn getframe dock]
		ScrolledWindow $frm.sw
		ScrollableFrame $frm.sw.sf -constrainedwidth 1
		$frm.sw setwidget $frm.sw.sf
		pack $frm.sw -anchor n -side top -expand true -fill both
		set frm [ $frm.sw.sf getframe ]

		::devel::dock $frm

		$develNb.nn compute_size
		[$develNb.nn getframe dock].sw.sf compute_size

		#  .----------.
		# _| packages |___
		set frm [$develNb.nn getframe packages]
		#ScrolledWindow $frm.sw
		#ScrollableFrame $frm.sw.sf -constrainedwidth 1
		#$frm.sw setwidget $frm.sw.sf
		#pack $frm.sw -anchor n -side top -expand true -fill both
		#set frm [ $frm.sw.sf getframe ]

		::devel::packages $frm

		#$develNb.nn compute_size
		#[$develNb.nn getframe packages].sw.sf compute_size
		
		#  .----------.
		# _| images   |___
		set frm [$develNb.nn getframe images]
		#ScrolledWindow $frm.sw
		#ScrollableFrame $frm.sw.sf -constrainedwidth 1
		#$frm.sw setwidget $frm.sw.sf
		#pack $frm.sw -anchor n -side top -expand true -fill both
		#set frm [ $frm.sw.sf getframe ]

		::devel::images $frm

		#$develNb.nn compute_size
		#[$develNb.nn getframe packages].sw.sf compute_size
		
		#  .----------.
		# _| pixmap   |___
		set frm [$develNb.nn getframe pixmaps]
		#ScrolledWindow $frm.sw
		#ScrollableFrame $frm.sw.sf -constrainedwidth 1
		#$frm.sw setwidget $frm.sw.sf
		#pack $frm.sw -anchor n -side top -expand true -fill both
		#set frm [ $frm.sw.sf getframe ]

		::devel::pixmaps $frm

		#$develNb.nn compute_size
		#[$develNb.nn getframe packages].sw.sf compute_size
		
		#  .--------.
		# _| console  |____
		set frm [$develNb.nn getframe console]
		ScrolledWindow $frm.sw
		ScrollableFrame $frm.sw.sf -constrainedwidth 1
		$frm.sw setwidget $frm.sw.sf
		pack $frm.sw -anchor n -side top -expand true -fill both
		set frm [ $frm.sw.sf getframe ]
		::devel::console $frm
		$develNb.nn compute_size
		[$develNb.nn getframe console].sw.sf compute_size

		#  .--------.
		# _| logs   |____
		set frm [$develNb.nn getframe logs]
		ScrolledWindow $frm.sw
		ScrollableFrame $frm.sw.sf -constrainedwidth 1
		$frm.sw setwidget $frm.sw.sf
		pack $frm.sw -anchor n -side top -expand true -fill both
		set frm [ $frm.sw.sf getframe ]
		::devel::logs $frm
		$develNb.nn compute_size
		[$develNb.nn getframe logs].sw.sf compute_size

		
		##  .--------.
		## _| config |____
		#set frm [$develNb.nn getframe config]
		#ScrolledWindow $frm.sw
		#ScrollableFrame $frm.sw.sf -constrainedwidth 1
		#$frm.sw setwidget $frm.sw.sf
		#pack $frm.sw -anchor n -side top -expand true -fill both
		#set frm [ $frm.sw.sf getframe ]
		#::devel::config $frm
		#$develNb.nn compute_size
		#[$develNb.nn getframe config].sw.sf compute_size

		#  .--------.
		# _| about  |____
		set frm [$develNb.nn getframe about]
		ScrolledWindow $frm.sw
		ScrollableFrame $frm.sw.sf -constrainedwidth 1
		$frm.sw setwidget $frm.sw.sf
		pack $frm.sw -anchor n -side top -expand true -fill both
		set frm [ $frm.sw.sf getframe ]
		::devel::about $frm
		$develNb.nn compute_size
		[$develNb.nn getframe about].sw.sf compute_size


		####
		set frm [ frame $develwin.save -class Degt ]
		#button $frm.save -text [trans save] -default active -command "::devel::savePrefs; destroy $develwin"
		#button $frm.cancel -text [trans close] -command "destroy $develwin"
		button $frm.close -text [trans close] -default active -command "destroy $develwin"

		#pack $frm.save $frm.cancel -side right -padx 10 -pady 10
		pack $frm.close -side right -padx 10 -pady 10
		pack $frm -side bottom -fill x
		
		
		# fin, compactage
		$develNb.nn raise varlist
		pack $develNb.nn -expand true -fill both
		pack $develwin.nb -side bottom -fill both -expand true -padx 5 -pady 5


		bind $develwin <<Escape>> "destroy $develwin"
	}

#####################################################################
#
# VAR
#
#
#####################################################################

	proc buildFormList { win } {
		#set frm [ frame $win.list ]
		#
		#foreach { key } [ lsort [ ::config::getKeys ] ] {
		#	set frame [frame $frm.f$key]
		#	::devel::drawKeyVal $frame $key
		#}
		#pack $frm -side top -fill both -expand true
		entry $win.texte -bg white -textvariable defaultSearch
		entry $win.var -bg white
		#label $win.textl -text "var :"
		#button $win.btn -text "Search" -command ""
		#pack $win.texte -side top -anchor nw -fill y
		#pack $win.var -side top -anchor center -fill y
		pack $win.texte -side top -anchor nw -fill both
		pack $win.var -side top -anchor nw -fill both
		pack $win -fill y
		#pack $win.texte $win.btn -side top -anchor nw
		bind $win.texte <KeyRelease> "::devel::updateVarSearch %A %W $win"
		
		#pack $win.texte $win.textl $win.btn
		listbox $win.l -listvariable listVar -font splainf -bg white -bg white \
			-height 90 -width 30 -yscrollcommand "$win.listbox_scroll set"
		pack $win.l -side left
		scrollbar $win.listbox_scroll -command "$win.l yview" -width 16 -highlightthickness 0
		pack $win.listbox_scroll -side left -fill y

		#bind $win.l <Double-B1-ButtonRelease> "::devel::setCommandValue $win [::config::getKey [.develwin.nb.nn.fvarlist.sw.sf.frame.l get active]]"
		#bind $win.l <Double-B1-ButtonRelease> "::devel::onDoubleClick $win"
		bind $win.l <Double-B1-ButtonRelease> "::devel::onDoubleClick $win"
		
		# Draw the text widget.
		text $win.t -yscrollcommand "$win.scroll set" \
			-width 70 -height 100 -wrap word -font splainf -highlightthickness 0 
		#-width 70 -height 100 -wrap word -font LucidaGrande -highlightthickness 0 
		scrollbar $win.scroll -command "$win.t yview" -width 16
		pack $win.scroll -side right -fill y
		pack $win.t -expand yes -fill both
		#bind $w.t <Double-B1-ButtonRelease> {::acv::editCommandValue [.acvWindow.l get active]}
		
		# Set up the view in the listbox and text widget.
		#log "win: $win"
		setCommandValue $win "Please choose a variable from the list on the left."
		#setCommandsList $win [lsort -dictionary [info procs "::*"]]
		setCommandsList $win [lsort -dictionary [::config::getKeys]]
	}

	proc updateVarSearch { char w win } {
		$win.l delete 1 end
		set char [$win.texte get]
		log "updateVarSearch: $win"
		setCommandsList $win [lsort -dictionary [::devel::getVar "$char"]]
	}

	proc onDoubleClick { win } {
		::devel::setCommandValue $win [::config::getKey [$win.l get active]]
	}
	################################################################
	# ::acv::_alternate.listbox.colors(listWin, colList)
	# Taken from: http://wiki.tcl.tk/9561
	# Gives an alternating row background to a listbox.
	# Arguments:
	# - listWin => The path to the list item.
	# - colList => A list with the colors to alternate between.
	proc _alternate.listbox.colors {listWin color} {
		#if {![winfo exists $listWin]} {
		#	return -code error {invalid window path}
		#}
		set listWinEnd [$listWin index end]
		#set colCount 0
		#set colListLength [llength $colList]
		#for {set i 0} {$i < $listWinEnd} {incr i} {
		#	$listWin itemconfigure $i -background [lindex $colList $colCount]
		#	incr colCount
		#	if {$colCount >= $colListLength} {
		#		set colCount 0
		#	}
		#}
		for {set i 0} {$i < $listWinEnd} {set i [expr {$i+2}]} {
			$listWin itemconfigure $i -background $color
		}
	}
	
	################################################################
	# ::acv::_updateReadOnlyTextBox(textItemPath, newText)
	# Updates a read only text box item.
	# Arguments:
	# - textItemPath => The path to the text box item.
	# - newText => The text to replace the current text with.
	proc _updateReadOnlyTextBox {textItemPath newText} {
		${textItemPath} configure -state normal
		${textItemPath} delete 1.0 end
		${textItemPath} insert end $newText
		${textItemPath} configure -state disabled
	}
	
	################################################################
	# ::acv::_updateAlternatingList(listItemPath, newItems)
	# Helper function to update an alternating list box.
	# Arguments:
	# - listItemPath => The path to the list box item.
	# - newItems => A list of new items to set as the contents of the list item.
	proc _updateAlternatingList {listItemPath newItems color} {
		#log "_updateAlternatingList $listItemPath :: $newItems"
		${listItemPath} delete 0 end
		foreach {item} $newItems {
			${listItemPath} insert end $item
			#log "_updateAlternatingList2: ${listItemPath} insert end $item"
		}
		#_alternate.listbox.colors ${listItemPath} [list white #edf3fe]
		if { $color == 1} {
			_alternate.listbox.colors ${listItemPath} "#edf3fe"
		}
	}
	
	################################################################
	# ::acv::setCommandValue(newDescription)
	# Set the value of the text box to newDescription.
	# Arguments:
	#	 - newDescription => A string with the value of the current command.
	proc setCommandValue {win newDescription} {
		#upvar 1 win $win
		_updateReadOnlyTextBox $win.t $newDescription
	}
	
	################################################################
	# ::acv::setCommandsList(newList)
	# Set the commands list box to the value of newList.
	# Arguments:
	#	 - newList => A list with the new values to set in the available commands list.
	proc setCommandsList { win newList {color 1}} {
		#log "setCommandsList: $win :: $newList"
		#upvar 1 win $win
		_updateAlternatingList $win.l $newList $color
	}


#####################################################################
#
#	Search vars
#
#
#####################################################################
	#proc buildFormSearch { win } {
	#	set frm [ frame $win.search]
	#	set frmb [frame $win.box]

	#	set defaultSearch "*"

	#	entry $frm.texte -bg white -textvariable defaultSearch
	#	label $frm.textl -text "var :"
	#	button $frm.btn -text "Search" -command [list ::devel::searchFor "$frm.texte" "$frmb.box"]

	#	# todo: faire en sorte que quand on appuie sur enter ça lance la recherche
	#	#bind $frm.textl <Return> [list ::devel::searchFor "$frm.texte" "$frmb.box" ]
	#	bind $frm.texte <Return> [list ::devel::searchFor "$frm.texte" "$frmb.box"]

	#	pack $frm.textl -anchor w -side left -padx 40
	#	pack $frm.texte -anchor w -side left -fill x
	#	pack $frm.btn -anchor w -side left -fill x
	#	pack $frm -fill x

	#	# result list box
	#	listbox $frmb.box -background white -yscrollcommand "$frmb.scroll set"
	#	scrollbar $frmb.scroll -command "$frmb.box yview" -borderwidth 1
	#	pack $frmb.box -side left -anchor w -pady 0 -padx 0 -expand true -fill both
	#	pack $frmb.scroll -side left -anchor w -pady 0 -padx 0 -fill y
	#	pack $frmb -side top -expand true -fill x


	#	# variable edit box
	#	# partie en dessous, qui permettera de modifier la var
	#	set frmr [ frame $win.res ]
	#	label $frmr.textl
	#	entry $frmr.texte -bg white 
	#	pack $frmr.textl -anchor w -side left 
	#	pack $frmr.texte -anchor w -side left -fill x
	#	pack $frmr
	#	
	#	bind $frmb.box <Double-1> [list ::devel::searchShowVar $frmb.box $frmr]
	#}

	#proc searchShowVar { lb res } {
	#	$res.textl configure -text [$lb get [$lb curselection]]
	#	$res.texte configure -textvariable [::config::getVar [$lb get [$lb curselection]]]
	#}

	proc getKey { key } {
		return [ array get ::config "*$key*" ]
	}

	proc getVar { key } {
		log "looking for $key"
		return [ array names ::config "*$key*" ]
	}

	proc drawKeyVal { win key } {
		label $win.varl -text $key
		entry $win.vare -textvariable [::config::getVar $key] -bg white
		pack $win.varl -anchor w -side left -padx 40
		pack $win.vare -anchor w -side left -fill x
		pack $win -fill x
	}

	proc searchFor { search lb } {
		variable develwin
		set i 0
		set search [$search get]
		$lb delete 0 [$lb size]

		foreach { key } [ lsort [::devel::getVar $search]] {
			incr i
			$lb insert end $key
		}
	}


#####################################################################
#
# Procs
#
#
#####################################################################
	proc buildProcs { win } {
		variable namespaces
		variable procs
		entry $win.texte -bg white
		pack $win.texte -side top -anchor nw -fill both
		bind $win.texte <KeyRelease> "::devel::updateProcSearch %A %W $win"
		
		listbox $win.l -listvariable listProc -font splainf -bg white \
			-height 90 -width 30 -yscrollcommand "$win.listbox_scroll set"
		#-height 90 -width 30 -yscrollcommand "$win.listbox_scroll set"
		pack $win.l -side left
		scrollbar $win.listbox_scroll -command "$win.l yview" -width 16 -highlightthickness 0
		pack $win.listbox_scroll -side left -fill y

		bind $win.l <Double-B1-ButtonRelease> "::devel::onProcDoubleClick $win"
		
		# Draw the text widget.
		text $win.t -background white -yscrollcommand "$win.scroll set" \
			-width 70 -height 100 -wrap word -font splainf -highlightthickness 0
		#-width 70 -height 100 -wrap word -font LucidaGrande -highlightthickness 0 
		scrollbar $win.scroll -command "$win.t yview" -width 16
		pack $win.scroll -side right -fill y
		pack $win.t -expand yes -fill both
		
		# Set up the view in the listbox and text widget.
		#log "win: $win"
		setCommandValue $win "Please choose a proc from the list on the left."
		#setCommandsList $win [lsort -dictionary [info procs "::*"]]
		log "setting procs in list"
		setCommandsList $win $procs 0
		log "procs in list"
	}
	proc updateProcSearch { char w win } {
		variable procs
		$win.l delete 1 end
		set char [$win.texte get]
		#log "updateVarSearch: $win"
		setCommandsList $win [lsearch -all -inline $procs "*$char*"]
	}
	proc onProcDoubleClick { win } {
		set proc1 [$win.l get active]
		set txt "proc $proc1 { [info args $proc1] } {[info body $proc1]}"
		::devel::setCommandValue $win $txt
	}
	

#####################################################################
#
# Mem stats
#
#
#####################################################################
	proc buildMemStats { win } {
		global tcl_platform tk_patchLevel tcl_patchLevel
		
		set frm [ frame $win.sysamsn ]
		label $frm.tcl -text "aMSN version: "
		label $frm.tclv -text "$::version from $::date"
		pack $frm.tcl -side left -anchor w -fill both
		pack $frm.tclv -side left -anchor w
		pack $frm -side top -expand true -fill x
		
		set frm [ frame $win.systcltk ]
		label $frm.tcl -text "TCL/TK version: "
		label $frm.tclv -text "$tcl_patchLevel $tk_patchLevel"
		pack $frm.tcl -side left -anchor w -fill both
		pack $frm.tclv -side left -anchor w
		pack $frm -side top -expand true -fill x
		
		set frm [ frame $win.systclplateforme ]
		label $frm.tcl -text "Tcl platform: "
		label $frm.tclv -text "[array get tcl_platform]"
		pack $frm.tcl -side left -anchor w -fill both
		pack $frm.tclv -side left -anchor w
		pack $frm -side top -expand true -fill x
		
		set frm [ frame $win.statstclcmd ]
		label $frm.tcl -text "Number of TCL Commands: "
		label $frm.tclv -text "[llength [info commands ::* ]]"
		pack $frm.tcl -side left -anchor w -fill both
		pack $frm.tclv -side left -anchor w
		pack $frm -side top -expand true -fill x
		
		set frm [ frame $win.statstnr ]
		label $frm.tcl -text "	-> Number invoked: "
		label $frm.tclv -text "[llength [info cmdcount	]]"
		pack $frm.tcl -side left -anchor w -fill both
		pack $frm.tclv -side left -anchor w
		pack $frm -side top -expand true -fill x

		set frm [ frame $win.statstglobals ]
		label $frm.tcl -text "Nr of global vars: "
		label $frm.tclv -text "[llength [info globals ::* ]]"
		pack $frm.tcl -side left -anchor w -fill both
		pack $frm.tclv -side left -anchor w
		pack $frm -side top -expand true -fill x

		set frm [ frame $win.statspackageload ]
		label $frm.tcl -text "Packages loaded with 'load': "
		label $frm.tclv -text "[llength [info loaded]]"
		pack $frm.tcl -side left -anchor w -fill both
		pack $frm.tclv -side left -anchor w
		pack $frm -side top -expand true -fill x

		set frm [ frame $win.statspackagerequire ]
		label $frm.tcl -text "Packages loaded with package require: "
		label $frm.tclv -text "[llength [package names]]"
		pack $frm.tcl -side left -anchor w -fill both
		pack $frm.tclv -side left -anchor w
		pack $frm -side top -expand true -fill x

		set frm [ frame $win.statsimg ]
		label $frm.tcl -text "Number of images: "
		label $frm.tclv -text "[llength [image names]]"
		pack $frm.tcl -side left -anchor w -fill both
		pack $frm.tclv -side left -anchor w
		pack $frm -side top -expand true -fill x

		#pixmaps
		set frm [ frame $win.statspixmaps ]
		label $frm.tcl -text "Loaded pixmaps: "
		label $frm.tclv -text "[llength [array names ::skin::loaded_pixmaps]]"
		pack $frm.tcl -side left -anchor w -fill both
		pack $frm.tclv -side left -anchor w
		pack $frm -side top -expand true -fill x


		set frm [ frame $win.statstpix ]
		label $frm.tcl -text "Pixmap names: "
		label $frm.tclv -text "[llength [array names ::skin::pixmaps_names]]"
		pack $frm.tcl -side left -anchor w -fill both
		pack $frm.tclv -side left -anchor w
		pack $frm -side top -expand true -fill x

		set frm [ frame $win.imgnames ]
		label $frm.tcl -text "Images names: "
		label $frm.tclv -text "[llength [image names]]"
		pack $frm.tcl -side left -anchor w -fill both
		pack $frm.tclv -side left -anchor w
		pack $frm -side top -expand true -fill x

	}

#####################################################################
#
#
#
#
#####################################################################
	proc plugins { win } {
		# array that will hold information of plugins
		variable plugins
		# the variable that holds the path to the selection window
		variable w
		# list of all the loaded plugins
		#variable loadedplugins
		# array that holds info about currently selected plugin
		variable selection
		# the path to the frame where are displayed pieces of information for a plugin
		variable mF

		# clear the selection
		set selection ""
		# set the window path
		set w $win

		# update the information and list of plugins
		::plugins::updatePluginsArray
		# create window and give it it's title
		#toplevel $w
		#wm title $w [trans pluginselector]
		#wm geometry $w 500x400
		# create widgets
		# listbox with all the plugins
		listbox $w.plugin_list -background "white" -height 15 -yscrollcommand "$w.ys set" -relief flat -highlightthickness 0
		scrollbar $w.ys -command "$w.plugin_list yview"

		#Scrollableframe that will contain pieces of information about a plugin
		ScrolledWindow $w.sw
		ScrollableFrame $w.sw.sf -areaheight 0 -areawidth 0
		$w.sw setwidget $w.sw.sf
		set mF [$w.sw.sf getframe]

		# holds the plugins info like name and description
		label $mF.name_title -text [trans name] -font sboldf
		label $mF.name	-wraplength 280
		label $mF.version_title -text [trans version] -font sboldf
		label $mF.version
		label $mF.author_title -text [trans author] -font sboldf
		label $mF.author	-wraplength 280
		label $mF.desc_title -text [trans description] -font sboldf
		# TODO make the -wraplength fit the label's width
		label $mF.desc -wraplength 280 -justify left -anchor w
		# holds the 'command center' buttons
		label $w.getmore -text "[trans getmoreplugins]" -fg #0000FF

		button $w.load -text "[trans load]" -command "::plugins::GUI_Load" -state disabled
		button $w.config -text "[trans configure]" -command "::plugins::GUI_Config" ;#-state disabled
		button $w.close -text [trans close] -command "::plugins::GUI_Close"

		#loop through all the plugins and add them to the list
		foreach {plugin} [lsort -dictionary [array names ::plugins::plugins *_name]] {
				set name $::plugins::plugins(${plugin})
				# add the plugin name to the list at counterid position
				$w.plugin_list insert end $name
				# if the plugin is loaded, color it one color. otherwise use other colors
				#TODO: Why not use skins?
				if {[lsearch "$::plugins::loadedplugins" $::plugins::plugins(${name}_name)] != -1} {
					$w.plugin_list itemconfigure end -background #DDF3FE
				} else {
					$w.plugin_list itemconfigure end -background #FFFFFF
				}
		}
		if {[$w.plugin_list size] > "15"} {
			$w.plugin_list configure -height [$w.plugin_list size]
		}
		#do the bindings
		bind $w.plugin_list <<ListboxSelect>> "::devel::GUI_NewSel"
		#bind $w <<Escape>> "::plugins::GUI_Close"
		pack $w.plugin_list -fill both -side left
		pack $w.ys -fill both -side left
		pack $mF.name_title -padx 5 -anchor w
		pack $mF.name -padx 5 -anchor w
		pack $mF.version_title -padx 5 -anchor w
		pack $mF.version -padx 5 -anchor w
		pack $mF.author_title -padx 5 -anchor w
		pack $mF.author -padx 5 -anchor w
		pack $mF.desc_title -padx 5 -anchor w
		pack $mF.desc -anchor nw -expand true -fill x -padx 5
		pack $w.sw -anchor w -side top -expand true -fill both
		pack $w.getmore -side top -anchor e -padx 5
		bind $w.getmore <Enter> "$w.getmore configure -font sunderf"
		bind $w.getmore <Leave> "$w.getmore configure -font splainf"
		set lang [::config::getGlobalKey language]
		bind $w.getmore <ButtonRelease> "launch_browser $::weburl/plugins.php?lang=$lang"

		pack $w.close $w.config $w.load -padx 5 -pady 5 -side right -anchor se

	}

	proc GUI_NewSel { } {
		# window path
		variable w
		# selection array
		variable selection
		# plugins' info
		variable plugins
		# the loaded plugins
		#variable loadedplugins
		#set loadedplugins $::plugins::loadedplugins
		# the path to the frame where are displayed pieces of information for a plugin
		variable mF

		# find the id of the currently selected plugin
		if { [ $w.plugin_list curselection ] == "" } {
			return
		}
		set selection [$w.plugin_list get [$w.plugin_list curselection]]
		# if the selection is empty, end proc
		if { $selection == "" } {
			return
		}

		# update the description
		$mF.name configure -text $selection
		$mF.author configure -text [::plugins::getInfo $selection author]
		$mF.version configure -text [::plugins::getInfo $selection plugin_version]
		$mF.desc configure -text [::plugins::getInfo $selection description]

		# update the buttons

		$w.config configure -state normal

		if {[lsearch "$::plugins::loadedplugins" $selection] != -1 } {
			# if the plugin is loaded, enable the Unload button and update the colors
			$w.load configure -state normal -text [trans unload] -command "::plugins::GUI_Unload"
			$w.plugin_list itemconfigure [$w.plugin_list curselection] -background #DDF3FE

			# if the plugin has a configlist, then enable configuration.
			# Otherwise disable it
			if {[info exists ::[::plugins::getInfo $selection plugin_namespace]::configlist] == 1} {
				$w.config configure -state normal
			} else {
				$w.config configure -state disabled
			}
		} else { # plugin is not loaded
			# enable the load button and disable config button and update color
			$w.load configure -state normal -text "[trans load]" -command "::plugins::GUI_Load"
			$w.plugin_list itemconfigure [$w.plugin_list curselection] -background #FFFFFF
			$w.config configure -state disabled
		}

	}



	proc UpdateAllPlugins {} {
		foreach { plugin } [ ::plugins::getPlugins ] {
			::plugins::UpdatePlugin $plugin
		}
	}

#####################################################################
#
#	dock
#
#
#####################################################################
	proc dock { win } {
		set win [ frame $win.dock ]
		label $win.txt -text "Enable dock :"
		button $win.loaddock -text "[trans load]" -command "init_dock"
		label $win.txt2 -text "Disable dock :"
		button $win.closedock -text "[trans unload]" -command "close_dock"

		pack $win.txt $win.loaddock -padx 10 -side left -anchor nw
		pack $win.txt2 $win.closedock -padx 10 -side left -anchor nw
		pack $win -side left -expand true -fill both

	}

#####################################################################
#
#	packages
#	resquested by Billiob
#
#####################################################################
	proc packages { win } {
		listbox $win.l -font splainf -bg white \
			-height 90 -width 30 -yscrollcommand "$win.listbox_scroll set"
		#-height 90 -width 30 -yscrollcommand "$win.listbox_scroll set"
		pack $win.l -side left
		scrollbar $win.listbox_scroll -command "$win.l yview" -width 16 -highlightthickness 0
		pack $win.listbox_scroll -side left -fill y

		#bind $win.l <Double-B1-ButtonRelease> "::devel::onProcDoubleClick $win"
		bind $win.l <Double-B1-ButtonRelease> "::devel::onPackDoubleClick $win"
		
		# Draw the text widget.
		text $win.t -yscrollcommand "$win.scroll set" \
			-width 70 -height 100 -wrap word -font splainf -highlightthickness 0
		#-width 70 -height 100 -wrap word -font LucidaGrande -highlightthickness 0 
		scrollbar $win.scroll -command "$win.t yview" -width 16
		pack $win.scroll -side right -fill y
		pack $win.t -expand yes -fill both
		
		# Set up the view in the listbox and text widget.
		setCommandValue $win "Please choose a package from the list on the left."
		setCommandsList $win [lsort -dictionary [package names]]
	}
	proc onPackDoubleClick { win } {
		variable packloaded
		set pack1 [$win.l get active]
		#log "pack is $pack1"
		set loaded "Not Loaded"

		if { [lsearch $packloaded [string tolower $pack1]] != -1 } {
			set loaded "Loaded"
		}
		set version [package versions $pack1]
		set txt "$pack1 $version $loaded"
		::devel::setCommandValue $win $txt
	}
#####################################################################
#
#	Images
#	resquested by Billiob
#
#####################################################################
	proc images { win } {
		listbox $win.l -font splainf -bg white \
			-height 90 -width 30 -yscrollcommand "$win.listbox_scroll set"
		#-height 90 -width 30 -yscrollcommand "$win.listbox_scroll set"
		pack $win.l -side left
		scrollbar $win.listbox_scroll -command "$win.l yview" -width 16 -highlightthickness 0
		pack $win.listbox_scroll -side left -fill y

		#bind $win.l <Double-B1-ButtonRelease> "::devel::onProcDoubleClick $win"
		bind $win.l <Double-B1-ButtonRelease> "::devel::onPixDoubleClick $win"
		
		# Draw the text widget.
		label $win.t -width 70 -height 100 -highlightthickness 0
		#-width 70 -height 100 -wrap word -font LucidaGrande -highlightthickness 0 
		scrollbar $win.scroll -command "$win.t yview" -width 16
		pack $win.scroll -side right -fill y
		pack $win.t -expand yes -fill both
		
		# Set up the view in the listbox and text widget.
		#setCommandValue $win "Please choose an image from the list on the left."
		setCommandsList $win [lsort -dictionary [image names]]
	}
	proc onPixDoubleClick { win } {
		set img [$win.l get active]
		set txt "$img"
		::devel::setImgValue $win $txt
	}
	################################################################
	# ::acv::_updateReadOnlyTextBox(textItemPath, newText)
	# Updates a read only text box item.
	# Arguments:
	# - textItemPath => The path to the text box item.
	# - newText => The text to replace the current text with.
	proc _updateImg {textItemPath newText} {
		${textItemPath} configure -state normal
		${textItemPath} configure -image $newText
	}
	
	################################################################
	# ::acv::setCommandValue(newDescription)
	# Set the value of the text box to newDescription.
	# Arguments:
	#	 - newDescription => A string with the value of the current command.
	proc setImgValue {win newDescription} {
		#upvar 1 win $win
		_updateImg $win.t $newDescription
	}
#####################################################################
#
#	Pixmap
#	resquested by Billiob
#
#####################################################################
	proc pixmaps { win } {
		listbox $win.l -font splainf -bg white \
			-height 90 -width 30 -yscrollcommand "$win.listbox_scroll set"
		#-height 90 -width 30 -yscrollcommand "$win.listbox_scroll set"
		pack $win.l -side left
		scrollbar $win.listbox_scroll -command "$win.l yview" -width 16 -highlightthickness 0
		pack $win.listbox_scroll -side left -fill y

		#bind $win.l <Double-B1-ButtonRelease> "::devel::onProcDoubleClick $win"
		bind $win.l <Double-B1-ButtonRelease> "::devel::onImgDoubleClick $win"
		
		# Draw the text widget.
		label $win.t -width 70 -height 100 -highlightthickness 0
		#-width 70 -height 100 -wrap word -font LucidaGrande -highlightthickness 0 
		scrollbar $win.scroll -command "$win.t yview" -width 16
		pack $win.scroll -side right -fill y
		pack $win.t -expand yes -fill both
		
		# Set up the view in the listbox and text widget.
		#setCommandValue $win "Please choose an image from the list on the left."
		setCommandsList $win [lsort -dictionary [array names ::skin::loaded_pixmaps]]
	}
	proc onImgDoubleClick { win } {
		set img [$win.l get active]
		set txt [::skin::loadPixmap $img]
		::devel::setImgValue $win $txt
	}
#####################################################################
#
#
#
#
#####################################################################
	proc svnGetVersion { win } {
		global program_dir
		#status_log "devel: program_dir is $program_dir"
		set data "Unable to fetch data"
		catch { set data [ exec svn info $program_dir ] } svnerr
		label $win.svninfot -text "Svn version: "
		label $win.svninfov -text "$data"
		pack $win.svninfot $win.svninfov -side top -anchor nw
		pack $win -side top -expand true -fill both
		
	}
	proc svnUpdate { win } {
		set svn [open "| svn co https://svn.sourceforge.net/svnroot/amsn/trunk/amsn" r]
		fileevent $svn readable "::devel::getinput $if $win"
	}
	proc getinput {channel win} {
		$win.svntext insert end [gets $channel]
	}

#####################################################################
#
#	config
#
#
#####################################################################
	#proc config { win } {
	#	button $win.genProc -text "[trans genproc]" -command "::devel::generateProcList $win"
	#	button $win.genPack -text "[trans genpack]" -command "::devel::generatePackageList $win"
	#	label $win.status -text "[trans status]"
	#	pack $win.genProc
	#	pack $win.genPack
	#	pack $win.status
	#	pack $win
	#}

	proc generatePackageList { win } {
		variable packloaded
		set $packloaded [list]
		foreach {packa} [lsort -dictionary [info loaded]] {
			lappend packloaded [string tolower [lindex $packa 1]]
		}
	}

	proc generateProcList { win } {
		variable procs
		set procs [list]
		#set namespaces [list]
		#lappend namespaces "::"
		#foreach {n} [namespace children "::"] {
		#	lappend namespaces $n
		#	#log "get namespace $n"
		#	#lappend namespaces [recursiveNamespace $n]
		#}
		#log "getting procs ::"
		foreach {p} [lsort -dictionary [info procs "::*"]] {
			if { $win != "" } {
				$win.status configure -text "status: $p"
			}
			lappend procs $p
		}
		#log "getting namespace childrens"
		foreach {n} [lsort -dictionary [namespace children "::"]] {
			#log "getting proc for namespace $n"
			foreach {p} [lsort -dictionary [info procs "${n}::*"]] {
				lappend procs $p
				if { $win != "" } {
					$win.status configure -text "status: $p"
				}
			}
		}
		if { $win != "" } {
			$win.status configure -text "status: done"
		}
		#log "procs done"
		#set procs [lsort -dictionary $procs]
		#foreach {p} {
		#	if { $p != "" } {
		#		#log "checking $p"
		#		foreach {pr} [info procs "${p}::*"] {
		#			#lappend procs [info procs "${p}::*"]
		#			lappend procs $pr
		#		}
		#	} else {
		#		log "Oops: get empty namespace ?!"
		#	}
		#}
		#log "procs: $procs"
	}

	proc console { win } {
	#	variable console
	#	log "win is $win"
	#	global tk_library
	#	#interp delete
	#	set consoleInterp [interp create $console]
	#	$consoleInterp eval [list set tk_library $tk_library]
	#	$consoleInterp alias exit exit
	#	load "" Tk $consoleInterp
	#	
	#	if {[package vsatisfies [package provide Tk] 4]} {
	#	   $consoleInterp alias interp consoleinterp
	#	} else {
	#	   $consoleInterp alias consoleinterp consoleinterp
	#	}
	#	## 4. Bind the <Destroy> event of the application interpreter's main
	#	##    window to kill the console (via tkConsoleExit)
	#	#bind . <Destroy> [list +if {[string match . %W]} [list catch \
	#	#       [list $consoleInterp eval tkConsoleExit]]]
	#	#
	#	## 5. Redefine the Tcl command 'puts' in the application interpreter
	#	##    so that messages to stdout and stderr appear in the console.
	#	## 6. No matter what Tk_Main says, insist that this is an interactive  shell
	#	#set tcl_interactive 1
	#	#########################################################################
	#	## Evaluate the Tk library script console.tcl in the console interpreter
	#	#########################################################################
	#	##$consoleInterp eval source [list [file join $tk_library console.tcl]]
	#	#$consoleInterp eval {
	#	#   if {![llength [info commands tkConsoleExit]]} {
	#	#       tk::unsupported::ExposePrivateCommand tkConsoleExit
	#	#   }
	#	#}
	#	#$consoleInterp eval {
	#	#   if {![llength [info commands tkConsoleOutput]]} {
	#	#       tk::unsupported::ExposePrivateCommand tkConsoleOutput
	#	#   }
	#	#}
	#	#if {[string match 8.3.4 $tk_patchLevel]} {
	#	#   # Workaround bug in first draft of the tkcon enhancments
	#	#   $consoleInterp eval {
	#	#       bind Console <Control-Key-v> {}
	#	#   }
	#	#}
	#	## Restore normal [puts] if console widget goes away...
	#	#$consoleInterp alias Oc_RestorePuts Oc_RestorePuts $consoleInterp
	#	#$consoleInterp eval {
	#	#    bind Console <Destroy> +Oc_RestorePuts
	#	#}
	#	#
	#	#unset consoleInterp
	#
	}

	#proc console {consoleInterp win sub {optarg {}}} [subst -nocommands {
	#    switch -exact -- \$sub {
	#       title {
#		   $consoleInterp eval wm title . [list \$optarg]
#	       }           
#	       hide {      
#		   $consoleInterp eval wm withdraw .
#	       }   
#	       show {  
#		   $consoleInterp eval wm deiconify .
#	       }   
#	       eval {
#		   $consoleInterp eval \$optarg
#	       }   
#	       default {
#		   error "bad option \\\"\$sub\\\": should be hide, show, or title"
#	       }   
#	   }           
#	}]

	proc logs { win } {
	}
#####################################################################
#
#	About
#
#
#####################################################################
	proc about { win } {
		label $win.warn1	-text "Warning, you can modify EVERY amsn's var."
		label $win.warn2	-text "This can damage your amsn's installation"
		label $win.warn3	-text "Use with caution.\n\n"
		label $win.about1 -text "Plugin written by Yoda-BZH"
		label $win.about2 -text "yodabzh@gmail.com"
		pack $win.warn1 $win.warn2 $win.warn3 $win.about1 $win.about2 -side top -anchor nw
		pack $win -side top -expand true -fill both
	}

#####################################################################
#
#
#
#
#####################################################################
	proc log { txt } {
		status_log "Devel: $txt"
		plugins_log Devel "$txt"
	}
}



