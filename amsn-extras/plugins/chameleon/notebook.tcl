namespace eval ::chameleon::notebook {

   proc notebook_customParseConfArgs { parsed_options args } {
     	array set options $args
	array set ttk_options $parsed_options

 	if { [info exists options(-bd)] } {
 	    set ttk_options(-padding) $options(-bd)
 	}
 	set padx 0
 	if { [info exists options(-padx)] &&
 	     [string is digit -strict $options(-padx)]  } {
 	    set padx $options(-padx)
 	}
 	set pady 0
 	if { [info exists options(-pady)] &&
 	     [string is digit -strict $options(-pady)] } {
 	    set pady $options(-pady)
 	}
 	if {$padx == 0 && $pady == 0 && 
 	    [info exists options(-bd)] } {
 	    set ttk_options(-padding) $options(-bd)
 	} else {
 	    if {$padx == 0 && $pady != 0 } {
 		set ttk_options(-padding) [list 2 $pady]
 	    } elseif {$padx != 0 && $pady == 0 } {
 		set ttk_options(-padding) [list $padx 2]
 	    } elseif {$padx != 0 && $pady != 0 } {
 		set ttk_options(-padding) [list $padx $pady]
 	    }
 	}

       if { [info exists options(-width)] } {
	   if {$options(-width) == 0} {
	       set ttk_options(-width) [list]
	   } else {
	       set ttk_options(-width) $options(-width)
	   }
       }

	return [array get ttk_options]
    }

    proc init_notebookCustomOptions { } {
 	variable notebook_widgetOptions
 	variable notebook_widgetCommands 

 	array set notebook_widgetOptions {
	    -font -ignore
	    -activebackground -ignore
	    -activeforeground -ignore	
	    -background -ignore
	    -bg -ignore
	    -borderwidth  -ignore
	    -bd	 -ignore
	    -disabledforeground	 -ignore
	    -foreground -ignore
	    -fg	 -ignore
	    -repeatdelay -ignore
	    -repeatinterval -ignore
	    -arcradius  -ignore
	    -height  -ignore
	    -homogeneous -ignore
	    -side -ignore
	    -tabbevelsize -ignore
	    -width -ignore
	    -ibd -ignore
	    -internalborderwidth -ignore
	    -tabpady -ignore
	}


	# ignoring -width because we need to map 0 to "" and "" to 0 in cget/configure
	
 	array set notebook_widgetCommands {
	    bindtabs {1 {notebook_bindtabs $w $args}} 
	    compute_size {3 {}}
	    delete {1 {notebook_delete $w $args}}
	    getframe {1 {notebook_getframe $w $args}}
	    index {3 {notebook_index $w $args}}
	    insert {3 {notebook_insert $w $args}}
	    itemcget {3 {notebook_itemCget $w $args}}
	    itemconfigure {3 {notebook_itemConfigure $w $args}}
	    move {1 {notebook_move $w $args}}
	    page {4 {notebook_page $w $args}}
	    pages {5 {notebook_pages $w $args}}
	    raise {1 {notebook_raise $w $args}}
	    see {3 {notebook_see $w $args}}
	    
	    add {1 {notebook_add $w $args}}
	    forget {1 {notebook_forget $w $args}}
	    select {3 {notebook_select $w $args}}
	    tab {3 {notebook_tab $w $args}}
	    tabs {4 {notebook_tabs $w $args}}
	}

#	::chameleon::createBinding <<Chameleon_WidgetCreated>> {::chameleon::notebook::notebook_widgetCreated $w}

    }

    proc notebook_customCget { w option } {
	set padding [$w cget -padding]
	if { [llength $padding] > 0 } {
 	    set padx [lindex $padding 0]
 	    set pady [lindex $padding 1]
	}
	if { $option == "-padx" && [info exists padx] } {
	    return $padx
	}
	if { $option == "-pady" && [info exists pady] } {
	    return $pady
	}
	if {$option == "-width"} {
	    set width [$w cget -width]
	    if {![string is digit -strict $width]} {
		return 0
	    } else {
		return $width
	    }
	}

	return ""
    }

   proc notebook_bindtabs { w event script } {
       #TODO
   }

   proc notebook_delete { w page {destroyframe 1}} {
       set tab [notebook_getframe $w $page]
       $w forget $tab

       if {$destroyframe} {
	   destroy $tab
       }

       array unset tabs($page)      
   }
   
   proc notebook_getframe { w page } {
       return [lindex [notebook_getPageInfo $w $page] 1]
   }

   proc notebook_index {w page_or_index} {
       if { [catch {set tab [notebook_getframe $w $page_or_index]}] } {
	   return [$w index $page_or_index]
       } else {
	   return [$w index $tab]
       }
   }
   
   proc notebook_insert {w index page args} {
       variable pages

       set w_name [notebook_commandToWidget $w]
       if {![info exists pages($w_name)] } {
	   set pages($w_name) [list]
       }
       array set tabs [set pages($w_name)]

       if {[info exists tabs($page)] } {
	   error "Page $page already exists in notebook $w_name"
       }
      
       #FIXME
       array set arguments $args

       array unset arguments(-createcmd)
       array unset arguments(-leavecmd)
       array unset arguments(-raisecmd)
   
       set child [frame $w_name.$page]
       set tabs($page) [list [$w index end] $child]

       set pages($w_name) [array get tabs]
       return [eval $w add $child [array get arguments]]
   }
  

   proc notebook_itemCget {w page option } {
 	variable notebook_frameOptions

       if {$option == "-createcmd" ||
	   $option == "-leavecmd" ||
	   $option == "-raisecmd" } {
	   return ""
       } else {
	   return [$w tab $option]
       }

       #FIXME

	if {![info exists notebook_frameOptions] } {
	    init_notebookFrameOptions
	}

	if { ![info exists notebook_frameOptions($option)]} {
	    error "Unknown option \"$name\""
	}

      if {[set notebook_frameOptions($option)] == "-ignore" } {
	   set value [eval [notebook_getOriginal] cget $option]
       } else {
	    set value [eval $w cget $option]
       } 
   }
   proc init_notebookFrameOptions { } {
       variable notebook_frameOptions

       array set notebook_frameOptions {
       }

   }

   proc notebook_itemConfigure { w page args } {
       if {[llength $args] == 0 } {
	   array set arguments {
	       -createcmd ""
	       -leavecmd ""
	       -raisecmd ""}
	   array set arguments [$w tab [notebook_getFramIndex $w $page]]
	   return [array get arguments]
       } elseif {[llength $args] == 1} {
	   return [notebook_itemCget $w $page $args]
       } else {
	   array set arguments $args

	   array unset arguments(-createcmd)
	   array unset arguments(-leavecmd)
	   array unset arguments(-raisecmd)
   
	   return [eval $w tab [array get arguments]]
       }

       #FIXME
   }

   proc notebook_move { w page index } {
       #TODO
   }

   proc notebook_page { w first {last ""} } {
       return [notebook_pages $w $first $last]
   }

   proc notebook_pages { w {first ""} {last ""} } {
       set tabs [$w tabs]
       if { $first == "" } {
	   return $tabs
       } elseif {$last == "" } {
	   return [lrange $tabs $first end]
       } else {
	   return [lrange $tabs $first $last]
       }
   }

   proc notebook_raise { w {page ""} } {
       if {$page == "" } {
	   return [$w index current]
       } else {
	   return [$w select [notebook_getFrameIndex $w $page]]
       }
   }

   proc notebook_see { w page } {
       #TODO
   }


   proc notebook_add { w child args} {
       variable pages

       set w_name [notebook_commandToWidget $w]
       if {![info exists pages($w_name)] } {
	   set pages($w_name) [list]
       }
       array set tabs [set pages($w_name)]

       set page $child
       set i 1
       while {![info exists tabs($page)] } {
	   set page "${child}#${i}"
	   incr i
       }
      
       set tabs($page) [list [$w index end] $child]

       set pages($w_name) [array get tabs]
       return [eval $w add $child $args]
         
   }

   proc notebook_forget { w index } {
       variable pages

       set w_name [notebook_commandToWidget $w]
       if {![info exists pages($w_name)] } {
	   set pages($w_name) [list]
       }
       array set tabs [set pages($w_name)]

       foreach name [array names tabs] {
	   foreach {idx frame} $tabs($name) break
	   if {$idx == $index} {
	       array unset tabs($name)
	       set pages($w_name) [array get tabs]
	       return [$w forget $index]
	   }
       }
      
       error "Unable to find tab with index $index"
   }

   proc notebook_select { w index } {
       return [$w select $index]
   }

   proc notebook_tab { w index args } {
       return [eval $w tab $index $args]
   } 

   proc notebook_tabs { w } {
       return [$w tabs]
   }
       

   proc notebook_getPageAt { w index } {
        variable pages
       
       set w_name [notebook_commandToWidget $w]
       if {![info exists pages($w_name)] } {
	   set pages($w_name) [list]
       }
       array set tabs [set pages($w_name)]
       
       foreach name [array names tabs] {
	   foreach {idx frame} $tabs($name) break
	   if {$idx == $index} {
	       return $name
	   }
       }
      
       return [lindex [set tabs($page)] 0]
   }

   proc notebook_getPageInfo { w page } {
       variable pages
       
       set w_name [notebook_commandToWidget $w]
       if {![info exists pages($w_name)] } {
	   set pages($w_name) [list]
       }

       array set tabs [set pages($w_name)]
       if {![info exists tabs($page)] } {
	   error "Unknown page $page for notebook $w"
       }
      
       return [set tabs($page)]
   }

   proc notebook_getFrameIndex { w page } {
       return [lindex [notebook_getPageInfo $w $page] 0]
   }

   proc notebook_commandToWidget {w} {
       return [string range $w 14 end]
   }

}