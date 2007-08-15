#
#
# Issues with pixmapmenu:
# - Not all menus are menubars. Can't we do this better (automatically instead of checking
#   whether pixmapmenu is enabled each time a menu is created)?
#
# - "enable_pixmapmenu ; disable_pixmapmenu ; enable_pixmapmenu" goes wrong, enabling the
#   second time results in some problem with contentmanager (attachment ... already exists)
#   -->> contentmanager add attachment ... in utils/pixmapmenu/pixmapmenu.tcl
#
#

package require Tk

namespace eval ::chameleon {
  variable chameleon_dir

  variable THEMELIST
  variable THEMES
  variable WR_WIDGETS

  array set WR_WIDGETS {
    Button	button
    CheckButton	checkbutton
    ComboBox	combobox::combobox
    Entry	entry
    Frame	frame
    Label	label
    LabelFrame	labelframe
    MenuButton	menubutton
    NoteBook	NoteBook
    RadioButton	radiobutton
    Scrollbar	scrollbar
  }

  # number of times a button/checkbutton/radiobutton should flash when the command 'flash' is invoked
  variable flash_count 10

  variable wrapped 0
  variable wrapped_procs
  variable wrapped_into
  variable wrapped_shortname

  #proc ::NoteBook { args } { return [eval ::NoteBook::create $args] }

  array set wrapped_into {
    NoteBook		notebook
    button		button
    checkbutton		checkbutton
    combobox::combobox	combobox
    entry		entry
    frame		frame
    label		label
    labelframe		labelframe
    menubutton		menubutton
    radiobutton		radiobutton
    scrollbar		scrollbar
  }

  array set wrapped_shortname {
    NoteBook		notebook
    button		button
    checkbutton		checkbutton
    combobox::combobox	combobox
    entry		entry
    frame		frame
    label		label
    labelframe		labelframe
    menubutton		menubutton
    radiobutton		radiobutton
    scrollbar		scrollbar
  }

  #      X means it is supported by Chameleon
  #      - means it is not yet supported by Chameleon
  #
  #     *List of Tk/Tile widgets :
  # -     scale
  # X     frame
  # X     button
  # X     labelframe
  # X     label
  # X     radiobutton
  # X     checkbutton
  # X     entry
  # X     menubutton
  # X     scrollbar
  # 
  #     *List of renamed widgets :
  # -    panedwindow => paned
  # -    ::dkfprogress => progressbar
  # -    tk_dialog/tk_messageBox => dialog
  # X    ::combobox::combobox => combobox
  # X    NoteBook => notebook
  # X	 menu => pixmapmenu
  #
  #
  #     *List non native Tile widgets :
  #     separator 
  #     treeview
  #    
  #     *List of non supported Tk widgets
  #     canvas 
  #     listbox
  #     message 
  #     spinbox
  #     text
  #     tk_popup
  #     toplevel


  proc DebugPrint { msg } {
    variable debug_proc

    if {[info exists debug_proc] && $debug_proc ne "" } {
      catch { eval $debug_proc $msg}
    }
  }

  proc SetDebugProc { pr } {
    variable debug_proc $pr
  }

  ################################################
  # Init( dir )                                  #
  #  Registration & initialization of the plugin #
  ################################################
  proc InitFromAmsn { dir } {
    ::plugins::RegisterPlugin Chameleon

    SetDebugProc [list plugins_log Chameleon]

    # Load language files
    set langdir	[file join $dir "lang"]
    set lang	[::config::getGlobalKey language]

    load_lang en	$langdir
    load_lang $lang	$langdir
    
    if {[catch {package require pixmapmenu}]} {
      msg_box [trans need_pixmapmenu]

      ::plugins::GUI_Unload

      return 0
    }

    if { [catch {InitChameleon $dir} res] } {
      msg_box [trans $res]

      ::plugins::GUI_Unload

      return 0
    }
  }

  proc translate { msg } {
    if { [info exists trans] } {
      return [trans $msg]
    } else {
      return $msg
    }
  }

