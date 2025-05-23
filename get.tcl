proc url_to_abs {url} {
	if { [string range $url 0 8 ] != "gemini://" } {
		if { [string index $url 0] != {/} } {
			set last [string last {/} $::cur]
			if { $last > 0 } {
				set loc [string range $::cur 0 $last]
			} else {
				set loc $::cur
			}
		} else {
			set first [string first {/} $::cur]
			if { $first > 0 } {
				set loc [string range $::cur 0 $first]
			} else {
				set loc $::cur
			}
		}
		set url "gemini://[string trimright $loc {/}]/[string trimleft $url {/}]"
	}
	return $url
}

proc append_msg {msg} {
	set ntext "${::bottomline}...${msg}"
	set ::bottomline "[string map {"\n" " " "\t" " " "\r" " "} [string range $ntext end-79 end]]"
}

proc get_page {url} {
	set url [url_to_abs $url]
	set host [lindex [split [string map { {gemini://} {} } $url] "/"] 0]
	set shost [split $host {:}]
	if { [llength $shost] == 2 } {
		set port [lindex [split $host {:}] 1]
		set host [lindex [split $host {:}] 0]
	} elseif { [llength $shost] != 1 } {
		append_msg "bad URL -> $url" 
		return
	} else {
		set port 1965
	}
	if { [lindex $::hist end] != $url } {
		hist_add $url
	}
	set ::cur [string map { {gemini://} {} } $url]
	set ::curhost $host
	set ::curport $port
	set r "$url\r\n"
	set ::topline $url
	set ::type "get"
	set ::mimetype ""
	request $host $port $r 0
}

proc get_inline_image {url} {
	set url [url_to_abs $url]
	set host [lindex [split [string map { {gemini://} {} } $url] "/"] 0]
	set shost [split $host {:}]
	if { [llength $shost] == 2 } {
		set port [lindex [split $host {:}] 1]
		set host [lindex [split $host {:}] 0]
	} elseif { [llength $shost] != 1 } {
		append_msg "bad URL -> $url" 
		return
	} else {
		set port 1965
	}
	set r "$url\r\n"
	request $host $port $r 1
}

proc request {host port request inline} {
	set s {}
	catch {
	if { $::certfile != "" && $::keyfile != "" } { 
		puts "tls connecting with crt $::certfile and key $::keyfile to $host : $port"
		set s [tls::socket -tls1 false -tls1.1 false -tls1.2 true -tls1.3 true -request true -require false -autoservername true -certfile $::certfile -keyfile $::keyfile $host $port]
	} else {	
		puts "tls connecting without crt and key to $host : $port"
		set s [tls::socket -tls1 false -tls1.1 false -tls1.2 true -tls1.3 true -request true -require false -autoservername true $host $port]
	}
	} res
	#puts "catch (create socket) $res"
	if { $s == "" } {
		append_msg "failed to open socket for $host : $port -> $request" 
		return
	}
	append_msg "$request -> requesting from $host : $port"
	catch {
	fconfigure $s -blocking 0 -buffering line -translation binary
	if { $inline != 1 } {
		set sid [after 3000 [list response_timeout $s]]
		fileevent $s readable [list response_handler $s $sid]
	} else {
		set ::inline_type($s) "get"
		fileevent $s readable [list response_handler_inline $s [string map {"\r\n" ""} $request]]
	}
	} res
	#puts "catch (configure socket) $res"
	catch { puts -nonewline $s $request } res
	#puts "catch (write request) $res"
}

proc response_timeout {s} {
	append_msg "timed out" 
	catch { close $s } res
	#puts "catch (timeout) $res"
	set ::fifo {}
}

proc response_handler_inline {s url} {
	set code {}
	set ctype {}
	set line {}
	if { $::inline_type($s) == "get" || $::inline_type($s) == "redirect" } {
		puts "expecting header response"
		catch { gets $s line } res
		#puts "catch (line, gets) $res"
		catch { puts $::inline_fifo($s) $line } res
		#puts "catch (line, load to fifo) $res"
	} else {
		puts "expecting data response"
		catch { puts -nonewline $::inline_fifo($s) [read $s] } res
		#puts "catch (bin, read and load to fifo) $res"
		catch { flush $::inline_fifo($s) } res
		#puts "catch (bin, flush fifo) $res"
	}
	if { [eof $s] } {
		if { $::inline_type($s) == "binary" } {
			puts "eof binary"
			set data {}
			catch { set data [read $::inline_fifo($s)] } res
			#puts "catch (binary data) $res"
			catch {
			set ret [display_inline_image $data $url]
			}
		}
		set ::inline_type($s) "$::inline_type($s) ."
		catch { close $s } res
		#puts "catch (close socket) $res"
	} elseif { ![fblocked $s] } {
		if { $::inline_type($s) != "get" || $line == {} } {
			puts "wrong state or empty line"
			return
		}
		if { [string index $line 2] != { } || [string index $line end] != "\r" || [string length $line] > 2047 } {
			puts "malformed string [string range $line 0 79]..."
			return
		}
		set code [string range $line 0 1]
		if { [regexp -all {[0-9]} $code] != 2 } {
			puts "wrong response code $code"
			return
		}	
		set code1 [string index $code 0]
		set code2 [string index $code 1]
		set ctypefull [string range $line 3 end]
		set ctype [string trim [lindex [split $ctypefull {;}] 0]]
		set ctypeparam [string trim [lindex [split $ctypefull {;}] 1]]
		if { $code1 == {2} && [string range $ctype 0 4] != {image} } {
			set ::inline_type($s) "binary"
			catch { close $::inline_fifo($s) } res
			#puts "catch ($code $ctype inline image) $res"
			set ::inline_fifo($s) [fifo]
			fconfigure $::inline_fifo($s) -buffering line -translation binary
		} else {
			set ::inline_type($s) "failure"
			catch { close $::inline_fifo($s) } res
			#puts "catch ($code $ctype inline image) $res"
		} 
	}
}

proc response_handler {s sid} {
	set code {}
	set ctype {}
	set line {}
	if { $::type == "get" || $::type == "redirect" } {
		puts "expecting header response"
		catch {
		gets $s line
		} res
		#puts "catch (line, gets) $res"
		catch {
		puts $::fifo $line 
		} res
		#puts "catch (line, load to fifo) $res"
	} else {
		puts "expecting data response"
		catch {
		puts -nonewline $::fifo [read $s]
		} res
		#puts "catch (bin, read and load to fifo) $res"
		catch {
		flush $::fifo
		} res
		#puts "catch (bin, flush fifo) $res"
	}
	if { [eof $s] } {
		if { $::type == "gemini" } {
			puts "eof gemini page"	
			set page {}
			catch {
				set data [read $::fifo]
				set page [encoding convertfrom utf-8 $data]
			} res
			#puts "catch (gemini page data) $res"
			clean_inline_images
			display_page .p.m.t $page
			if { [lindex $::hist end] != $::topline } {
				hist_add $::topline
			}
			set ::cdata $data
			set ::cname [url_decode [lindex [split $::topline {/}] end]]
		} elseif { $::type == "plain" } {
			puts "eof plain page"	
			catch {
				set data [read $::fifo]
				set page [encoding convertfrom utf-8 $data]
			} res
			#puts "catch (plain page data) $res"
			.p.m.t delete 1.0 end
			.p.m.t insert end $page
			.p.m.t insert "\n"
			if { [lindex $::hist end] != $::topline } {
				hist_add $::topline
			}
			set ::cdata $data
			set ::cname [url_decode [lindex [split $::topline {/}] end]]
		} elseif { $::type == "binary" } {
			puts "eof binary"
			set data {}
			catch {
				#binary scan [read $::fifo] a* data
				set data [read $::fifo]
			} res
			#puts "catch (binary data) $res"
			set def [url_decode [lindex [split $::topline {/}] end]]
			if { $def == "" } {
				set def "newfile"
			}
			#set path [tk_getSaveFile -initialfile "$def"]
			#vwait path
			#if { $path != "" && ![file exists $path] } {
			#	set f [open $path w]
			#	puts -nonewline $f $data
			#	close $f
			#	unset $f
			#}
			set ret {-1}
			#if { [string range $::mimetype 0 4] == "audio" } {
			#	set ret [display_sound $def $::mimetype $data]
			#}
			if { [string range $::mimetype 0 4] == "image" } {
				set ret [display_image $data $def]
			}
			if { [string length $data] > 0 && $ret == -1 } {
				after idle [list save_file $def $data]
			}
			if { [lindex $::hist end] != $::topline } {
				hist_add $::topline
			}
			set ::cdata $data
			set ::cname [url_decode [lindex [split $::topline {/}] end]]
		}
		set ::type "$::type ."
		append_msg "closed socket"
		catch {
		close $s
		} res
		#puts "catch (close socket) $res"
	} elseif { ![fblocked $s] } {
		if { $::type != "get" || $line == {} } {
			puts "wrong state or empty line"
			return
		}
		if { [string index $line 2] != { } || [string index $line end] != "\r" || [string length $line] > 2047 } {
			puts "malformed string [string range $line 0 79]..."
			return
		}
		set code [string range $line 0 1]
		if { [regexp -all {[0-9]} $code] != 2 } {
			puts "wrong response code $code"
			return
		}	
		set code1 [string index $code 0]
		set code2 [string index $code 1]
		set ctypefull [string range $line 3 end]
		set ctype [string trim [lindex [split $ctypefull {;}] 0]]
		set ctypeparam [string trim [lindex [split $ctypefull {;}] 1]]
		append_msg "$code $ctypefull"
		if { $code1 == {2} && $ctype == {text/gemini} } {
			append_msg "$code $ctypefull -> loading"
			set ::type "gemini"
			set ::mimetype $ctype
			catch { close $::fifo } res
			#puts "catch ($code $ctype $::topline) $res"
			set ::fifo [fifo]
			fconfigure $::fifo -buffering line -translation binary
		} elseif { $code1 == {2} && $ctype == {text/plain} } {
			append_msg "$code $ctypefull -> loading"
			set ::type "plain" 
			set ::mimetype $ctype
			catch { close $::fifo } res
			#puts "catch ($code $ctype $::topline) $res"
			set ::fifo [fifo]
			fconfigure $::fifo -buffering line -translation binary
		} elseif { $code1 == {2} && [string range $ctype 0 4] != {text/} } {
			puts "ctype $ctype"
			append_msg "$code $ctypefull -> loading"
			set ::type "binary"
			set ::mimetype $ctype
			catch { close $::fifo } res
			#puts "catch ($code $ctype $::topline) $res"
			set ::fifo [fifo]
			fconfigure $::fifo -buffering line -translation binary
		} elseif { $code1 == {3} } { 
			append_msg "redirected $code -> [lindex $line 1]"
			set ::type "redirect"
			set ::mimetype {}
			catch { close $::fifo } res
			#puts "catch ($code $ctype $::topline) $res"
			set ask [tk_dialog .red_dlg "Redirect offered" "Redirect offered\nfrom $::topline to [lindex $line 1],\nfollow?" "" 1 "Cancel" "Accept"]
			if { $ask == 1 } {
				get_page [lindex $line 1]
			}
		} elseif { $code1 == {1} } {
			append_msg "prompt"
			set ::type "prompt"
			set ::mimetype {}
			prompt $::cur $ctype
			catch { close $::fifo } res
			#puts "catch ($code $ctype $::topline) $res"
		} elseif { $code1 == {4} } {
			append_msg "temporary failure -> $code $ctype"
			set ::type "fail $code"
			set ::mimetype {}
			catch { close $::fifo } res
			#puts "catch ($code $ctype $::topline) $res"
		} elseif { $code1 == {5} } {
			append_msg "permanent failure -> $code $ctype"
			set ::type "fail $code"
			set ::mimetype {}
			catch { close $::fifo } res
			#puts "catch ($code $ctype $::topline) $res"
		} elseif { $code1 == {6} } {
			append_msg "identity -> $code $ctype"
			set ::type "identify"
			set ::mimetype {}
			catch { close $::fifo } res
			#puts "catch ($code $ctype $::topline) $res"
			if { $code2 == {0} } {
				get_page $::topline
			} else {
				append_msg "identity failure -> $code $ctype"
			}
		} 
	}
	catch { after cancel $sid } res
	#puts "catch (cancel timeout) $res"
}
