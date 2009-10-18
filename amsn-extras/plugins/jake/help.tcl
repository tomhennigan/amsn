proc helpparseArgs { string_text } {
    #element 0 from list = command
    #element 1 from list = status (ok if everything is ok, else err) 

    #if string is "" we should return the general help
    #elseif string starts with " and ends with " we should return the help for the command between ""
    #else string isn't well formatted.
    if { [string compare $string_text ""] == 0 } {
	set arguments [list "" "ok"]
    } elseif { [regexp -- {^".*"$} $string_text] } {
	#remove first char
	set string_text [string range $string_text 1 end]
	#remove last char
	set string_text [string range $string_text 0 [expr [string length $string_text] - 2]]
	set arguments [list $string_text "ok"]
    } else {
	set arguments [list "" "err"]
    }
    return $arguments
}

proc helpgeneralHelp {} {
    set results "[trans txtcommands]:\n\n\
		![trans cmdhelp], ![trans cmdon], ![trans cmdoff],\
		![trans cmdgoogle], ![trans cmddefine], ![trans cmdhour]\
		![trans cmddate], ![trans cmdstate], ![trans cmdlearn],\
		![trans cmdforget], ![trans cmdyoutube],\
		![trans cmdexpr], ![trans cmdmegaupload], ![trans cmdsong],\
		![trans cmdtranslate]\n\n\
                [trans txtprm]: [trans prmhelp]\n\
                [trans txtdsc]: [trans dschelp]\n\
                [trans txtexl]: [trans exlhelp]"
    return $results
}

proc helpcommandHelp { string_text } {
    #probably there is a really better way of doing this. Maybe an array containing the commands.
    #if the command exists, just [trans cmd$array_value]
    #else print the error message.
    #I'll change that in the future.
    if { [string compare $string_text "![trans cmdhelp]"] == 0 } {
	set results "[trans txtcommand]: ![trans cmdhelp]\n\
		    [trans txtprm]: [trans prmhelp]\n\
		    [trans txtdsc]: [trans dschelp]\n\
		    [trans txtexl]: [trans exlhelp]"
    } elseif { [string compare $string_text "![trans cmdon]"] == 0 } {
	set results "[trans txtcommand]: ![trans cmdon]\n\
		    [trans txtprm]: [trans prmon]\n\
		    [trans txtdsc]: [trans dscon]\n\
		    [trans txtexl]: [trans exlon]"
    } elseif { [string compare $string_text "![trans cmdoff]"] == 0 } {
	set results "[trans txtcommand]: ![trans cmdoff]\n\
		    [trans txtprm]: [trans prmoff]\n\
		    [trans txtdsc]: [trans dscoff]\n\
		    [trans txtexl]: [trans exloff]"
    } elseif { [string compare $string_text "![trans cmdgoogle]"] == 0 } {
	set results "[trans txtcommand]: ![trans cmdgoogle]\n\
		    [trans txtprm]: [trans prmgoogle $::jake::config(nresultsgoogle)]\n\
		    [trans txtdsc]: [trans dscgoogle]\n\
		    [trans txtexl]: [trans exlgoogle]"
    } elseif { [string compare $string_text "![trans cmddefine]"] == 0 } {
	set results "[trans txtcommand]: ![trans cmddefine]\n\
		    [trans txtprm]: [trans prmdefine]\n\
		    [trans txtdsc]: [trans dscdefine]\n\
		    [trans txtexl]: [trans exldefine]"
    } elseif { [string compare $string_text "![trans cmdhour]"] == 0 } {
	set results "[trans txtcommand]: ![trans cmdhour]\n\
		    [trans txtprm]: [trans prmhour]\n\
		    [trans txtdsc]: [trans dschour]\n\
		    [trans txtexl]: [trans exlhour]"
    } elseif { [string compare $string_text "![trans cmddate]"] == 0 } {
	set results "[trans txtcommand]: ![trans cmddate]\n\
		    [trans txtprm]: [trans prmdate]\n\
		    [trans txtdsc]: [trans dscdate]\n\
		    [trans txtexl]: [trans exldate]"
    } elseif { [string compare $string_text "![trans cmdstate]"] == 0 } {
	set results "[trans txtcommand]: ![trans cmdstate]\n\
		    [trans txtprm]: [trans prmstate]\n\
		    [trans txtdsc]: [trans dscstate]\n\
		    [trans txtexl]: [trans exlstate]"
    } elseif { [string compare $string_text "![trans cmdlearn]"] == 0 } {
	set results "[trans txtcommand]: ![trans cmdlearn]\n\
		    [trans txtprm]: [trans prmlearn]\n\
		    [trans txtdsc]: [trans dsclearn]\n\
		    [trans txtexl]: [trans exllearn]"
    } elseif { [string compare $string_text "![trans cmdforget]"] == 0 } {
	set results "[trans txtcommand]: ![trans cmdforget]\n\
		    [trans txtprm]: [trans prmforget]\n\
		    [trans txtdsc]: [trans dscforget]\n\
		    [trans txtexl]: [trans exlforget]"
    } elseif { [string compare $string_text "![trans cmdyoutube]"] == 0 } {
	set results "[trans txtcommand]: ![trans cmdyoutube]\n\
		    [trans txtprm]: [trans prmyoutube $::jake::config(nresultsyoutube)]\n\
		    [trans txtdsc]: [trans dscyoutube]\n\
		    [trans txtexl]: [trans exlyoutube]"
    } elseif { [string compare $string_text "![trans cmdexpr]"] == 0 } {
	set results "[trans txtcommand]: ![trans cmdexpr]\n\
		    [trans txtprm]: [trans prmexpr]\n\
		    [trans txtdsc]: [trans dscexpr]\n\
		    [trans txtexl]: [trans exlexpr]"
    } elseif { [string compare $string_text "![trans cmdmegaupload]"] == 0 } {
	set results "[trans txtcommand]: ![trans cmdmegaupload]\n\
		    [trans txtprm]: [trans prmmegaupload $::jake::config(nresultsmegaupload)]\n\
		    [trans txtdsc]: [trans dscmegaupload]\n\
		    [trans txtexl]: [trans exlmegaupload]"
    } elseif { [string compare $string_text "![trans cmdsong]"] == 0 } {
	set results "[trans txtcommand]: ![trans cmdsong]\n\
		    [trans txtprm]: [trans prmsong $::jake::config(nresultssongs)]\n\
		    [trans txtdsc]: [trans dscsong]\n\
		    [trans txtexl]: [trans exlsong]"
    } elseif { [string compare $string_text "![trans cmdtranslate]"] == 0 } {
	set results "[trans txtcommand]: ![trans cmdtranslate]\n\
		    [trans txtprm]: [trans prmtranslate]\n\
		    [trans txtdsc]: [trans dsctranslate]\n\
		    [trans txtexl]: [trans exltranslate]"
    } else {
	set results "[trans txtcmdunknown] $string_text"
    }
    return $results
}