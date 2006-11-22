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
namespace eval ::chameleon {

      variable plugin_dir

      variable THEMELIST 
      variable THEMES
      variable WR_WIDGETS 
      array set WR_WIDGETS [list Frame frame \
                                Button button \
                                NoteBook NoteBook \
                                LabelFrame labelframe \
                                Label label \
                                RadioButton radiobutton \
                                CheckButton checkbutton \
                                Entry entry \
                                MenuButton menubutton \
                                Scrollbar scrollbar \
                                ComboBox combobox::combobox]

      variable flash_count 10

      variable wrapped 0
      variable wrapped_procs
      variable wrapped_into
      variable wrapped_shortname

      #proc ::NoteBook { args } { return [eval ::NoteBook::create $args] }

      array set wrapped_into [list frame frame \
                                  button button  \
                                  NoteBook notebook \
                                  labelframe labelframe \
                                  label label \
                                  radiobutton radiobutton \
                                  checkbutton checkbutton \
                                  scrollbar scrollbar \
                                  entry entry \
                                  combobox::combobox combobox \
                                  menubutton menubutton]

      array set wrapped_shortname [list button button \
                                       frame frame \
                                       NoteBook notebook \
                                       labelframe labelframe \
                                       label label \
                                       radiobutton radiobutton \
                                       checkbutton checkbutton \
                                       scrollbar scrollbar \
                                       entry entry \
                                       combobox::combobox combobox \
                                       menubutton menubutton]



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



      ################################################
      # Init( dir )                                  #
      #  Registration & initialization of the plugin #
      ################################################
      proc Init { dir } {
              variable plugin_dir
              variable THEMELIST
              variable THEMES
              variable WR_WIDGETS

              ::plugins::RegisterPlugin Chameleon

              # Load language files
              set langdir [file join $dir "lang"]
              set lang [::config::getGlobalKey language]
              load_lang en $langdir
              load_lang $lang $langdir

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
                      set ::auto_path $autopath
                      return 0
              }

			  if {[catch {package require pixmapmenu}]} {
				msg_box [trans need_pixmapmenu]
				::plugins::GUI_Unload
				set ::auto_path $autopath
				return 0
			  }

