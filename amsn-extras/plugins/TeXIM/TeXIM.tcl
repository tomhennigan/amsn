# Copyright Andrei Barbu (abarbu@uwaterloo.ca)
# This code is distributed under the GPL


namespace eval ::TeXIM {

	# We do this so more than one person can use amsn and this plugin concurrently
	# Otherwise we would risk simultaneous access to the same file
	variable localpid [pid]
	variable dir /tmp/${localpid}-latex

	proc Init { dir } {
		plugins_log "TeXIM" "LaTeX plugin has started"

		file mkdir $::TeXIM::dir

		::plugins::RegisterPlugin "TeXIM"
		::plugins::RegisterEvent "TeXIM" WinWrite parseLaTeX	

		#TODO, fix amsn string support, it doesn't put it by default to what it sais in config
		#TODO, add a multiline input box for header and footer

                array set ::TeXIM::config {
			showtex {0}
			showerror {0}
			path_latex {latex}
			path_dvips {dvips}
			path_convert {convert}
			dummy {0}
	        }
		
	        set ::TeXIM::configlist [list \
					     [list bool "Show tex" showtex] \
					     [list bool "Display errors" showerror] \
					     [list str "Path to latex binary" path_latex] \
					     [list str "Path to dvips binary" path_dvips] \
					     [list str "Path to convert binary" path_convert] \
					    ]
	}
	
	proc DeInit { } {
		file delete -force $::TeXIM::dir
	}
	
	proc parseLaTeX {event evPar} {

		upvar 2 txt txt
		upvar 2 win_name win_name

		if { [string first "\\tex " $txt] == 0 } { 
			
			# Strip \tex out
			set msg [string range $txt 4 end]
			
			set localtime [clock seconds]

			set chan [open ${::TeXIM::dir}/temp.tex w]
			puts $chan "\\documentclass\[10pt\]\{article\}"
			puts $chan "\\pagestyle{empty}"
			puts $chan "\\begin\{document\}"
			puts $chan "\\begin\{huge\}"
			puts $chan $msg
			puts $chan "\\end\{huge\}"
			puts $chan "\\end\{document\}"
			flush $chan
			close $chan

			set olddir [pwd]
			cd ${::TeXIM::dir}

			catch { exec $::TeXIM::config(path_latex)  \
				    -interaction=nonstopmode ${::TeXIM::dir}/temp.tex } msg

			if { [file exists ${::TeXIM::dir}/temp.dvi] }  {
				if { [ catch { exec $::TeXIM::config(path_dvips) \
						   -f -E -o ${::TeXIM::dir}/temp.ps -q ${::TeXIM::dir}/temp.dvi } msg ] == 0 } { 
					catch {file delete ${::TeXIM::dir}/temp.dvi}
					if { [ catch { exec $::TeXIM::config(path_convert) \
							   ${::TeXIM::dir}/temp.ps ${::TeXIM::dir}/temp.gif } msg ] == 0 } {
						
						set imagename [image create photo -file ${::TeXIM::dir}/temp.gif -format gif]
						
						${win_name}.f.out.text configure -state normal -font bplainf -foreground black
						${win_name}.f.out.text image create end -name ${localtime} -image $imagename -padx 0 -pady 0 
						
						if { $::TeXIM::config(showtex) == 0 } { 
							set txt "" 
						} else {
							${win_name}.f.out.text configure -state normal -font bplainf -foreground black
							${win_name}.f.out.text insert end "\n"
						}		    
						
						cd $olddir
						return txt
					}
				}
				
			}

			if { $::TeXIM::config(showerror) == 1 } {
				${win_name}.f.out.text insert end $msg
				${win_name}.f.out.text insert end "\n"
			} else { plugins_log "TeXIM" $msg }  
		
		
			cd $olddir
			return txt	
		}
		
		return ""
	}
}
