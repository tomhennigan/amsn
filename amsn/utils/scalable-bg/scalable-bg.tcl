package require snit
#package require TkCximage
package provide scalable-bg 0.1

snit::type scalable-bg {
	option -n -configuremethod setOption
	option -e -configuremethod setOption
	option -s -configuremethod setOption
	option -w -configuremethod setOption
	option -resizemethod
	option -source -configuremethod setOption
	option -width -configuremethod setOption
	option -height -configuremethod setOption

	variable top
	variable right
	variable bottom
	variable left
	variable centre
	variable src

	variable base

	constructor { args } {
		$self configurelist $args

		set base [image create photo -width $options(-width) -height $options(-height)]
		set left [image create photo -width $options(-w) -height [expr {$options(-height) - $options(-n) - $options(-s)}]]
		set centre [image create photo -width [expr {$options(-width) - $options(-w) - $options(-e)}] -height [expr {$options(-height) - $options(-n) - $options(-s)}]]
		set right [image create photo -width $options(-e) -height [expr {$options(-height) - $options(-n) - $options(-s)}]]
		set top [image create photo -width [expr {$options(-width) - $options(-e)}] -height $options(-n)]
		set bottom [image create photo -width [expr {$options(-width) - $options(-e)}] -height $options(-n)]
		set src $options(-source)

		$self BuildImage
	}

	method BuildImage { } {
		$base configure -width $options(-width) -height $options(-height)
		#Check if requested size is too small:
		if {
			$options(-width) < [expr {$options(-w) + $options(-e) + 1}] || \
			$options(-height) < [expr {$options(-n) + $options(-s) + 1}] || \
			[image width $src] < [expr {$options(-w) + $options(-e) + 1}] || \
			[image height $src] < [expr {$options(-n) + $options(-s) + 1}]
		 } {
			return
		} else {
			#Resize left section:
			$left configure -width $options(-w) \
				-height [expr [image height $src] - $options(-n) - $options(-s)]
			$left blank
			if { [expr {[image height $src] - $options(-s)}] < 0 } { exit }
			$left copy $src -from 0 $options(-n) $options(-w) [expr [image height $src] - $options(-s)] -to 0 0
			if { $options(-resizemethod) == "scale" } {
				::CxImage::Resize $left $options(-w) [expr {$options(-height) - $options(-n) - $options(-s)}]
			}
		
			#Resize middle section:
			$centre configure -width [expr {[image width $src] - $options(-w) - $options(-e)}] \
				-height [expr {[image height $src] - $options(-n) - $options(-s)}]
			$centre blank
			$centre copy $src -from $options(-w) $options(-n) [expr {[image width $src] - $options(-e)}] \
				[expr {[image height $src] - $options(-s)}] -to 0 0
			if { $options(-resizemethod) == "scale" } {
				::CxImage::Resize $centre [expr {$options(-width) - $options(-w) - $options(-e)}] \
					[expr {$options(-height) - $options(-n) - $options(-s)}]
			}
	
			#Resize right section:
			$right configure -width $options(-e) \
				-height [expr {[image height $src] - $options(-n) - $options(-s)}]
			$right blank
			$right copy $src -from [expr {[image width $src] - $options(-e)}] $options(-n) [image width $src] [expr {[image height $src] - $options(-s)}] -to 0 0
			if { $options(-resizemethod) == "scale" } {
				::CxImage::Resize $right $options(-e) [expr {$options(-height) - $options(-n) - $options(-s)}]
			}
	
			#Resize top section:
			$top configure -width [expr {[image width $src] - $options(-w) - $options(-e)}] -height $options(-n)
			$top blank
			$top copy $src -from $options(-w) 0 [expr {[image width $src] - $options(-e)}] $options(-n)
			if { $options(-resizemethod) == "scale" } {
				::CxImage::Resize $top [expr {$options(-width) - $options(-w) - $options(-e)}] $options(-n)
			}
	
			#Resize bottom section:
			$bottom configure -width [expr {[image width $src] - $options(-w) - $options(-e)}] -height $options(-s)
			$bottom blank
			$bottom copy $src -from $options(-w) [expr {[image height $src] - $options(-s)}] \
				[expr {[image width $src] - $options(-e)}] [image height $src]
			if { $options(-resizemethod) == "scale" } {
				::CxImage::Resize $bottom [expr {$options(-width) - $options(-w) - $options(-e)}] \
					$options(-s)
			}
	
			#Build up button image:
			$base configure -width $options(-width) -height $options(-height)
			$base blank
			#NW corner
			$base copy $src -from 0 0 $options(-w) $options(-n) -to 0 0
			#Top border
			$base copy $top -to $options(-w) 0 [expr {$options(-width) - $options(-e)}] $options(-n)
			#NE corner
			$base copy $src -from [expr {[image width $src] - $options(-e)}] 0 [image width $src] \
				$options(-n) -to [expr {$options(-width) - $options(-e)}] 0
			#Left border
			$base copy $left -to 0 $options(-n) $options(-w) [expr {$options(-height) - $options(-s)}]
			#Centre
			$base copy $centre -to $options(-w) $options(-n) [expr {$options(-width) - $options(-e)}] \
				[expr {$options(-height) - $options(-s)}]
			#Right border
			$base copy $right -to [expr {$options(-width) - $options(-e)}] $options(-n) $options(-width) \
				[expr {$options(-height) - $options(-s)}]
			#SW corner
			$base copy $src -from 0 [expr {[image height $src] - $options(-s)}] $options(-w) \
				[image height $src] -to 0 [expr {$options(-height) - $options(-s)}]
			#Bottom border
			$base copy $bottom -to $options(-w) [expr {[image height $base] - $options(-s)}] \
				[expr {$options(-width) - $options(-e)}] $options(-height)
			#SE corner
			$base copy $src -from [expr {[image width $src] - $options(-e)}] \
				[expr {[image height $src] - $options(-s)}] [image width $src] [image height $src] \
				-to [expr {$options(-width) - $options(-e)}] [expr {$options(-height) - $options(-s)}]
		}
	}

	method setOption { option value } {
		set options($option) $value
		if {
			[info exists top] && \
			[info exists right] && \
			[info exists bottom] && \
			[info exists left] && \
			[info exists centre] && \
			[info exists src] && \
			[info exists base]
		} {
			$self BuildImage
		}
	}

	method name { } {
		return $base
	}
}