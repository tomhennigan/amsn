package require snit
package require TkCximage
package provide scalable-bg 0.1

snit::type scalable-bg {
	option -n -configuremethod setOption -default 0
	option -e -configuremethod setOption -default 0
	option -s -configuremethod setOption -default 0
	option -w -configuremethod setOption -default 0
	option -resizemethod -default tile
	option -source -configuremethod setOption
	option -width -configuremethod setOption -default 1
	option -height -configuremethod setOption -default 1

	variable top
	variable right
	variable bottom
	variable left
	variable centre
	variable src

	variable base

	constructor { args } {
		$self configurelist $args

		# Create image spaces
		set base [image create photo -width $options(-width) -height $options(-height)]
		set left [image create photo -width $options(-w) -height [expr {$options(-height) - $options(-n) - $options(-s)}]]
		set centre [image create photo -width [expr {$options(-width) - $options(-w) - $options(-e)}] -height [expr {$options(-height) - $options(-n) - $options(-s)}]]
		set right [image create photo -width $options(-e) -height [expr {$options(-height) - $options(-n) - $options(-s)}]]
		set top [image create photo -width [expr {$options(-width) - $options(-e)}] -height $options(-n)]
		set bottom [image create photo -width [expr {$options(-width) - $options(-e)}] -height $options(-n)]
		set src $options(-source)

		# Build up the image
		$self BuildImage
	}

	method BuildImage { } {

		# Check if requested size is too small:
		set minwidth [expr $options(-w) + $options(-e) + 1]
		set minheight [expr $options(-n) + $options(-s) + 1]
		#if {
		#	$options(-width) < $minwidth || \
		#	$options(-height) < $minheight
		 #} {
		#	puts FAILED:$options(-height)
		#	return
		#} else {
			# Set base image's width and height
			$base configure -width $options(-width) -height $options(-height)

			# Get src image width and height:
			set srcwidth [image width $src]
			set srcheight [image height $src]
			set midvert [expr $options(-height) - $options(-n) - $options(-s)]
			set midhoriz [expr $options(-width) - $options(-w) - $options(-e)]
			set srcmidvert [expr $srcheight - $options(-n) - $options(-s)]
			set srcmidhoriz [expr $srcwidth - $options(-w) - $options(-e)]
			set bottomvert [expr $options(-height) - $options(-s)]
			set righthoriz [expr $options(-width) - $options(-e)]
			set srcbottomvert [expr $srcheight - $options(-s)]
			set srcrighthoriz [expr $srcwidth - $options(-e)]

			# Check values aren't negative
			foreach var { srcwidth srcheight midvert midhoriz srcmidvert srcmidhoriz bottomvert righthoriz srcbottomvert srcrighthoriz } {
				if { [expr $$var] < 1 } {
					set $var 1
				}
			}

			# Resize left section:----------------------------------------
			if { $options(-w) > 0 } {
				$left configure -width $options(-w) -height $srcmidvert
				$left blank
				$left copy $src -from 0 $options(-n) $options(-w) $srcbottomvert -to 0 0
	
				if { $options(-resizemethod) == "scale" } {
					::CxImage::Resize $left $options(-w) $midvert
				}
			}

			#-------------------------------------------------------------
			# Resize middle section:--------------------------------------
			$centre configure -width $srcmidhoriz -height $srcmidvert
			$centre blank
			$centre copy $src -from $options(-w) $options(-n) $srcrighthoriz $srcbottomvert -to 0 0

			if { $options(-resizemethod) == "scale" } {
				::CxImage::Resize $centre $midhoriz $midvert
			}
			#-------------------------------------------------------------
			# Resize right section:---------------------------------------
			if { $options(-e) > 0 } {
				$right configure -width $options(-e) -height $srcmidvert
				$right blank
				$right copy $src -from $srcrighthoriz $options(-n) $srcwidth $srcbottomvert -to 0 0
	
				if { $options(-resizemethod) == "scale" } {
					::CxImage::Resize $right $options(-e) $midvert
				}
			}

			# Resize top section:--------------------------------------
			if { $options(-n) > 0 } {
				$top configure -width $srcmidhoriz -height $options(-n)
				$top blank
				$top copy $src -from $options(-w) 0 $srcrighthoriz $options(-n)
	
				if { $options(-resizemethod) == "scale" } {
					::CxImage::Resize $top $midhoriz $options(-n)
				}
			}

			# Resize bottom section:--------------------------------------
			if { $options(-s) > 0 } {
				$bottom configure -width $srcmidhoriz -height $options(-s)
				$bottom blank
				$bottom copy $src -from $options(-w) $srcbottomvert $srcrighthoriz $srcheight
	
				if { $options(-resizemethod) == "scale" } {
					::CxImage::Resize $bottom $midhoriz $options(-s)
				}
			}


			# Build up button image:
			$base blank
			$base configure -width $options(-width) -height $options(-height)

			# NW corner
			$base copy $src -from 0 0 $options(-w) $options(-n) -to 0 0

			# Top border
			$base copy $top -to $options(-w) 0 $righthoriz $options(-n)

			# NE corner
			$base copy $src -from $srcrighthoriz 0 $srcwidth $options(-n) -to $righthoriz 0

			# Left border
			$base copy $left -to 0 $options(-n) $options(-w) $bottomvert

			# Centre
			$base copy $centre -to $options(-w) $options(-n) $righthoriz $bottomvert

			# Right border
			$base copy $right -to $righthoriz $options(-n) $options(-width) $bottomvert

			# SW corner
			$base copy $src -from 0 $srcbottomvert $options(-w) $srcheight -to 0 $bottomvert

			# Bottom border
			$base copy $bottom -to $options(-w) $bottomvert $righthoriz $options(-height)

			# SE corner
			$base copy $src -from $srcrighthoriz $srcbottomvert $srcwidth $srcheight -to $righthoriz $bottomvert
		
		#}
	}

	method setOption { option value } {
		if { [string equal $options($option) $value] } {
			return {}
		}
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
			set src $options(-source)
			$self BuildImage
		}
	}

	# Returns the name of the actual image used by this scalable-bg
	method name { } {
		return $base
	}
}
