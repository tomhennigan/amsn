-- by Edgar C. Rodriguez, Daniel Buenfil and JŽr™me Gagnon-Voyer
--iTunes script to get Path and Name of current track playing and write it to a text file


tell application "System Events"
	set iTunes to ((application processes whose (name is equal to "iTunes")) count)
end tell

if iTunes is greater than 0 then
	
	tell application "iTunes"
		if player state is playing then
			set status to "Play"
			if class of current track is URL track then
				set aSong to name of current track
				set aArt to ""
				set finalpath to 0
			else if class of current track is shared track then
				set aSong to name of current track
				set aArt to artist of current track
				set finalpath to 0
			else if class of current track is audio CD track then
				set aSong to name of current track
				set aArt to artist of current track
				set finalpath to 0
			else if class of current track is file track then
				set aSong to name of current track as text
				set aArt to artist of current track
				set firstpath to current track's location
				if firstpath is not missing value then
					set finalpath to POSIX path of firstpath as string
				else
					set finalpath to 0
				end if
				
			end if
			
			set return to status & "
" & aSong & "
" & aArt & "
" & finalpath
			
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

