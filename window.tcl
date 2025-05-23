set ::gui_entry_opts {-highlightcolor {#909090} -highlightbackground {#606060}}
set ::gui_button_opts {-activebackground {#606060} -activeforeground {#000000} -highlightthickness 2 -highlightcolor {#909090} -highlightbackground {#606060}}
set ::gui_listbox_opts {-highlightthickness 2 -highlightcolor {#909090} -highlightbackground {#606060} -selectforeground {#000000} -selectbackground {#606060}}
set ::gui_text_opts {-highlightthickness 2 -highlightcolor {#909090} -highlightbackground {#606060} -foreground {#c0c0c0}}
set ::gui_label_opts {-highlightcolor {#909090} -highlightbackground {#606060}}
set ::gui_scroll_opts {-activebackground {#606060} -troughcolor {#606060} -width 16}

proc make_window {} {
	wm title . "gemview"
	pack [panedwindow .p -ori ver] -fill both -expand 1
	.p add [frame .p.t] -stretch never
	#pack [button .p.t.menu -text "menu" -command {} -font {Sans 9} {*}$::gui_button_opts ] -fill both -side left
	pack [button .p.t.save -text "save" -command {save_file $::cname $::cdata} -font {Sans 9} {*}$::gui_button_opts ] -fill both -side left
	pack [button .p.t.certs -text "certs" -command {manage_certs} -font {Sans 9} {*}$::gui_button_opts ] -fill both -side left
	pack [button .p.t.back -text "back" -command {back} -font {Sans 9} {*}$::gui_button_opts ] -fill both -side left
	pack [entry .p.t.line -textvar ::topline -font {Monospace 9} {*}$::gui_entry_opts ] -fill both -expand 1 -side left
	#pack [button .p.t.put -text "put" -command {toggle_put_mode} -font {Sans 9} {*}$::gui_button_opts ] -fill both -side left
	pack [button .p.t.get -text "get" -command {get_page $::topline} -font {Sans 9} {*}$::gui_button_opts ] -fill both -side left
	pack [button .p.t.history -text "history" -command {fromhistory} -font {Sans 9} {*}$::gui_button_opts ] -fill both -side left
	pack [label .p.t.type -textvar ::type -font {Sans 9} {*}$::gui_label_opts -width 6 ] -fill both -side left
	pack [button .p.t.exit -text "exit" -command {hist_save;exit} -font {Sans 9} {*}$::gui_button_opts -width 1 ] -fill both -side left 
	.p add [frame .p.tp] -stretch never -hide true
	#pack [button .p.tp.menu -text "menu" -command {} -font {Sans 9} {*}$::gui_button_opts ] -fill both -side left
	pack [label .p.tp.line -textvar ::topline -font {Sans 9} {*}$::gui_label_opts ] -fill both -expand 1 -side left
	pack [button .p.tp.commit -text "commit" -command {commit} -font {Sans 9} {*}$::gui_button_opts ] -fill both -side left
	pack [button .p.tp.cancel -text "cancel" -command {toggle_put_mode} -font {Sans 9} {*}$::gui_button_opts ] -fill both -side left
	.p add [frame .p.m] -stretch always
	pack [text .p.m.t -wrap word -yscrollc {.p.m.y set} -height 20 -width 80 -font {Monospace 9} {*}$::gui_text_opts ] -fill both -expand 1 -side left
	pack [scrollbar .p.m.y -command {.p.m.t yview} {*}$::gui_scroll_opts ] -fill y -side left
	.p add [frame .p.mp] -stretch always -hide true
	pack [text .p.mp.t -wrap word -yscrollc {.p.mp.y set} -height 20 -width 80 -font {Monospace 9} {*}$::gui_text_opts ] -fill both -expand 1 -side left
	pack [scrollbar .p.mp.y -command {.p.mp.t yview} {*}$::gui_scroll_opts ] -fill y -side left
	.p add [frame .p.b] -stretch never
	pack [label .p.b.line -textvar ::bottomline -font {Monospace 9} {*}$::gui_label_opts ] -fill both -expand 1 -side left
	set link_cmd {+ click .p.m.t %x %y link get_page}
	set seen_cmd {+ click .p.m.t %x %y seen get_page}
	.p.m.t tag bind link <1> $link_cmd
  .p.m.t tag bind link <Enter> ".p.m.t config -cursor hand2"
  .p.m.t tag bind link <Leave> ".p.m.t config -cursor {}"
	.p.m.t tag bind seen <1> $seen_cmd
  .p.m.t tag bind seen <Enter> ".p.m.t config -cursor hand2"
  .p.m.t tag bind seen <Leave> ".p.m.t config -cursor {}"
	bind .p.t.line <Key-Return> {get_page $::topline}
	set defcert [file join "." "certs" "default.crt"]
	set defkey [file join "." "certs" "default.key"]
}

proc click {w x y tag action} {
	set arg {}
	catch {
	set range [$w tag prevrange $tag [$w index @$x,$y]]
	set arg [eval $w get $range]
	} res
	puts "catch $res"
	if { $arg != "" } {
		$action [lindex $arg 0]
	}
}

proc back {} {
	set l [llength $::hist]
	if { $l == 0 } {
		return
	}
	set url [lindex $::hist end-1]
	set ::topline $url
	get_page $::topline
}

proc toggle_put_mode {} {
	if { [ .p panecget .p.t -hide ] } {
		.p paneconfigure .p.t -hide false 
		.p paneconfigure .p.m -hide false
		.p paneconfigure .p.tp -hide true 
		.p paneconfigure .p.mp -hide true
	} else {
		.p paneconfigure .p.t -hide true 
		.p paneconfigure .p.m -hide true
		.p paneconfigure .p.tp -hide false 
		.p paneconfigure .p.mp -hide false
		.p.mp.t delete 1.0 end
	}
} 

proc commit {} {
}

proc fromhistory {} {
	if { [winfo exists .h] == 1 } {
		return
	}
	toplevel .h
	wm title .h "Open URL from history"
	pack [panedwindow .h.p -ori ver] -fill both -expand 1
	.h.p add [frame .h.t] -stretch never
	#pack [button .h.t.cancel -text "cancel" -command {destroy .h} -font {Sans 9} {*}$::gui_button_opts ] -fill both -side left
	pack [label .h.t.line -text "Open URL from history" -font {Sans 9} {*}$::gui_label_opts ] -fill both -expand 1 -side left
	pack [button .h.t.get -text "get" -command {set ::topline [lindex $::hist [lindex [.h.m.l index active] 0]] ; get_page $::topline ; destroy .h} -font {Sans 9} {*}$::gui_button_opts ] -fill both -side left
	pack [button .h.t.delete -text "delete" -command {set i [lindex [.h.m.l index active] 0] ; set ::hist [lreplace $::hist $i $i] ; hist_save} -font {Sans 9} {*}$::gui_button_opts ] -fill both -side left
	.h.p add [frame .h.m] -stretch always
	pack [listbox .h.m.l -listvar ::hist -yscrollc {.h.m.y set} -height 20 -width 80 -font {Sans 9} {*}$::gui_listbox_opts ] -fill both -expand 1 -side left
	pack [scrollbar .h.m.y -command {.h.m.l yview} {*}$::gui_scroll_opts ] -fill y -side left
	.h.m.l yview end
}

proc prompt {url prompt} {
	if { [winfo exists .pr] == 1 } {
		return
	}
	toplevel .pr
	wm title .pr "Input request at $url"
	pack [panedwindow .pr.p -ori ver] -fill both -expand 1
	.pr.p add [frame .pr.t] -stretch never
	pack [label .pr.t.line -text "Input request at $url :" -font {Sans 9} {*}$::gui_label_opts ] -fill both -expand 1 -side left
	.pr.p add [frame .pr.m] -stretch never 
	pack [label .pr.m.prompt -text "$prompt" -font {Sans 9} {*}$::gui_label_opts ] -fill both -expand 1 -side left
	.pr.p add [frame .pr.b] -stretch never
	pack [entry .pr.b.line -textvar ::inputline -font {Monospace 9} {*}$::gui_entry_opts ] -fill both -expand 1 -side left
	pack [button .pr.b.send -text "send" -command {get_page "gemini://$::cur?[url_encode $::inputline]" ; destroy .pr} -font {Sans 9} {*}$::gui_button_opts ] -fill both -side left
	bind .pr.b.line <Key-Return> {get_page "gemini://$::cur?[url_encode $::inputline]" ; destroy .pr}
}

proc manage_certs {} {
	if { [winfo exists .mc] == 1 } {
		return
	}
	toplevel .mc
	wm title .mc "Manage certs"
	pack [panedwindow .mc.p -ori ver] -fill both -expand 1
	.mc.p add [frame .mc.t] -stretch never
	pack [entry .mc.t.line -textvar ::certline -font {Monospace 9} {*}$::gui_entry_opts ] -fill both -expand 1 -side left
	pack [button .mc.t.load -text "load" -command {set ::certline [lindex $::certlist [lindex [.mc.m.l index active] 0]] ; load_cert $::certline ; update_certs } -font {Sans 9} {*}$::gui_button_opts ] -fill both -side left
	pack [button .mc.t.clear -text "clear" -command {set ::certline {} ; set ::certfile {} ; set ::keyfile {} ; update_certs } -font {Sans 9} {*}$::gui_button_opts ] -fill both -side left
	#pack [button .mc.t.new -text "new" -command {save_cert {*}[gen_client_cert $::certline] ; update_certs } -font {Sans 9} {*}$::gui_button_opts ] -fill both -side left
	pack [button .mc.t.new -text "new" -command {cmd_make_cert $::certline ; update_certs } -font {Sans 9} {*}$::gui_button_opts ] -fill both -side left
	.mc.p add [frame .mc.m] -stretch always
	pack [listbox .mc.m.l -listvar ::certlist -yscrollc {.mc.m.y set} -height 20 -width 80 -font {Sans 9} {*}$::gui_listbox_opts ] -fill both -expand 1 -side left
	pack [scrollbar .mc.m.y -command {.mc.m.l yview} {*}$::gui_scroll_opts ] -fill y -side left
	.mc.p add [frame .mc.b] -stretch never
	pack [label .mc.b.cline -textvar ::certfile -font {Monospace 9} {*}$::gui_entry_opts ] -fill both -expand 1 -side left
	pack [label .mc.b.sep -text "|" -font {Monospace 9} {*}$::gui_entry_opts ] -fill both -side left
	pack [label .mc.b.kline -textvar ::keyfile -font {Monospace 9} {*}$::gui_entry_opts ] -fill both -expand 1 -side left

	proc update_certs {} {
		set cfiles [glob -nocomplain -directory [file join "." "certs"] -type f *.crt ]
		set ::certlist {}
		foreach cfile $cfiles {
			lappend ::certlist [string map {{.crt} {}} [lindex [file split $cfile] end]]
		}
	}
	update_certs
}

proc save_file {def data} {
	set path [tk_getSaveFile -initialfile "$def"]
	if { $path != "" && ![file exists $path] } {
		set f [open $path w]
		fconfigure $f -translation binary
		puts -nonewline $f $data
		close $f
	}
}