  proc InitChameleon { dir } {
    variable chameleon_dir
    variable THEMELIST
    variable THEMES
    variable WR_WIDGETS

    # Avoid having 100s of $dir in auto_path, in case user loads/unloads plugin many times..
    if { [lsearch $::auto_path $dir] == -1  } {
      lappend ::auto_path $dir
    }

    # This forces an update of the available packages list.
    # let's hope it will fix the problem on Mac where the tile extension is not found
    # if placed in the plugin's dir.
    eval [package unknown] Tcl [package provide Tcl]

    if {[catch {package require tile 0.7}]} {
      msg_box [trans need_tile_extension]

      ::plugins::GUI_Unload

      return 0
    }

    if {[catch {package require pixmapmenu}]} {
      msg_box [trans need_pixmapmenu]

      ::plugins::GUI_Unload

      set ::auto_path $autopath

      error need_tile_extension
    }

    foreach package [info loaded] {
      foreach {lib name} $package break

      if {$name eq "Tile" } {
	set tile_dir [file dirname $lib]
      }
    }

    if { [info exists tile_dir] } {
      # Avoid having 100s of $dir in auto_path, in case user loads/unloads plugin many times..
      if { [lsearch $::auto_path $tile_dir] == -1  } {
	lappend ::auto_path $tile_dir
      }

      if { [lsearch $::auto_path [file join $tile_dir demos]] == -1  } {
	lappend ::auto_path [file join $tile_dir demos]
      }

      if { [lsearch $::auto_path [file join $tile_dir themes]] == -1  } {
	lappend ::auto_path [file join $tile_dir themes]
      }

      if { [lsearch $::auto_path [file join $dir themes]] == -1  } {
	lappend ::auto_path [file join $dir themes]
      }
    }

    # This forces an update of the available packages list.
    # It's required for package names to find the themes in demos/themes/*.tcl
    eval [package unknown] Tcl [package provide Tcl]

    # Use tile::defaultTheme to get the default theme for this platform 
    if { [info exists ::Chameleon_cfg(theme)] } {
      set ::chameleon::config(theme) [set ::Chameleon_cfg(theme)]
    } else {
      set ::chameleon::config(theme) [set ::tile::defaultTheme]
    }
    
    foreach widget [array names WR_WIDGETS] {
      if { [info exists ::Chameleon_cfg(wrap_$widget)] } {
	set ::chameleon::config(wrap_$widget) [set ::Chameleon_cfg(wrap_$widget)]
      } else {
	set ::chameleon::config(wrap_$widget) 1
      }
    }

    # Enable pixmapmenu
    set ::chameleon::config(enable_pixmapmenu) 0

    set THEMELIST {
      alt		"Revitalized"
      aqua		"Aqua"
      classic		"Classic"
      default		"Default"
      winnative		"Windows native"
      xpnative		"XP Native"
    }

    array unset THEMES
    array set THEMES $THEMELIST;

    # Add in any available loadable themes:
    foreach name [tile::availableThemes] {
      if {![info exists THEMES($name)]} {
	lappend THEMELIST $name [set THEMES($name) [string totitle $name]]
      }
    }

    set ::chameleon::configlist [list \
				   [list frame ::chameleon::PopulateThemesFrame ""] \
				   [list frame ::chameleon::PopulateWidgetsFrame ""] \
				   [list frame ::chameleon::PopulateMenuFrame ""]]
    set chameleon_dir $dir

    # Initialization of the needed wrapped alternatives
    catch { 
      package require BWidget
      NoteBook::use

      package require pixmapscroll
    }

    ::chameleon::SetTheme  $::chameleon::config(theme) 1

    # need to reset the theme at idle so the option add will actually be effective!
    after idle {::chameleon::WrapAndSetTheme  $::chameleon::config(theme) 1}
  }

  proc DeInitChameleon { } {
    variable defaultBgColor 
    variable lastSetBgColor 

    unwrap 

    option add *background $defaultBgColor

    RecursivelySetBgColor . $defaultBgColor

    set lastSetBgColor $defaultBgColor
  }

