package require snit
package provide scalable-bg 0.1

snit::type scalable-bg {
	option -border -default {0 0 0 0} -configuremethod setBorder
	option -n -configuremethod setOption -default 0
	option -e -configuremethod setOption -default 0
	option -s -configuremethod setOption -default 0
	option -w -configuremethod setOption -default 0
	option -resizemethod -default tile
	option -source -configuremethod setOption
	option -width -configuremethod setOption -default 1
	option -height -configuremethod setOption -default 1

	variable src
	variable base

	constructor { args } {
		$self configurelist $args

		# Create base image
		set base [image create photo]

		set src $options(-source)

		# Build up the image
		$self BuildImage
	}

	destructor {
		catch {image delete $base}
	}

	method BuildImage { } {
		# Check if requested size is too small
		set minwidth [expr {$options(-w) + $options(-e) + 1}]
		set minheight [expr {$options(-n) + $options(-s) + 1}]
		if {
			$options(-width) < $minwidth || \
			$options(-height) < $minheight
		} {
			return {}
		}

			# Get src image width and height
			set srcwidth [image width $src]
			set srcheight [image height $src]
			set midvert [expr {$options(-height) - $options(-n) - $options(-s)}]
			set midhoriz [expr {$options(-width) - $options(-w) - $options(-e)}]
			set srcmidvert [expr {$srcheight - $options(-n) - $options(-s)}]
			set srcmidhoriz [expr {$srcwidth - $options(-w) - $options(-e)}]
			set bottomvert [expr {$options(-height) - $options(-s)}]
			set righthoriz [expr {$options(-width) - $options(-e)}]
			set srcbottomvert [expr {$srcheight - $options(-s)}]
			set srcrighthoriz [expr {$srcwidth - $options(-e)}]

			# Check values aren't below 1
			foreach var { srcwidth srcheight midvert midhoriz srcmidvert srcmidhoriz bottomvert righthoriz srcbottomvert srcrighthoriz } {
				if { [set $var] < 1 } {
					set $var 1
				}
			}

			# Create sub-images
			foreach img { top left centre right bottom } {
				set $img [image create photo]
			}

			# Are we scaling or tiling?
			set scaling [string equal $options(-resizemethod) scale]

			# Resize left section
			if { $options(-w) > 0 } {
				$left configure -width $options(-w) -height $srcmidvert
				$left blank
				$left copy $src -from 0 $options(-n) $options(-w) $srcbottomvert -to 0 0
	
				if { $scaling } {
					::CxImage::Resize $left $options(-w) $midvert
				}
			}

			# Resize middle section
			$centre configure -width $srcmidhoriz -height $srcmidvert
			$centre blank
			$centre copy $src -from $options(-w) $options(-n) $srcrighthoriz $srcbottomvert -to 0 0

			if { $scaling } {
				::CxImage::Resize $centre $midhoriz $midvert
			}

			# Resize right section
			if { $options(-e) > 0 } {
				$right configure -width $options(-e) -height $srcmidvert
				$right blank
				$right copy $src -from $srcrighthoriz $options(-n) $srcwidth $srcbottomvert -to 0 0
	
				if { $scaling } {
					::CxImage::Resize $right $options(-e) $midvert
				}
			}

			# Resize top section
			if { $options(-n) > 0 } {
				$top configure -width $srcmidhoriz -height $options(-n)
				$top blank
				$top copy $src -from $options(-w) 0 $srcrighthoriz $options(-n)
	
				if { $scaling } {
					::CxImage::Resize $top $midhoriz $options(-n)
				}
			}

			# Resize bottom section
			if { $options(-s) > 0 } {
				$bottom configure -width $srcmidhoriz -height $options(-s)
				$bottom blank
				$bottom copy $src -from $options(-w) $srcbottomvert $srcrighthoriz $srcheight
	
				if { $scaling } {
					::CxImage::Resize $bottom $midhoriz $options(-s)
				}
			}


			# Build up button image
			# Start with a clean slate...
			$base blank
			# ...of correct proportions
			$base configure -width $options(-width) -height $options(-height)
			# NW corner
			$base copy $src -from 0 0 $options(-w) $options(-n) -to 0 0
			# N border
			$base copy $top -to $options(-w) 0 $righthoriz $options(-n)
			# NE corner
			$base copy $src -from $srcrighthoriz 0 $srcwidth $options(-n) -to $righthoriz 0
			# W border
			$base copy $left -to 0 $options(-n) $options(-w) $bottomvert
			# Centre/Body
			$base copy $centre -to $options(-w) $options(-n) $righthoriz $bottomvert
			# E border
			$base copy $right -to $righthoriz $options(-n) $options(-width) $bottomvert
			# SW corner
			$base copy $src -from 0 $srcbottomvert $options(-w) $srcheight -to 0 $bottomvert
			# S border
			$base copy $bottom -to $options(-w) $bottomvert $righthoriz $options(-height)
			# SE corner
			$base copy $src -from $srcrighthoriz $srcbottomvert $srcwidth $srcheight -to $righthoriz $bottomvert

			# Delete sub-images
			foreach img { top left centre right bottom } {
				image delete [set $img]
			}
	}

	# Set's the borders for the image
	method setBorder { option value } {
		set options(-border) $value
		foreach { n e s w } $value {
			$self configure -n $n
			$self configure -e $e
			$self configure -s $s
			$self configure -w $w
		}
	}

	# Generic option setting
	method setOption { option value } {
		if { [string equal $options($option) $value] } {
			return {}
		}

		set options($option) $value

		# Check we have everythgin we need to build the image
		if { [info exists src] && [info exists base] } {
			set src $options(-source)
			$self BuildImage
		}
	}

	# Returns the name of the tk image used by this scalable-bg
	method name { } {
		return $base
	}
}
