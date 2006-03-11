namespace eval ::chameleon::notebook {

   proc notebook_customParseConfArgs {w parsed_options args } {
     	array set options $args
	array set ttk_options $parsed_options

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
	    -font -styleOption
	    -activebackground -styleOption
	    -activeforeground -styleOption
	    -background -styleOption
	    -bg -styleOption
	    -borderwidth  -styleOption
	    -bd	 -styleOption
	    -disabledforeground	 -styleOption
	    -foreground -styleOption
	    -fg	 -styleOption
	    -repeatdelay -ignore
	    -repeatinterval -ignore
	    -arcradius  -ignore
	    -height  -ignore
	    -homogeneous -ignore
	    -side -ignore
	    -tabbevelsize -ignore
	    -width -toImplement
	    -ibd -ignore
	    -internalborderwidth -ignore
	    -tabpady -ignore
	}


	# ignoring -width because we need to map 0 to "" and "" to 0 in cget/configure
	
 	array set notebook_widgetCommands {
	    bindtabs {1 {notebook_bindtabs $w $args}} 
	    compute_size {3 {notebook_compute_size $w $args}}
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

	::chameleon::addBinding <<WidgetCreated>> {::chameleon::notebook::notebook_widgetCreated}
	::chameleon::addBinding <<WidgetDestroyed>> {::chameleon::notebook::notebook_widgetDestroyed}

    }

   proc notebook_widgetCreated { } {
       set nb [::chameleon::getLastCreatedWidget]
       if {[string first "notebook" $nb] == 0 } {
	   puts "Notebook $nb is created"
	   ::ttk::notebook::enableTraversal [::chameleon::getWidgetPath $nb]
	   bind $nb <<NotebookTabChanged>> "::chameleon::notebook::notebook_tabChanged $nb"
       }
   }

   proc notebook_widgetDestroyed { } {
       variable pages

       set nb [::chameleon::getLastDestroyedWidget]
       if {[string first "notebook" $nb] == 0 } {
	   puts "Notebook $nb is destroyed"
	   array unset pages [::chameleon::getWidgetPath $nb]
       }
   }

   proc notebook_tabChanged { w } {
       #FIXME
      puts "Tab changed on $w to : [$w index current]"
   }

    proc notebook_customCget { w option } {

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

   proc notebook_compute_size { w } {
       set max_w 0
       set max_h 0

       update idletasks 

       foreach child [winfo children [::chameleon::getWidgetPath $w]] {
	   set reqw    [winfo reqwidth  $child]
	   set reqh    [winfo reqheight $child]
	   set max_w [expr {$reqw > $max_w ? $reqw : $max_w}]
	   set max_h [expr {$reqh > $max_h ? $reqh : $max_h}] 
       }

       notebook_configure $w -width $max_w -height $max_h
   }

   proc notebook_delete { w page {destroyframe 1}} {
       set tab [notebook_getframe $w $page]
       $w forget $tab

       if {$destroyframe} {
	   destroy $tab
       }

       array unset tabs $page      
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
       variable pageOptions

       set w_name [notebook_commandToWidget $w]
       if {![info exists pages($w_name)] } {
	   set pages($w_name) [list]
       }
       array set tabs [set pages($w_name)]

       if {[info exists tabs($page)] } {
	   error "Page $page already exists in notebook $w_name"
       }
      
       array set arguments $args

       
       set pageOptions($w:$page) $args

       array unset arguments -createcmd
       array unset arguments -leavecmd
       array unset arguments -raisecmd
   
       set child [frame $w_name.$page]
       set tabs($page) [list [$w index end] $child]

       set pages($w_name) [array get tabs]
       set ret [eval $w add $child [array get arguments]]
       notebook_move $w $page $index

       if {[info exists arguments(-createcmd)] } {
	   after 100 "$arguments(-createcmd)"
       }

       return $ret
   }
  

   proc notebook_itemCget {w page option } {
       variable pageOptions

       if {$option == "-createcmd" ||
	   $option == "-leavecmd" ||
	   $option == "-raisecmd" } {
	   array set opts [set pageOptions($w:$page)]
	   if {[info exists opts($option)] } {
	       return [set opts($option)]
	   } else {
	       return ""
	   }
       } else {
	   return [$w tab $option]
       }
   }

   proc notebook_itemConfigure { w page args } {
       variable pageOptions

       if {[llength $args] == 0 } {
	   array set arguments {
	       -createcmd ""
	       -leavecmd ""
	       -raisecmd ""
	   }
	   array set arguments [set pageOptions($w:$page)]
	   array set arguments [$w tab [notebook_getFrameIndex $w $page]]
	   return [array get arguments]
       } elseif {[llength $args] == 1} {
	   return [notebook_itemCget $w $page $args]
       } else {
	   array set arguments $args

	   set pageOptions($w:$page) $args
	   array unset arguments -createcmd
	   array unset arguments -leavecmd
	   array unset arguments -raisecmd
   
	   return [eval $w tab [array get arguments]]
       }

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
           set pageIdx [$w index current]
       } else {
           set pageIdx [notebook_getFrameIndex $w $page]
	   $w select $pageIdx
       }
       return [notebook_getPageAt $w $pageIdx]
   }

   proc notebook_see { w page } {
    
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
	       array unset tabs $name
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
       return [::chameleon::getWidgetPath $w]
   }

}
