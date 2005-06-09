package require snit
package require scalable-bg

snit::widget pixmapprogbar {
	variable progress
	variable barwidth

	option -font -configuremethod SetFont
	option -foreground -configuremethod SetFg -default black -cgetmethod GetFg
	option -fg -configuremethod SetFg -cgetmethod GetFg
	option -overforeground -configuremethod SetOverFg -default white -cgetmethod GetOverFg
	option -overfg -configuremethod SetOverFg -cgetmethod GetOverFg

	component trough
	delegate option * to trough

	constructor { args } {
		install trough using canvas $win.c -bg white -highlightthickness 0 -relief flat
		$self configurelist $args
		set troughimg [image create photo -file trough.gif]
		scalable-bg trough -source $troughimg -width [$trough cget -width] -height [$trough cget -height] -n 1 -w 1 -s 1 -e 1
		set barimg [image create photo -file bar.gif]
		scalable-bg bar -source $barimg -width 0 -height [$trough cget -height] -n 3 -w 3 -s 6 -e 6
		
		set progress 0
		set barwidth 0
		
		$trough create image 0 0 -anchor nw -image [trough name] -tag trough
		$trough create image 0 0 -anchor nw -image [bar name] -tag bar
		$trough create text 0 0 -anchor c -text "0%" -tag indicator

		$self configurelist $args

		pack $trough -expand true -fill x
		bind $trough <Configure> "$self Resize %w %h"
	}

	method Resize { w h } {
		$trough coords indicator [expr [winfo width $trough] / 2] [expr [winfo height $trough] / 2]
		set barwidth [expr round($progress * [winfo width $trough])]
		set barheight [winfo height $trough]
		bar configure -width $barwidth -height $barheight
	}

	method setprogress { value } {
		set progress $value
		set barwidth [expr round($value * [winfo width $trough])]

		bar configure -width $barwidth

		if { $barwidth > [lindex [$trough coords indicator] 0] } {
			$trough itemconfigure indicator -fill $options(-overforeground)
		} else {
			$trough itemconfigure indicator -fill $options(-foreground)
		}

		$trough itemconfigure indicator -text "[expr round($value * 100)]%"
	}

	method SetFont { option value } {
		set options(-font) $value
		$trough itemconfigure indicator -font $value
	}

	method SetFg { option value } {
		set options(-foreground) $value
		set options(-fg) $value
		$trough itemconfigure indicator -fill $value
	}

	method GetFg { option } {
		return $options(-foreground)
	}

	method SetOverFg { option value } {
		set options(-overforeground) $value
		set options(-overfg) $value
	}

	method GetOverFg { option } {
		return $options(-overforeground)
	}

}