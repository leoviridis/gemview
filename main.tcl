package require Tcl
package require tls
package require pki
package require Tk
package require Memchan
package require Img
package require sound
package require snack
#package require snackogg

source "./cert.tcl"
source "./url.tcl"
source "./get.tcl"
source "./display.tcl"
source "./image.tcl"
source "./sound.tcl"
source "./window.tcl"
source "./hist.tcl"

set ::cur {}
set ::hist {}
set ::fifo {}
set ::topline {}
set ::bottomline {}
set ::type {}
set ::cdata {}
set ::cname {}

hist_load
make_window

vwait forever
hist_save
