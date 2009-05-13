tell application "Finder"
	tell disk "aMSN 0.98ß"
		
		-- Set the window up how we want
		open
		tell container window
			set current view to icon view
			set toolbar visible to false
			set statusbar visible to false
			set the bounds to {105, 187, 714, 612}
		end tell
		
		set opts to the icon view options of container window
		tell opts
			set icon size to 80
			set arrangement to not arranged
			set label position to bottom
		end tell
		
		set background picture of opts to file ".hidden:background.jpg"
		
		set position of file "aMSN.app" to {360, 125}
		set position of file "Applications" to {530, 125}
		set position of file "Help & Support.webloc" to {390, 270}
		set position of file "Plugins & Skins Installer.app" to {500, 270}
		
		update without registering applications
		
		tell container window
			set the bounds to {105, 187, 714, 612}
		end tell
		
		update without registering applications
		
		delay 5
	end tell
end tell