              foreach package [info loaded] { 
                      foreach {lib name} $package break
                      if {$name == "Tile" } {
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
              set ::chameleon::config(theme) [set ::tile::defaultTheme]
              foreach widget [array names WR_WIDGETS] {
                      set ::chameleon::config(wrap_$widget) 0
              }

			  # Enable pixmapmenu
			  set ::chameleon::config(enable_pixmapmenu) 0

              set THEMELIST {
                      default         "Default"
                      classic         "Classic"
                      alt             "Revitalized"
                      winnative       "Windows native"
                      xpnative        "XP Native"
                      aqua    "Aqua"
              }

              array unset THEMES
              array set THEMES $THEMELIST;

              # Add in any available loadable themes:
              #
              foreach name [tile::availableThemes] {
                      if {![info exists THEMES($name)]} {
                              lappend THEMELIST $name [set THEMES($name) [string totitle $name]]
                      }
              }

              set ::chameleon::configlist [list \
				[list frame ::chameleon::populateframe ""] \
				[list frame ::chameleon::populateframe2 ""] \
				[list frame ::chameleon::populateframe3 ""]]
              set plugin_dir $dir

              if { [info exists ::Chameleon_cfg(theme)] } {
                      SetTheme $::Chameleon_cfg(theme)
              } else {
                      SetTheme $::chameleon::config(theme)
              }



              # Initialization of the needed wrapped alternatives
              catch { 
                      package require AMSN_BWidget
                      package require pixmapscroll
                      NoteBook::use
              }

              ::chameleon::SetTheme  $::chameleon::config(theme) 1

              # need to reset the theme at idle so the option add will actually be effective!
              after idle {::chameleon::WrapAndSetTheme  $::chameleon::config(theme) 1}
      }

      proc DeInit { } {
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

              plugins_log "Chameleon" "Setting theme to $theme"
              if { ![info exists defaultBgColor] || $reset_defaultBg} {
                      set defaultBgColor [option get . background Toplevel]
              }
              if { ![info exists lastSetBgColor] } {
                      set lastSetBgColor $defaultBgColor
              }

              # TODO find a way to get the tile's frame's background more efficiently
              tile::setTheme $theme
              switch -- $theme {
                      "winnative" { set bgcolor \#d6d3ce }
                      "xpnative" { set bgcolor \#ece9d8}
                      "step" { set bgcolor \#a0a0a0 }
                      "clam" { set bgcolor \#dcdad5 }
                      "aqua" { set bgcolor \#ececec }
                      "alt" -
                      "classic" -
                      default  { set bgcolor \#d9d9d9 }

              }
              if {[style default . -background] != "" } {
                      set bgcolor [style default . -background]
              }

              if {![catch {tk windowingsystem} wsystem] && $wsystem == "aqua"} {
                      return
              }

              option add *background $bgcolor
              RecursivelySetBgColor . $bgcolor

              set lastSetBgColor $bgcolor
      }
      proc RecursivelySetBgColor { w color } {
              variable defaultBgColor 
              variable lastSetBgColor

              if {[info commands $w] != "" && [winfo toplevel $w] == $w} {
                      catch {
                              if { [$w cget -background] == $defaultBgColor ||
                                   [$w cget -background] == $lastSetBgColor} {
                                      $w configure -background $color
                              }
                      }
              } else { 
                      # Detect a canvas widget and change bg of canvas from ScrollableFrame 
                      # as it's path is $w:cmd it doesn't seem to appear in [winfo children]
                      if { ![catch {$w cget -confine}] } {
                              if { [$w cget -background] == $defaultBgColor ||
                                   [$w cget -background] == $lastSetBgColor} {
                                      ${w} configure -background $color
                              }
                      } elseif { ![catch {${w}:cmd cget -confine}] } {
                              if { [$w cget -background] == $defaultBgColor ||
                                   [$w cget -background] == $lastSetBgColor} {
                                      ${w}:cmd configure -background $color
                              }
                      }
              }
              foreach child [winfo children $w] {
                      RecursivelySetBgColor $child $color
              }
      }

	  proc populateframe3 { win } {
		set pmenu $win.pmenu

		::ttk::labelframe $pmenu -text [trans experimental]
		set b [::ttk::checkbutton $pmenu.enablepixmapmenu \
			-text [trans enable_pixmapmenu] \
			-variable ::chameleon::config(enable_pixmapmenu)]
		pack $b -side top -expand false -fill x

		pack $pmenu -expand true -fill both
	  }

      proc populateframe2 { win } {
              variable WR_WIDGETS 

              set widgs $win.widgs

              ::ttk::labelframe $widgs -text [trans widgets_to_wrap]
              plugins_log "Chameleon" "$widgs"
              foreach w_name [array names WR_WIDGETS] {
                      set b [::ttk::checkbutton $widgs.wrap$w_name -text $w_name \
                                 -variable ::chameleon::config(wrap_$w_name)]
                      pack $b -side top -expand false -fill x
              }

              pack $widgs -expand true -fill both
      }

      proc populateframe { win } {
              variable THEMELIST
              variable THEMES

              set themes $win.themes

              ::ttk::labelframe $themes -text [trans theme]
              plugins_log "Chameleon" "$themes"
              foreach {theme name} $THEMELIST {
                      set b [::ttk::radiobutton $themes.s$theme -text $name \
                                 -variable ::chameleon::config(theme) -value $theme \
                                 -command [list chameleon::SetTheme $theme]]
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
              if {$wrapped == 0 } {
                      return [wrap_or_unwrap 0]
              }
      }
      proc unwrap { } {
              variable wrapped
              variable wrapped
              if {$wrapped == 1 } {
                      return [wrap_or_unwrap 1]
              }
      }

      proc wrap_or_unwrap {{revert 0}} {
              global pixmapmenu_enabled
              variable wrapped
              variable wrapped_procs
              variable wrapped_into
              variable wrapped_shortname
              variable plugin_dir
              variable widget_type
              variable ttk_widget_type
              variable tk_widget_type
              variable WR_WIDGETS

              plugins_log "Chameleon" "In wrap $revert"
              if {$revert == 1 } {
                      if {$wrapped == 0 } {
                              error "can't revert the wrapping : must wrap before"
                      }

                      foreach command $wrapped_procs {
                              set tk_widget_type $command
                              set ttk_widget_type [set wrapped_into($command)]
                              set widget_type [set wrapped_shortname($command)]


                              if { [info commands ::tk::${tk_widget_type}] == "::tk::${tk_widget_type}" && 
                                   [info procs ::${tk_widget_type}] == "::${tk_widget_type}" } {
                                      plugins_log "Chameleon" "Unwrapping ${tk_widget_type}"
                                      rename ::${tk_widget_type} ""
                                      rename ::tk::${tk_widget_type} ::${tk_widget_type}
                              } else {
                                      plugins_log "Chameleon" "Not unwrapping ${tk_widget_type}"
                                      plugins_log "Chameleon" "Because of : [info command ::tk::${tk_widget_type}] - [info procs ::${tk_widget_type}]"
                              }


                      }

                      catch { destroy .chameleon_events_messages }
                      set wrapped 0

              } else {
                      if {$wrapped == 1 } {
                              error "can't wrap : already wrapped"
                      }
                      set wrapped_procs [list]

                      foreach w_name [array names WR_WIDGETS] {
                              if { $::chameleon::config(wrap_$w_name) == 1 } {
                                      lappend wrapped_procs [set WR_WIDGETS($w_name)]
                              }
                      }
					  # pixmapmenu
					  if {$::chameleon::config(enable_pixmapmenu) && \
						  [info exists pixmapmenu_enabled] && \
                          ! $pixmapmenu_enabled} {
						enable_pixmapmenu
					  } elseif {! $::chameleon::config(enable_pixmapmenu)} {
						plugins_log "Chameleon" "Not enabling pixmapmenu because disabled in config."
					  } elseif {! [info exists pixmapmenu_enabled]} {
						plugins_log "Chameleon" "Not enabling pixmapmenu because pixmapmenu_enabled var does not exist."
					  } else {
						plugins_log "Chameleon" "Not enabling pixmapmenu because pixmapmenu already enabled."
					  }


                      foreach command $wrapped_procs {
                              set tk_widget_type $command
                              set ttk_widget_type [set wrapped_into($command)]
                              set widget_type [set wrapped_shortname($command)]

                              source [file join $plugin_dir common.tcl]
                              source [file join $plugin_dir ${widget_type}.tcl]


                              if { [info commands ::tk::${tk_widget_type}] == "" && 
                                   [info commands ::${tk_widget_type}] == "::${tk_widget_type}" } {
                                      plugins_log "Chameleon" "Wrapping ${tk_widget_type}"
                                      rename ::${tk_widget_type} ::tk::${tk_widget_type}
                                      proc ::${tk_widget_type} {w args} "set newargs \[list \$w\]; eval lappend newargs \$args; eval ::chameleon::${widget_type}::${widget_type} \$newargs"
                              } else {
                                      plugins_log "Chameleon" "Not wrapping ${tk_widget_type}"
                                      plugins_log "Chameleon" "Because of : [info command ::tk::${tk_widget_type}] - [info command ::${tk_widget_type}] - [info procs ::${tk_widget_type}] - [info procs ::tk::${tk_widget_type}]"
                              }
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
                              eval $script
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
              catch {rename ::$w ""}
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



      proc ::chameleon::copyStyle { widget_type dest options} {

              set src [widgetToStyle $widget_type $dest $options]

              append dest ".$src"

              #Copy parameters from one style to another
              eval [list style configure $dest] [style configure $src]
              #eval style layout $dest \{[style layout $src]\}
              #eval style map $dest [style map $src]

              return $dest
      }

      proc ::chameleon::widgetToStyle { widget_type dest options } {
              set src ""
              if {$widget_type == "scrollbar" } {
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
              append src [string toupper [string range ${widget_type} 0 0]]
              append src [string range ${widget_type} 1 end]

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


