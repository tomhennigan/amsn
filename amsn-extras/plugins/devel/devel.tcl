

namespace eval ::devel {
	variable develwin
	
	proc InitPlugin { dir } {
		variable develwin
		#RegisterPlugin
		::plugins::RegisterPlugin "Devel"

		#Register events
		#::devel::RegisterEvent
		#Set default values for config
		::devel::ConfigArray
		#Add items to configure window
		::devel::ConfigList
		set develwin ".develwin"
		if {![catch {tk windowingsystem} wsystem] && $wsystem == "aqua"} {
			bind . <Option-d> ::devel::drawMainWindow
		} else {
			bind . <Alt-d> ::devel::drawMainWindow
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
		moveinscreen $develwin 100
	}

	proc buildForms { } {
		variable develwin

		frame $develwin.nb -class Degt

		set develNb $develwin.nb

		NoteBook $develNb.nn

		$develNb.nn insert end varlist -text "Var list"
		$develNb.nn insert end varsearch -text "Vars"
		$develNb.nn insert end procs -text "Procs"
		$develNb.nn insert end plugins -text "Plugins"
		$develNb.nn insert end memstats -text "Memory"
		$develNb.nn insert end about -text "[trans about]"


		#  .------.
		# _| list |_____________
		set frm [ $develNb.nn getframe varlist]
		ScrolledWindow $frm.sw
		ScrollableFrame $frm.sw.sf -constrainedwidth 1
		$frm.sw setwidget $frm.sw.sf
		pack $frm.sw -anchor n -side top -expand true -fill both
		
		set frm [ $frm.sw.sf getframe ]
		::devel::buildFormList $frm

		$develNb.nn compute_size
		[$develNb.nn getframe varlist].sw.sf compute_size


		#  .--------.
		# _| search |______
		set frm [$develNb.nn getframe varsearch]
		ScrolledWindow $frm.sw
		ScrollableFrame $frm.sw.sf -constrainedwidth 1
		$frm.sw setwidget $frm.sw.sf
		pack $frm.sw -anchor n -side top -expand true -fill both
		set frm [ $frm.sw.sf getframe ]
		::devel::buildFormSearch $frm

		$develNb.nn compute_size
		[$develNb.nn getframe varsearch ].sw.sf compute_size

		#  .---------.
		# _| procs   |____________
		set frm [$develNb.nn getframe procs]
		ScrolledWindow $frm.sw
		ScrollableFrame $frm.sw.sf -constrainedwidth 1
		$frm.sw setwidget $frm.sw.sf
		pack $frm.sw -anchor n -side top -expand true -fill both
		set frame [ $frm.sw.sf getframe ]
		foreach { procs } [ lsort [info procs ::cmsn*] ] {
			set procsname [string map {:: _} $procs]
			set frm [frame $frame.p$procsname]
			button $frm.button -text $procs -command $procs
			pack $frm.button -side left -anchor w -fill x
			pack $frm -fill x -side top -expand true
		}
		pack $frame -side top -fill x -expand true
		$develNb.nn compute_size
		[$develNb.nn getframe procs ].sw.sf compute_size


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
		ScrolledWindow $frm.sw
		ScrollableFrame $frm.sw.sf -constrainedwidth 1
		$frm.sw setwidget $frm.sw.sf
		pack $frm.sw -anchor n -side top -expand true -fill both
		set frm [ $frm.sw.sf getframe ]
		
		::devel::plugins $frm

		$develNb.nn compute_size
		[$develNb.nn getframe plugins].sw.sf compute_size

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

		bind $develwin <<Escape>> "destroy $develwin"
		#pack $frm.save $frm.cancel -side right -padx 10 -pady 10
		pack $frm.close -side right -padx 10 -pady 10
		pack $frm -side bottom -fill x
		
		
		# fin, compactage
		$develNb.nn raise varlist
		pack $develNb.nn -expand true -fill both
		pack $develwin.nb -side bottom -fill both -expand true -padx 5 -pady 5
	}

	proc buildFormList { win } {
		set frm [ frame $win.list ]

		foreach { key } [ lsort [ ::config::getKeys ] ] {
			set frame [frame $frm.f$key]
			::devel::drawKeyVal $frame $key
		}
		pack $frm -side top -fill both -expand true
	}

	proc buildFormSearch { win } {
		set frm [ frame $win.search]
		set frmb [frame $win.box]

		set defaultSearch "*"

		entry $frm.texte -bg white -textvariable defaultSearch
		label $frm.textl -text "var :"
		button $frm.btn -text "Search" -command [list ::devel::searchFor "$frm.texte" "$frmb.box"]

		# todo: faire en sorte que quand on appuie sur enter ça lance la recherche
		#bind $frm.btn <Return> [list ::devel::searchFor "$frm.text" "$frmb.box" ]

		pack $frm.textl -anchor w -side left -padx 40
		pack $frm.texte -anchor w -side left -fill x
		pack $frm.btn -anchor w -side left -fill x
		pack $frm -fill x

		# result list box
		listbox $frmb.box -background white -yscrollcommand "$frmb.scroll set"
		scrollbar $frmb.scroll -command "$frmb.box yview" -borderwidth 1
		pack $frmb.box -side left -anchor w -pady 0 -padx 0 -expand true -fill both
		pack $frmb.scroll -side left -anchor w -pady 0 -padx 0 -fill y
		pack $frmb -side top -expand true -fill x


		# variable edit box
		# partie en dessous, qui permettera de modifier la var
		set frmr [ frame $win.res ]
		label $frmr.textl
		entry $frmr.texte -bg white 
		pack $frmr.textl -anchor w -side left 
		pack $frmr.texte -anchor w -side left -fill x
		pack $frmr
		
		
		bind $frmb.box <Double-1> [list ::devel::searchShowVar $frmb.box $frmr]
	}

	proc searchShowVar { lb res } {
		$res.textl configure -text [$lb get [$lb curselection]]
		$res.texte configure -textvariable [::config::getVar [$lb get [$lb curselection]]]
	}

	proc getKey { key } {
		return [ array get ::config "*$key*" ]
	}

	proc getVar { key } {
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

	proc savePrefs { } {
		#variable develwin
		#set frm "$develwin.nb.nn.fvarlist.sw.sf.frame.list"
                #
		#foreach { key } [ lsort [ ::config::getKeys ] ] {
                #        set frame $frm.f$key
		#	set confKey [ $frame.varl cget -text ]
		#	set confVal [ $frame.vare get ]
		#	#status_log "$key : [::config::getKey $key] : $confKey : $confVal"
		#	if { $confVal != [::config::getKey $key] } {
		#		status_log "saving $key: [::config::getKey $key] -> $confVal" red
		#	}
                #}

	}

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
		label $frm.tcl -text "  -> Number invoked: "
		label $frm.tclv -text "[llength [info cmdcount  ]]"
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

	proc plugins { win } {
		NoteBook $win.nn
		#set firstplugin ""
		
		# 1ère section, générale
		$win.nn insert end general -text "General"
		set f [ $win.nn getframe general ]
		ScrolledWindow $f.sw
		ScrollableFrame $f.sw.sf -constrainedwidth 1
		$f.sw setwidget $f.sw.sf
		pack $f.sw -anchor n -side top -expand true -fill both
		set frm [ $f.sw.sf getframe ]
		label $frm.label -text "general"
		button $frm.updateall -text "Update all plugins" -command "::devel::UpdateAllPlugins"
		pack $frm.label -side left -anchor w -fill y 
		pack $frm.updateall -anchor w -side left -fill x
		pack $frm -side top -expand true -fill both
		$win.nn compute_size
		[$win.nn getframe general].sw.sf compute_size

		# on parcourt les plugins
		foreach { pluginname } [lsort [::plugins::getPlugins]] {
			set plugin [ string map {" " ""} $pluginname]
			#if { "$firstplugin" == "" } {
			#	set firstplugin $plugin
			#}
			$win.nn insert end $plugin -text "$plugin"
			set f [ $win.nn getframe $plugin ]
			ScrolledWindow $f.sw
			ScrollableFrame $f.sw.sf -constrainedwidth 1
			$f.sw setwidget $f.sw.sf
			pack $f.sw -anchor n -side top -expand true -fill both

			set frm [ $f.sw.sf getframe ]
			label $frm.label -text "$plugin"
			pack $frm.label -side left -anchor w -fill both -expand true
			pack $frm -side top -expand true -fill both

			#on vérifie si le plugin est chargé ou non
			if {[lsearch "$::plugins::loadedplugins" "$pluginname"] != -1 } {
				set status "loaded"
			} else {
				set status "unloaded"
			}
			label $frm.status -text "Status: $status"
			pack $frm.status -side left -anchor w -fill both
			pack $frm -side top -expand true -fill x

			# les boutons load et unload
			button $frm.btnload -text [trans load] -command "::plugins::LoadPlugin {$pluginname}"
			button $frm.btnunload -text [trans unload] -command "::plugins::UnLoadPlugin {$pluginname}"
			pack $frm.btnload $frm.btnunload -anchor w -side left -fill both
			pack $frm -side top -expand true -fill x

			# on compacte le tout
			$win.nn compute_size
			[$win.nn getframe $plugin].sw.sf compute_size
		}

		$win.nn raise general
		pack $win.nn -expand true -fill both
	}

	proc UpdateAllPlugins {} {
		foreach { plugin } [ ::plugins::getPlugins ] {
			::plugins::UpdatePlugin $plugin
		}
	}

	proc about { win } {
		label $win.warn1  -text "Warning, you can modify EVERY amsn's var."
		label $win.warn2  -text "This can damage your amsn's installation"
		label $win.warn3  -text "Use with caution.\n\n"
		label $win.about1 -text "Plugin written by Yoda-BZH"
		label $win.about2 -text "yodabzh@gmail.com"
		pack $win.warn1 $win.warn2 $win.warn3 $win.about1 $win.about2 -side left -anchor w
		pack $win -side top -expand true -fill x
	}
}



