#!/bin/tcsh
# calculate exchange frequency by phmdDCD from stage1, stage2, ...
#

if ($#argv < 2) then
    USAGE:
    echo "Usage: phrex_frq.sh <first stage> <last stage>"
    exit 1
endif

set firststage = $argv[1]
set laststage = $argv[2]

#merge_log.sh $firststage $laststage  
set nfiles = `ls *log_*.stage$firststage-$laststage* | wc -l`

printf "phmdDCD" > phmdDCD.cmd

set i = 0

while ($i < $nfiles)
    printf " -log *log_$i.stage$firststage-$laststage" >> phmdDCD.cmd
    @ i += 1
end
 
chmod +x phmdDCD.cmd
./phmdDCD.cmd
 
mv ExchangeRate.dat ExchangeRate.dat.stage$firststage-$laststage
mv RepWalk1.dat RepWalk.dat.stage$firststage-$laststage
rm phmdDCD.cmd

exit
