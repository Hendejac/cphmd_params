#!/bin/tcsh
# merge multiple log files from stage1, stage2, ...
#

if ($#argv < 2) then
    USAGE:
    echo "Usage: merge_log.sh <first stage> <last stage>"
    exit 1
endif

set firststage = $argv[1]
set laststage = $argv[2]
set filenames = `ls stage$firststage/*log* | cut -d'/' -f2`

foreach fname ($filenames)

    echo "File name: $fname"

    if ( -e $fname.stage$firststage-$laststage ) then
        rm $fname.stage$firststage-$laststage
    endif

    set i = $firststage
    while ($i <= $laststage)
        cat stage$i/$fname >> $fname.stage$firststage-$laststage
        @ i += 1
    end

end

exit
