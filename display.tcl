# w is a text widget
proc display_page {w data} {
	puts "display_page"
	$w delete 1.0 end
	$w tag configure header1 -font {Serif 10 bold} -foreground {#c06060}
	$w tag configure header2 -font {Serif 10 bold} -foreground {#c09060}
	$w tag configure header3 -font {Serif 10 bold} -foreground {#6090c0}
	$w tag configure link -font {Sans 9} -foreground {#6060c0} -underline true -relief raised -borderwidth 0
	$w tag configure seen -font {Sans 9} -foreground {#c060c0} -underline true -relief raised -borderwidth 0
	$w tag configure linkdesc -font {Sans 9} -foreground {#c0c0c0} -selectforeground {#c0c0c0}
	$w tag configure seendesc -font {Sans 9} -foreground {#c0c0c0} -selectforeground {#c0c0c0}
	$w tag configure litem -font {Sans 9 italic} -foreground {#c0c0c0} -selectforeground {#c0c0c0}
	$w tag configure text -font {Sans 9} -foreground {#c0c0c0} -selectforeground {#c0c0c0}
	$w tag configure mono -font {Monospace 9} -foreground {#c0c0c0} -selectforeground {#c0c0c0}
	$w tag configure prefix -font {Monospace 9} -foreground {#909090}
	$w tag configure quote -font {Sans 9} -foreground {#909090}
	#$w tag configure hidden -elide true
	set lines [split $data "\n"]
	set l 0
	set tag {}
	set prefix {}
	set content {}
	set desc {}
	set desctag {}
	foreach rline $lines {
		#puts "$rline"
		set rline [string trim $rline]
		if { [string range $rline 0 2] == "```" } {
			if { $l == 0 } {	
				set l 1	
			} else {
				set l 0
			}
			$w insert end "```" {prefix}
			set rline [string range $rline 3 end]
		}
		set first [string first { } [string map {"\t" " "} $rline]]
		if { $first != -1 } {
			set token [string trim [string range $rline 0 "$first-1"]]
			set rest [string range $rline "$first+1" end]
		} else {
			set token $rline
			set rest { }
		}
		#set line [split [regsub -all {\s+} $rline { }] { }]
		#set token [lindex $line 0]
		switch $token {
			"#" {
				set prefix {# }
				set tag {header1}
				#set content [concat [lrange $line 1 end]]
				set content $rest 
				set desc {}
				set desctag {}
			}
			"##" {
				set prefix {## }
				set tag {header2}
				#set content [concat [lrange $line 1 end]]
				set content $rest 
				set desc {}
				set desctag {}
			}
			"###" {
				set prefix {### }
				set tag {header3}
				#set content [concat [lrange $line 1 end]]
				set content $rest
				set desc {}
				set desctag {}
			}
			">" {
				set prefix {> }
				set tag {quote}
				#set content [concat [lrange $line 1 end]]
				set content $rest
				set desc {}
				set desctag {}
			}
			"=>" {
				#set prefix "-> "
				set prefix {=> }
				set tag {link}
				set desctag {linkdesc}
				set second [string first { } [string map {"\t" " "} $rest]]
				if { $second == -1 } { set second end }
				set content [string trim [string range $rest 0 $second]]
				if { [lsearch -exact $::hist [url_to_abs $content]] > -1 } {
					set tag {seen}
					set desctag {seendesc}
				}
				set desc [string trim [string range $rest $second end]]
				set ext [lindex [split $content "."] end]
				# lots of loading pictures is unpleasant
				set ext "nopics"
				switch $ext {
					"gif" -
					"jpeg" -
					"jpg" -
					"png" {
						catch {
						insert_inline_image $content
						set delay [expr "500+[clock microseconds]%4500"]
						after $delay [list get_inline_image $content]
						}
					}
				}	
			}
			"*" {
				set prefix " * "
				set tag {litem}
				#set content [concat [lrange $line 1 end]]
				set content $rest
				set desc {}
				set desctag {}
			}
			default {
				set prefix { }
				set tag {text}
				set content $rline
				set desc {}
				set desctag {}
			}
		}	
		if { $l == 1 } {
			set prefix { }
			set tag {mono}
			set content $rline
			set desc {}
			set desctag {}
		}
		$w insert end $prefix {prefix}
		$w insert end "$content" $tag
		$w insert end " " {text}
		$w insert end "$desc" $desctag 
		$w insert end "\n"
	}
	$w yview 1.0 
}