  proc WrapAndSetTheme {theme {reset_defaultBg 0}} {
    SetTheme $theme $reset_defaultBg

    rewrap 
  }

  proc SetTheme {theme {reset_defaultBg 0}} {
    variable defaultBgColor 
    variable lastSetBgColor 

    DebugPrint "Setting theme to $theme"

    if { ![info exists defaultBgColor] || $reset_defaultBg} {
      set defaultBgColor [option get . background Toplevel]
    }

    if { ![info exists lastSetBgColor] } {
      set lastSetBgColor $defaultBgColor
    }

    # TODO find a way to get the tile's frame's background more efficiently
    tile::setTheme $theme

    switch -- $theme {
      "winnative"	{ set bgcolor "#d6d3ce" }
      "xpnative"	{ set bgcolor "#ece9d8" }
      "step"		{ set bgcolor "#a0a0a0" }
      "clam"		{ set bgcolor "#dcdad5" }
      "aqua"		{ set bgcolor "#ececec" }
      "alt"		-
      "classic"		-
      default		{ set bgcolor "#d9d9d9" }
    }

    if {[style default . -background] ne "" } {
      set bgcolor [style default . -background]
    }

    if {![catch {tk windowingsystem} wsystem] && $wsystem eq "aqua"} {
      return
    }

    option add *background $bgcolor

    RecursivelySetBgColor . $bgcolor

    set lastSetBgColor $bgcolor
  }

  proc RecursivelySetBgColor { w color } {
    variable defaultBgColor 
    variable lastSetBgColor

    if {[info commands $w] ne "" && [winfo toplevel $w] eq $w} {
      catch {
	if { [$w cget -background] eq $defaultBgColor || 
	     [$w cget -background] eq $lastSetBgColor} {
	  $w configure -background $color
	}
      }
    } else { 
      # Detect a canvas widget and change bg of canvas from ScrollableFrame 
      # as it's path is $w:cmd it doesn't seem to appear in [winfo children]
      if { ![catch {$w cget -confine}] } {
	if { [$w cget -background] eq $defaultBgColor || 
	     [$w cget -background] eq $lastSetBgColor} {
	  $w configure -background $color
	}
      } elseif { ![catch {${w}:cmd cget -confine}] } {
	if { [$w cget -background] eq $defaultBgColor || 
	     [$w cget -background] eq $lastSetBgColor} {
	  ${w}:cmd configure -background $color
	}
      }
    }

    foreach child [winfo children $w] {
      RecursivelySetBgColor $child $color
    }
  }

  proc ConfigureChameleon { } {
    set win .chameleon_config
    toplevel $win

    set themes $win.themes
    set widgets $win.widgets
    set buttons $win.buttons
    frame $themes
    frame $widgets 
    frame $buttons

    array set old_config [array get ::chameleon::config]

    PopulateThemesFrame $themes
    PopulateWidgetsFrame $widgets
    
    ::ttk::button $buttons.ok -text "Ok" -command "::chameleon::rewrap; destroy $win"
    ::ttk::button $buttons.cancel -text "Cancel" -command "array set ::chameleon::config [list [array get old_config]]; ::chameleon::SetTheme  \$::chameleon::config(theme); destroy $win"
    pack $themes $widgets -expand true -fill both -side top
    pack $buttons -expand false -fill both -side bottom
    pack  $buttons.ok $buttons.cancel -expand false -fill both -side right
  }

  proc PopulateMenuFrame { win } {
    set pmenu $win.pmenu

    ::ttk::labelframe $pmenu -text [translate experimental]
    set b [::ttk::checkbutton $pmenu.enablepixmapmenu \
	     -text [translate enable_pixmapmenu] \
	     -variable ::chameleon::config(enable_pixmapmenu)]
    pack $b -side top -expand false -fill x

    pack $pmenu -expand true -fill both
  }

