# Renames tk commands and replaces them with our commands

rename menu tk_menu
rename menushell menu
rename menubutton tk_menubutton
rename menubut menubutton
###################################
destroy [tk_optionMenu .1 a b]
destroy .1
###################################
rename tk_optionMenu tk_tk_optionMenu
rename OptionMenu tk_optionMenu