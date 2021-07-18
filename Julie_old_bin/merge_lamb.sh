#!/bin/tcsh
# merge multiple files from stage1, stage2, ...
#

if ($#argv < 2) then
    USAGE:
    echo "Usage: merge_lamb.sh <first stage> <last stage>"
    exit 1
endif

set firststage = $argv[1]
set laststage = $argv[2]
set filenames = `ls stage$firststage/*lamb* | cut -d'/' -f2`

foreach fname ($filenames)

    echo "File name: $fname"
    awk '{if($1 ~ /^#/) print}' stage$firststage/$fname > $fname.stage${firststage}-${laststage}
    set laststep = 0
    set i = $firststage

    while ($i <= $laststage)
        awk -v laststep=$laststep '{if($1 !~ /^#/) {$1=$1+laststep; printf("%8i",$1); for(i=2;i<=NF;i++) {printf("%5.2f",$i)}; printf("\n")}} END {if(laststep<$1) laststep=$1; print laststep > "laststep.tmp"}' stage$i/$fname >> $fname.stage${firststage}-${laststage}
        set laststep = `cat laststep.tmp`
        rm laststep.tmp
        @ i += 1
    end

end

exit
