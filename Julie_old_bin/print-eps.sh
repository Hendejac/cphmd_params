#!/usr/bin/tcsh
#prints .eps files for all .agr files in current directory

foreach x (*.agr)
 xmgrace -hdevice EPS -hardcopy $x
end
