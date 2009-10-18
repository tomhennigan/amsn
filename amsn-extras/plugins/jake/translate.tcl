proc replacehtmlentities { string_text } {
    array set chars {
        u0026ndash; – u0026mdash; — u0026iexcl; ¡ u0026iquest; ¿ u0026quot; \" \
        u0026ldquo; “ u0026rdquo; ” u0026lsquo; ‘ u0026rsquo; ’ u0026aquo; « \
        u0026raquo; » u0026amp; \\& u0026cent; ¢ u0026copy; © u0026divide; ÷ \
        u0026gt; > u0026lt; < u0026micro; µ u0026middot; · u0026para; ¶ \
        u0026plusmn; ± u0026euro; € u0026pound; £ u0026reg; ® u0026sect; § \
        u0026trade; ™ u0026yen; ¥ u0026#39; ' u003d = }
    foreach {char replace} [array get chars] {
            regsub -all \\\\$char $string_text $replace string_text
    }
    return $string_text
}

proc convert {string} {
        set x [string length $string]
        for {set i 0} {$i<$x} {incr i} {
                append output "&#[scan [string range $string $i $i] %c];"
        }
        return $output
}

proc translateWithGoogle {lng txt} {
        set botname $::jake::config(botname)
        array set languages  [list \
        "[trans lngalbanian]" sq "[trans lngarabic]" ar "[trans lngarmenian]" hy \
        "[trans lngbasque]" eu "[trans lngbelarusian]" be "[trans lngbengali]" bn \
        "[trans lngbosnian]" bs "[trans lngbreton]" br "[trans lngbulgarian]" bg \
        "[trans lngcatalan]" ca "[trans lngchinese-simplified]" zh-CN \
        "[trans lngchinese-traditional]" zh-TW "[trans lngcroatian]" hr \
        "[trans lngczech]" cs "[trans lngdanish]" da "[trans lngdutch]" nl \
        "[trans lngenglish]" en "[trans lngesperanto]" eo "[trans lngfilipino]" tl \
        "[trans lngfinnish]" fi "[trans lngfrench]" fr "[trans lnggalician]" gl \
        "[trans lnggerman]" de "[trans lnggreek]" el "[trans lnghebrew]" iw \
        "[trans lnghungarian]" hu "[trans lngirish]" ga "[trans lngitalian]" it \
        "[trans lngjapanese]" ja "[trans lngkorean]" ko "[trans lnglatin]" la \
        "[trans lnglithuanian]" lt "[trans lngmacedonian]" mk "[trans lngmongolian]" mn \
        "[trans lngnorwegian]" no "[trans lngpersian]" fa "[trans lngpolish]" pl \
        "[trans lngportuguese-brazil]" pt-BR "[trans lngportuguese-portugal]" pt-PT \
        "[trans lngromanian]" ro "[trans lngrussian]" ru "[trans lngscots]" gd \
        "[trans lngserbian]" sr "[trans lngserbo-croatian]" sh "[trans lngslovak]" sk \
        "[trans lngslovenian]" sl "[trans lngspanish]" es "[trans lngswedish]" sv \
        "[trans lngturkish]" tr "[trans lngukrainian]" uk "[trans lngvietnamese]" vi \
        "[trans lngwelsh]" cy ]
        if { [info exists languages($lng)] } {
                set query [httpformatQuery q $txt v 1.0]
                set token [::http::geturl http://www.google.com/uds/GlangDetect?$query -query]
                set data [::http::data $token]
                regexp {\"language\":\"(.*?)\",\"} $data -> from

                set query [::http::formatQuery v 1.0 q [convert $txt] langpair $from|$languages($lng)]
                set token [::http::geturl http://ajax.googleapis.com/ajax/services/language/translate?$query -query]
                set data [::http::data $token]
                regexp {\"translatedText\":\"(.*?)\"\}} $data -> str
                set str [replacehtmlentities $str]

                set output "$botname: \n\n$str"
        } else {
                set output "$botname: \n\n[trans errtranslate] $lng."
        }
        return $output
}