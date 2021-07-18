#!/bin/tcsh
# get average from a charmm pmf file

if ($#argv < 1) then
USAGE:
    echo "Get average of force from charmm pmf files."
    echo "Usage: pmf_2d_average < prefix of lamb file name ([xxx].theta...thetx...)> [cumulative average flag (default: 0, off; >0, on)] [start step (default: begin of file)] [end step (default: end of file)]"
    exit 1
endif

set start=-1
set end=9999999999999999999999999999999
set cflag=0

if ($#argv >= 1) then
    set name  = $argv[1]
endif

if ($#argv >= 2) then
    set cflag  = $argv[2]
endif

if ($#argv >= 3) then
    set start  = $argv[3]
endif

if ($#argv >= 4) then
    set end = $argv[4]
endif


printf "#theta\tthetx\tFtheta_ave\tFtheta_sem\tFthetx_ave\tFtehtx_sem\n" > $name.pmf.dat

foreach theta (0.0 0.2 0.4 0.6 0.7854 1.0 1.2 1.4 1.5708)
  foreach thetx (0.0 0.2 0.4 0.6 0.7854 1.0 1.2 1.4 1.5708)

    echo "theta = $theta, thetx = $thetx"
    echo "prod_${theta}_${thetx}.lambda"
    set fname="prod_${theta}_${thetx}.lambda"

  if ( -e $fname ) then

   if ($cflag > 0) then
    printf "#step\tFtheta_cave\tFthetx_cave\n" > $fname.cave
   endif

    awk -v start=$start -v end=$end -v cflag=$cflag -v fname=$fname -v name=$name -v theta=$theta -v thetx=$thetx 'BEGIN {for(i=3;i<=NF;i+=2) {sum[i]=0; s2[i]=0}; n=0; first=-1; last=-1; printf("%.4f\t%.4f",theta,thetx) >> name".pmf.dat";}; {if($1 !~ /^#/ && $1>=start && $1<=end) {for(i=3;i<=NF;i+=2) {sum[i]+=$i; s2[i]+=$i^2}; n++; if(n==1) first=$1; if($1>last) last=$1; if(cflag>0) {printf("%i\t",$1) >> fname".cave"; for(i=3;i<=NF-1;i+=2) {printf("%.4f\t",sum[i]/n) >> fname".cave"}; printf("%.4f\n",sum[NF]/n) >> fname".cave"}}}; END {for(i=3;i<=NF;i+=2) {ave[i]=sum[i]/n; sem[i]=sqrt(1/(n-1)*(s2[i]/n-(sum[i]/n)^2));}; for(i=3;i<=NF;i+=2) {printf("\t%8.4f\t%8.4f",ave[i],sem[i]) >> name".pmf.dat"}; printf("\n") >> name".pmf.dat"; print "Start Time: ", first, " ps; End Time: ", last, " ps."}' $fname
  else
    echo "$fname does not exit!"
  endif

  end
end


exit

