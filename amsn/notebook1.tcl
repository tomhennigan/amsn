#
# Notebook - version 1.1
#
#   This is a DYNAMIC notebook widget which you can delete the
# middle page without any bugs.
#
#      Commands:
# notebook:create $window $args 
#   This creates a new window. Arguments are the same as notebook:configure.
#
# notebook:configure $window $args
#   This is for configuring a notebook. Arguments:
#
#       -pappend $pagename   : Appends a page named $pagename. If you use
#                              this command, then it will return a list of
#                              the paths of the pages. It returns a list
#                              because you can use this argument as much
#                              as you want in a line.
#
#       -pdelete $pagenum    : Deletes the page given by $pagenum. The number
#                              of the pages DON'T change even if you use this
#                              command. When you create a widget with three
#                              pages, the first one will get the # of 0,
#                              second will get 1, third will get 2. But if you
#                              delete the second page (numbered 1), the number
#                              of the third WILL NOT change.
#
# Additional options (by D. Grimaldo)
#	-bgcolor #COLOR	     : Background color, must be before the -p* opts!
#	-font  fontid	     : Font for radiobuttons (tab titles)
#
# notebook:raise $window $pagenum
#   This command raises the page numbered $pagenum. For more info anbout page numbers, look at notebook:configure.
#
#
#
#     Author: Waster
#             waster@iname.com http://waster.8m.com/notebook/index.html
#
#     Improvements: LordOfScripts
#		lordofscripts AT sourceforge.com http://www.coralys.com/


proc notebook:create {w args} {
global notebook

  set notebook($w,pages) {}
  set notebook($w,numpage) "-1"
  set notebook($w,selected) ""
  set notebook($w,paths) ""
  set notebook($w,bgcol) ""
  set notebook($w,font) ""

  frame $w -relief flat -borderwidth 1
  frame $w.f0 -relief flat -borderwidth 0
  frame $w.f1 -relief raised -borderwidth 1

  pack $w.f0 -in $w -expand 0 -fill x
  pack $w.f1 -in $w -expand 1 -fill both

  set returnval [eval notebook:configure $w $args]
  set notebook($w,paths) $returnval
  notebook:raise $w 0
  return $returnval
}

proc notebook:getpage {w pageid} {
    global notebook

    set page ""
    if {[string is integer $pageid]} {
    	# Caller is using the numerical page ID
	set page [lindex $notebook($w,paths) $pageid]
    } else {
    	# Caller is using the page's label
	set done 0
	while {$done == 0} {
	    set pageCnt $notebook($w,numpage)
	    for {set i 0} {$done == 0 && $i < $pageCnt} {incr i} {
	        set pageTitle [$w.f0.r$i cget -text]
		if {[string compare $pageTitle $pageid] == 0} {
		    set page [lindex $notebook($w,paths) $i]
		    set done 1
		}
	    }
	}
	if {$done == 0} {
	    puts "notebook:getpage $w $pageid invalid pageid"
	}
    }
    return $page
}

proc notebook:configure {w args} {
global notebook 
set returnval ""
set SystemButtonFace #aabbcc

  if {$notebook($w,bgcol) == ""} {
      set notebook($w,bgcol) [$w cget -background]
  }

  foreach {tag value} $args {
    switch -- $tag {
      -bgcolor {
          set notebook($w,bgcol) $value
      }
      -font {
          set notebook($w,font) $value
      }
      -pappend {
        lappend notebook($w,pages) $value
        incr notebook($w,numpage)
        lappend notebook($w,pages,del) 0

        radiobutton $w.f0.r$notebook($w,numpage) -borderwidth 1 -highlightthickness 0 -indicatoron 0 -padx 0 -pady 0 -selectcolor $SystemButtonFace -text $value -value $notebook($w,numpage) -variable notebook($w,selected) -command "notebook:raise $w $notebook($w,numpage)"
	if {$notebook($w,font) != ""} {
	    $w.f0.r$notebook($w,numpage) configure -font $notebook($w,font)
	}
        frame $w.f1.f$notebook($w,numpage) -relief flat -borderwidth 2 \
		-background $notebook($w,bgcol)

        pack $w.f0.r$notebook($w,numpage) -fill none -side left

        lappend returnval $w.f1.f$notebook($w,numpage)
      }
      -pdelete {
        set notebook($w,pages,del) [lreplace $notebook($w,pages,del) $value $value 1]
        destroy $w.f0.r$value
        destroy $w.f1.f$value

        if {$value==$notebook($w,selected)} {notebook:raise $w [notebook:findfirst $w]}
      }
    }
  }
  return $returnval
}

proc notebook:raise {w page} {      #raises the page given, the page must be the path of the frame, like $w.f1.f0 will raise 0. page
global notebook
set num 0

if { [lindex $notebook($w,pages,del) $page] != 0 } {return}

  set notebook($w,selected) $page
  foreach a $notebook($w,pages) {pack forget $w.f1.f$num; incr num}

  pack $w.f1.f$page -expand 1 -fill both

}

proc notebook:findfirst {w} {      #returns the number of the first page that is not deleted
global notebook
set num 0

  foreach a $notebook($w,pages,del) { if {$a==0} {return $num}; incr num }
}

