proc display_image {data name} {
	set type {}
	puts "display_image mimetype $::mimetype"
	switch $::mimetype {
		"image/png" {
			set type png
		}
		"image/jpeg" {
			set type jpeg
		}
		"image/jpg" {
			set type jpeg
		}
		"image/gif" {
			set type gif
		}
		default {
			puts "unknown image type $::mimetype"
			return -1
		}
	}
	puts "image type $type"
	catch { image delete $::img } res
	set fimg [image create photo -format $type -data $data]
	set ::img [image create photo]
	set iw [image width $fimg]
	set ih [image height $fimg]
	set w [winfo width .p.m.t]
	set h [winfo height .p.m.t]
	if { $w > $iw && $h > $ih } {
		$::img copy $fimg -to 0 0 -shrink
	} else {
		$::img copy $fimg -to 0 0
	}
	catch { image delete $fimg } res
	.p.m.t delete 1.0 end
	.p.m.t insert end "suggested name: $name\n"
	.p.m.t insert end "widget resolution: $w x $h\n"
	.p.m.t insert end "original image resolution: $iw x $ih\n"
	.p.m.t insert end "mimetype: $::mimetype\n"
	.p.m.t insert end "\n"
	.p.m.t image create end -image $::img
	.p.m.t insert end "\n"
	return 0
}

proc clean_inline_images {} {
	foreach {id name} [array get ::inline_img] {
		catch {
			image delete $name
		} res
	}
	catch {
	array unset ::inline_img "*"
	} res
}

proc insert_inline_image {url} {
	set url [url_to_abs $url]
	puts "insert_inline_image $url"
	set img [image create photo]
	array set ::inline_img [list $url $img]
	.p.m.t insert end "\n"
	.p.m.t image create end -image $img
	.p.m.t insert end "\n"
	puts "inserted image $url"
}

proc display_inline_image {data url} {
	set url [url_to_abs $url]
	puts "display_inline_image $url"
	set ext [lindex [split $url "."] end]
	if { $ext == "jpg" } {
		set ext "jpeg"
	}
	set fimg [image create photo -format $ext -data $data]
	set img [lindex [array get ::inline_img $url] end]
	set iw [image width $fimg]
	set ih [image height $fimg]
	set w [winfo width .p.m.t]
	set h [winfo height .p.m.t]
	if { $w > $iw && $h > $ih } {
		$img copy $fimg -to 0 0 -shrink
	} else {
		$img copy $fimg -to 0 0
	}
	catch { image delete $fimg } res
	puts "displayed image $url"
	return 0
}
