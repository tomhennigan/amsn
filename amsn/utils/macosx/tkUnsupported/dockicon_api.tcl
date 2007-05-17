#
# Modify the Dock Icon on Mac OS X
# 	- Accessing the Carbon API's with Ffidl
# 		- Copyright (c) 2005, Daniel A. Steffen <das@users.sourceforge.net>
# 		- Modified by tomhennigan <tomhennigan[at]gmail[dot]com> for use with aMSN.
# 	- BSD License: c.f. <http://www.opensource.org/licenses/bsd-license>
#

package require Ffidl

namespace eval carbon {
	proc api {name argl ret lib} {::ffidl::callout $name $argl $ret \
		[::ffidl::symbol $lib.framework/$lib $name]}
	proc type {name type} {::ffidl::typedef $name $type}
	proc const {name args} {variable {}; eval set [list ($name)] $args}

	type OSStatus sint32
	type bool int
	type CFURLRef pointer
	type CGDataProviderRef pointer
	type CGImageRef pointer
	type CGColorRenderingIntent int
	const kCGRenderingIntentDefault 0

	api CFURLCreateFromFileSystemRepresentation {pointer pointer-utf8 \
			int bool} CFURLRef CoreFoundation
	api CFRelease {pointer} void CoreFoundation
	api CGDataProviderCreateWithURL {CFURLRef} CGDataProviderRef \
			ApplicationServices
	api CGImageCreateWithPNGDataProvider {CGDataProviderRef pointer \
			bool CGColorRenderingIntent} CGImageRef ApplicationServices
	api SetApplicationDockTileImage {CGImageRef} OSStatus Carbon
	api OverlayApplicationDockTileImage {CGImageRef} OSStatus Carbon
	api RestoreApplicationDockTileImage {} OSStatus Carbon

	proc setApplicationDockIconToPNG {pngFile} {
		if {[file exists $pngFile]} {
			set url [CFURLCreateFromFileSystemRepresentation 0 $pngFile \
					[string bytelength $pngFile] 0]
			if {$url} {
				set dp [CGDataProviderCreateWithURL $url]
				if {$dp} {
					set img [CGImageCreateWithPNGDataProvider $dp 0 1 \
							[const kCGRenderingIntentDefault]]
					if {$img} {
						SetApplicationDockTileImage $img
						CFRelease $img
					}
					CFRelease $dp
				}
				CFRelease $url
			}
		}
		
		return $pngFile
	}
	
	proc overlayApplicationDockIconWithPNG {pngFile} {
		if {[file exists $pngFile]} {
			set url [CFURLCreateFromFileSystemRepresentation 0 $pngFile \
					[string bytelength $pngFile] 0]
			if {$url} {
				set dp [CGDataProviderCreateWithURL $url]
				if {$dp} {
					set img [CGImageCreateWithPNGDataProvider $dp 0 1 \
							[const kCGRenderingIntentDefault]]
					if {$img} {
						OverlayApplicationDockTileImage $img
						CFRelease $img
					}
					CFRelease $dp
				}
				CFRelease $url
			}
		}
		
		return $pngFile
	}
	
	proc restoreApplicationDockIcon {} {
		RestoreApplicationDockTileImage
		
		return ""
	}
}