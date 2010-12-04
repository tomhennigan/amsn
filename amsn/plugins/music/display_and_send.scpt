-- by Jerome Gagnon Voyer
--with the help of Edgar C. Rodriguez and Daniel Buenfil
--Thanks to Doug Adams for the part about cover arts
--Get more free AppleScripts and info on writing your own
--at Doug's AppleScripts for iTunes
--http://www.malcolmadams.com/itunes/
--iTunes script to get Path and Name of current track playing and write it to a text file


tell application "System Events"
	set iTunes to ((application processes whose (name is equal to "iTunes")) count)
end tell

if iTunes is greater than 0 then
	set artfile to ""
	tell application "iTunes"
		if player state is playing then
			set status to "Play"
			if class of current track is URL track then
				set aSong to name of current track
				set aArt to ""
				set finalpath to 0
				set artfile to 0
			else if class of current track is shared track then
				set aSong to name of current track
				set aArt to artist of current track
				set finalpath to 0
				set artfile to 0
			else if class of current track is audio CD track then
				set aSong to name of current track
				set aArt to artist of current track
				set finalpath to 0
				set artfile to 0
			else if class of current track is file track then
				set aSong to name of current track as text
				set aArt to artist of current track
				set firstpath to current track's location
				if firstpath is not missing value then
					set finalpath to POSIX path of firstpath as string
				else
					set finalpath to 0
				end if
				
				--Taking care of Artwork
				set theTrack to current track
				if class of current track is not file track or artworks of current track is {} then
					--my alert_user_and_cancel("The selected track does not contain Artwork.")
					set artfile to 0
				end if
				
				set artworkFolder to (path to application support folder from user domain as string) & "amsn:plugins:"
				try
					set artworkData to (data of artwork 1 of theTrack) as picture
					set artworkFormat to (format of artwork 1 of theTrack) as string
					if artworkFormat contains "JPEG" then
						set extension to ".jpg"
					else if artworkFormat contains "PNG" then
						set extension to ".png"
					end if
					
					set theName to "artworkitunes"
					
					set tempartworkFile to (artworkFolder & "temp" & extension) as string
					set finalartworkFile to (artworkFolder & theName & extension) as string
					
					set file_reference to (open for access tempartworkFile write permission 1)
					write artworkData starting at 0 to file_reference as picture
					close access file_reference
					
					do shell script "cd " & quoted form of (POSIX path of artworkFolder) & Â
						";tail -c+223 " & quoted form of ("temp" & extension) & "> " & Â
						quoted form of (theName & extension) & ";rm " & Â
						quoted form of ("temp" & extension)
					
				on error errM
					--close access file_reference
					--return ("Unable to export Artwork from the selected track." & Â
					--	return & return & errM)
					set artfile to 0
					
					
				end try
				if artfile is not 0 then
					set artfile to POSIX path of finalartworkFile as string
				else
					set artfile to ""
				end if
			end if
			
			set return to status & "
" & aSong & "
" & aArt & "
" & finalpath & "
" & artfile
			
			return return
			
		else if player state is paused then
			return 0
		else if player state is stopped then
			return 0
		end if
		
	end tell
	--if iTunes is not open
else
	return 0
	
end if

