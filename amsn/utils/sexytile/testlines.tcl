#testlines:

package forget sexytile; package require sexytile; destroy .t; toplevel .t ; sexytile .t.st -icon [::skin::loadPixmap online] -text "This is a test"; pack .t.st



package forget sexytile; package require sexytile; destroy .t; toplevel .t ; sexytile .t.st -bgimage_default [::skin::loadPixmap online] -bgimage_hover [::skin::loadPixmap offline] -bgimage_pressed [::skin::loadPixmap busy] -icon [::skin::loadPixmap online] -text "This is a test"; pack .t.st


#tile with icon and text
package forget sexytile; package require sexytile; destroy .t; toplevel .t ; sexytile .t.st -bgimage_hover [::skin::loadPixmap offline] -bgimage_pressed [::skin::loadPixmap busy] -onpress [list puts "Sexy tile pressed"] -icon [::skin::loadPixmap online] -text "This is a sexy tile with text and icon"; pack .t.st

#button with icon and text
package forget sexytile; package require sexytile; destroy .t; toplevel .t ; sexytile .t.sb -bgimage_default [::skin::loadPixmap online] -bgimage_hover [::skin::loadPixmap offline] -bgimage_pressed [::skin::loadPixmap busy] -onpress [list puts "Sexy button pressed"] -icon [::skin::loadPixmap online] -text "This is a sexy button with text and icon"; pack .t.sb

#checkbutton or "selection button" with icon and text (like for in a preferences screen sidebar)
package forget sexytile; package require sexytile; destroy .t; toplevel .t ; sexytile .t.sb -textorientation s -bgimage_default [::skin::loadPixmap online] -bgimage_hover [::skin::loadPixmap offline] -bgimage_pressed [::skin::loadPixmap busy] -onpress [list puts "Sexy button pressed"] -icon [::skin::loadPixmap online] -text "This is a sexy button with text and icon"; pack .t.sb


#A simple filewidget
package forget sexytile; package require sexytile; destroy .t; toplevel .t ; sexytile .t.sb -type filewidget -icon [::skin::loadPixmap online] -text "filename.ext"; pack .t.sb; sexytile .t.sb2 -type filewidget -icon [::skin::loadPixmap offline] -text "filename2.ext";  pack .t.sb2
