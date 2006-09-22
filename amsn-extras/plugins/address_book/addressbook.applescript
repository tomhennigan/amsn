-- Description:	API To Access MSN Handles in Address Book
-- Author:		Tom Hennigan
-- Version:		0.1
-- License:		Keep my name included as a comment within the API, and you can do what you want with it.

on run args
	if args is {} then
		return "Usage: osascript scriptName.app returnAllAddressesWithMSNHandle/returnAllCustomNicks"
	else if item 1 of args is "returnAllMSNAddresses" then
		return returnAllAddressesWithMSNHandle()
	else if item 1 of args is "returnAllCustomNicks" then
		return returnAllCustomNicks()
	else
		return "Usage: osascript scriptName.app returnAllAddressesWithMSNHandle/returnAllCustomNicks"
	end if
end run

on returnAllAddressesWithMSNHandle()
	tell application "Address Book"
		set AppleScript's text item delimiters to "\" \""
		return ("\"" & (value of MSN handles of (every person whose MSN handles is not {}) as text) & "\"") 
	end tell
end returnAllAddressesWithMSNHandle

on returnAllCustomNicks()
	tell application "Address Book"
		set AppleScript's text item delimiters to "\" \""
		return ("\"" & (name of (every person whose MSN handles is not {}) as text) & "\"")
	end tell
end returnAllCustomNicks