  proc PopulateWidgetsFrame { win } {
    variable WR_WIDGETS 

    set widgs $win.widgs

    ::ttk::labelframe $widgs -text [translate widgets_to_wrap]

    DebugPrint "$widgs"

    foreach w_name [array names WR_WIDGETS] {
	set b [::ttk::checkbutton $widgs.wrap$w_name	\
		   -text	$w_name \
		   -variable	::chameleon::config(wrap_$w_name)]

      pack $b -side top -expand false -fill x
    }

    pack $widgs -expand true -fill both
  }

  proc PopulateThemesFrame { win } {
    variable THEMELIST
    variable THEMES

    set themes $win.themes

    ::ttk::labelframe $themes -text [translate theme]

    DebugPrint "$themes"

    foreach {theme name} $THEMELIST {
      set b [::ttk::radiobutton $themes.s$theme	\
	   -text	$name \
	   -variable	::chameleon::config(theme) -value $theme \
	   -command	[list chameleon::SetTheme $theme]]

      pack $b -side top -expand false -fill x

      if {[lsearch -exact [package names] tile::theme::$theme] == -1} {
	$themes.s$theme state disabled
      }
    }

    pack $themes -expand true -fill both

    bind $win <Destroy> {::chameleon::WrapAndSetTheme $::chameleon::config(theme)}
  }


  proc rewrap { } {
    unwrap 
    wrap 
  }

  proc wrap { } {
    variable wrapped

    if {!$wrapped} {
      return [wrap_or_unwrap 0]
    }
  }

  proc unwrap { } {
    variable wrapped

    if {$wrapped} {
      return [wrap_or_unwrap 1]
    }
  }

  proc wrap_or_unwrap {{revert 0}} {
    global pixmapmenu_enabled

    variable WR_WIDGETS
    variable chameleon_dir
    variable tk_widget_type
    variable ttk_widget_type
    variable widget_type
    variable wrapped
    variable wrapped_into
    variable wrapped_procs
    variable wrapped_shortname

    DebugPrint "In wrap $revert"

    if {$revert} {
      if {!$wrapped} {
	error "can't revert the wrapping : must wrap before"
      }

      foreach command $wrapped_procs {
	set tk_widget_type	$command
	set ttk_widget_type	[set wrapped_into($command)]
	set widget_type		[set wrapped_shortname($command)]


	if { [info commands ::tk::$tk_widget_type] eq "::tk::$tk_widget_type" && 
	     [info procs ::$tk_widget_type] eq "::$tk_widget_type" } {
	  DebugPrint "Unwrapping $tk_widget_type"

	  rename ::$tk_widget_type	""
	  rename ::tk::$tk_widget_type	::$tk_widget_type
	} else {
	  DebugPrint "Not unwrapping $tk_widget_type"
	  DebugPrint "Because of : [info command ::tk::$tk_widget_type] - [info procs ::$tk_widget_type]"
	}
      }

      catch { destroy .chameleon_events_messages }

      if { [info commands ::tk::button2] ne "" } {
	rename ::tk::button2 button
      }

      set wrapped 0
    } else {
      if {$wrapped} {
	error "can't wrap : already wrapped"
      }

      set wrapped_procs [list]

      foreach w_name [array names WR_WIDGETS] {
	if { [info exists ::chameleon::config(wrap_$w_name)] && 
	     [set ::chameleon::config(wrap_$w_name)] == 1 } {
	  lappend wrapped_procs [set WR_WIDGETS($w_name)]
	}
      }

      # pixmapmenu
      if {[info exists ::chameleon::config(enable_pixmapmenu)] && 
	  [set ::chameleon::config(enable_pixmapmenu)] && 
	  [info exists pixmapmenu_enabled] && ! $pixmapmenu_enabled} {
	enable_pixmapmenu
      } elseif {!$::chameleon::config(enable_pixmapmenu)} {
	DebugPrint "Not enabling pixmapmenu because disabled in config."
      } elseif {![info exists pixmapmenu_enabled]} {
	DebugPrint "Not enabling pixmapmenu because pixmapmenu_enabled var does not exist."
      } else {
	DebugPrint "Not enabling pixmapmenu because pixmapmenu already enabled."
      }

      foreach command $wrapped_procs {
	set tk_widget_type	$command
	set ttk_widget_type	$wrapped_into($command)
	set widget_type		$wrapped_shortname($command)

	source [file join $chameleon_dir common.tcl]
	source [file join $chameleon_dir $widget_type.tcl]

	if { [info commands ::tk::$tk_widget_type] eq "" && [info commands ::$tk_widget_type] eq "::$tk_widget_type" } {
	  DebugPrint "Wrapping $tk_widget_type"

	  rename ::$tk_widget_type ::tk::$tk_widget_type

	  proc ::$tk_widget_type {w args} "set newargs \[list \$w\]; eval lappend newargs \$args; eval ::chameleon::${widget_type}::$widget_type \$newargs"
	} else {
	  DebugPrint "Not wrapping $tk_widget_type"
	  DebugPrint "Because of : [info command ::tk::$tk_widget_type] - [info command ::$tk_widget_type] - [info procs ::$tk_widget_type] - [info procs ::tk::$tk_widget_type]"
	}
      }

      if { $::chameleon::config(theme) == "tileqt" } {
	# tileqt doesn't honor -relief flat so we run the workaround
	catch { ::buttons2labels }
      }

      set wrapped 1
    }
  }

