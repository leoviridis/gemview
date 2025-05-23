proc hist_load {} {
	set path "./history"
	if { ![file exists $path] } {
		return
	}
	set f [open $path r]
	set ::hist {}
	while { [gets $f url] >= 0 && ![eof $f] } {
		lappend ::hist $url
	}
	close $f
}

proc hist_add {url} {
	lappend ::hist $url
	set path "./history"
	set f [open $path a]
	puts $f $url
	close $f
}

proc hist_save {} {
	set path "./history"
	set f [open $path w]
	foreach url $::hist {
		puts $f $url
	}
	close $f
}
