proc key_init {} {
	set ::certfile {}
	set ::keyfile {}
	set path [file join "." "mainkey"]
	if { ![file exists $path] } {
		set key [gen_key]
		set ::mainkey $key
		set f [open $path w]
		puts $f $key
		close $f
	} else {
		set f [open $path r]
		set key [read $f]
		close $f
		set ::mainkey $key
	}
	file mkdir [file join "." "certs"]
	set defcert [file join "." "certs" "default.crt"]
	set defkey [file join "." "certs" "default.key"]
	#save_cert {*}[gen_client_cert "default"]
	if { ![file exists $defcert] || ![file exists $defkey] } {
		cmd_make_cert "default"
	}
	set ::certline "default"
	load_cert $::certline
}

proc gen_key {} {
	set rkey [::pki::rsa::generate 1024]
	set key [::pki::key $rkey ]
	return $key
}

proc fake_ca {key} {
	set subj "C=gemview ca #[clock microseconds], L=gemview, O=gemview, CN=[::sha1::sha1 $key]"
	set d [::pki::pkcs::parse_key $key] 
	dict set d subject "$subj"
}

proc gen_client_cert {name} {
	if { $name == "" } {
		set name "gemview user, ms since epoch [clock microseconds]"
	}
	set rkey [::pki::rsa::generate 1024]
	set key [::pki::key $rkey ]
	set pubkey [::pki::public_key $rkey]
	set rpubkey [::pki::pkcs::parse_public_key $pubkey]
	set rcsr [::pki::pkcs::create_csr $rkey [list "CN" "$name"] true sha256]
	set csr [::pki::pkcs::parse_csr $rcsr]
	set cert [::pki::x509::create_cert $csr [fake_ca $::mainkey] [clock microseconds] 0 [clock add [clock seconds] 100 years] false {} true]
	puts "key"
	puts "$key"
	puts "cert"
	puts $cert
	return [list $name $cert $key]
}

proc load_cert {name} {
  set path [file join "." "certs" "$name.crt"]
  set kpath [file join "." "certs" "$name.key"]
  if { $name == "" || ![file exists $path] || ![file exists $kpath] } { 
    return
  }
	#set f [open $path r]
	#set ::cert [read $f]
	#close $f
	#set f [open $kpath r]
	#set ::key [read $f]
	#close $f
  set ::certfile $path
  set ::keyfile $kpath
}

proc save_cert {name cert key} {
  set path [file join "." "certs" "$name.crt"]
  set kpath [file join "." "certs" "$name.key"]
  if { $name == "" || [file exists $path] || [file exists $kpath] } { 
    return
  }
	set f [open $path w]
	puts -nonewline $f $cert
	close $f
	set f [open $kpath w]
	puts -nonewline $f $key
	close $f
}

proc cmd_make_cert {name} {
	set certfile [file join "." "certs" "$name.crt"]
	set keyfile [file join "." "certs" "$name.key"]
	set cmd "openssl req -new -subj \"/CN=$name\" -x509 -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 -days 1825 -nodes -out $certfile -keyout $keyfile"
	set out {}
	set res {}
	catch {
	set out [exec {*}$cmd]
	} res
	puts "catch $res"
	puts "RESULT OF CERT/KEY GENERATION : \n$out\n"
} 

key_init
