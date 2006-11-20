# Renames tk commands and replaces them with our commands

set pixmapmenu_enabled 0

proc pixmapmenu_isEnabled {} {
  global pixmapmenu_enabled
  return [expr [info exists pixmapmenu_enabled] && $pixmapmenu_enabled ]
}

proc restore_pixmapmenus {} {
  # Recreating some menus
  create_states_menu .my_menu
  create_other_menus .user_menu .menu_invite
  create_main_menu .main_menu
}

proc enable_pixmapmenu {} {
  global pixmapmenu_enabled

  rename menu tk_menu
  rename menushell menu
  rename menubutton tk_menubutton
  rename menubut menubutton

  catch { tk_optionMenu -w00t }
  rename tk_optionMenu tk_tk_optionMenu
  rename OptionMenu tk_optionMenu

  set pixmapmenu_enabled 1
  restore_pixmapmenus
}

proc disable_pixmapmenu {} {
  global pixmapmenu_enabled

  rename tk_optionMenu OptionMenu
  rename tk_tk_optionMenu tk_optionMenu

  rename menubutton menubut
  rename tk_menubutton menubutton
  rename menu menushell
  rename tk_menu menu

  set pixmapmenu_enabled 0
  restore_pixmapmenus
}