  proc widgetCreated { w w_name } {
    variable lastCreatedWidget
    variable widget2window

    set lastCreatedWidget $w
    set widget2window($w) $w_name

    generateEvent <<WidgetCreated>>
  }

  proc generateEvent { event } {
    variable listeners

    if { [info exists listeners($event)] } {
      set list [set listeners($event)]

      foreach script $list { 
	  # Equivalent to eval
	if 1 $script
      }
    }
  }

  proc getLastCreatedWidget { } {
    variable lastCreatedWidget

    if {[info exists lastCreatedWidget]} {
      return $lastCreatedWidget
    }

    return ""
  }

  proc getWidgetPath { w } {
    variable widget2window

    if { [info exists widget2window($w)]} {
      return $widget2window($w)
    }

    return ""
  }

  proc widgetDestroyed { w } {
    variable lastDestroyedWidget

    set widg [getWidgetPath $w]

    catch {rename ::$w  ""}
    catch {rename $widg ""}

    set lastDestroyedWidget $w

    array unset widget2window $w

    generateEvent <<WidgetDestroyed>>
  }

  proc getLastDestroyedWidget { } {
    variable lastDestroyedWidget

    if {[info exists lastDestroyedWidget] } {
      return $lastDestroyedWidget
    }

    return ""
  }

  proc addBinding { event script } {
    variable listeners

    if { [info exists listeners($event)] } {
      set list [set listeners($event)]

      if { [lsearch $list $script] == -1} {
	lappend listeners($event) $script
      }
    } else {
      set listeners($event) [list $script]
    }
  }

  proc ::chameleon::copyStyle { widget_type a_dest options} {
    set src	[widgetToStyle $widget_type $a_dest $options]
    set dest	"$a_dest.$src"

    #Copy parameters from one style to another
    eval [list style configure $dest] [style configure $src]

    #eval style layout $dest \{[style layout $src]\}
    #eval style map $dest [style map $src]

    return $dest
  }

  proc ::chameleon::widgetToStyle { widget_type dest options } {
    set src ""

    if {$widget_type eq "scrollbar" } {
      if { [catch {$dest cget -orient} orientation]} {
	array set opt $options

	if { [info exists opt(-orient)] } { 
	  set orientation $opt(-orient)
	} else {
	  set orientation "vertical"
	}
      }

      append src [string toupper [string range $orientation 0 0]]
      append src [string range $orientation 1 end]
      append src "."
    }

    append src "T"
    append src [string toupper [string range $widget_type 0 0]]
    append src [string range $widget_type 1 end]

    return $src
  }

  proc printStackTrace { } {
    for { set i [info level] } { $i > 0 } { incr i -1} { 
      puts "Level $i : [info level $i]"
      puts "Called from within : "
    }

    puts ""
  }
}

package provide Chameleon 0.6
