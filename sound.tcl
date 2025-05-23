proc display_sound {name mime data} {
	catch {
		destroy .wf
		destroy .snd_play
		destroy .snd_stop
		destroy .snd_pause
	}
	switch $mime {
		{audio/mpeg} {
			set fmt "mp3"
		}
		{audio/ogg} {
			set fmt "ogg"
		}
		{audio/ogg-vorbis} {
			set fmt "ogg"	
		}
		{audio/wav} {
			set fmt "wav"
		}
		default {
			puts "not a supported audio format"
			return -1
		}
	} 
	catch { $::sound($name) destroy }
	catch { close $::sound($name,fifo) }
	catch { set ::sound($name,fifo) [fifo] }
	catch { fconfigure $::sound($name,fifo) -translation binary -encoding binary }
	catch { puts -nonewline $::sound($name,fifo) $data }
	snack::sound $name -channel $::sound($name,fifo) -channels 2 -rate 44100
	#canvas .wf -width 800 -height 80 -highlightcolor red -selectforeground green
	#.wf create waveform 0 0 -sound $name -width 800 -height 80
	set play_cmd "$name play -blocking 0"
	set stop_cmd "$name stop"
	set pause_cmd "$name pause"
	button .snd_play -text play -command $play_cmd
	button .snd_stop -text stop -command $stop_cmd
	button .snd_pause -text pause -command $pause_cmd
	.p.m.t delete 1.0 end
	#.p.m.t insert end "\n" {text}
	#.p.m.t window create end -window .wf
	.p.m.t insert end "\n" {text}
	.p.m.t insert end "Sound: $name" {text}
	.p.m.t insert end "\n" {text}
	.p.m.t window create end -window .snd_play
	.p.m.t window create end -window .snd_stop
	.p.m.t window create end -window .snd_pause
	.p.m.t insert end "\n" {text}
	return 0
}
