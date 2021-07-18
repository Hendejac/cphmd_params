#!/bin/tcsh
# fit average forces to get phmd parameters

if ($#argv < 1) then
USAGE:
    echo "Fit average forces to get phmd parameters."
    echo "Usage: pmf_2d_fit.sh <residue name ([xxx].theta...thetx...)> [>0: weighted fit (default:0, no weight)]"
    exit 1
endif

if ($#argv >= 1) then
   set name  = $argv[1]
   if ($#argv >= 2) then
       set weight = $argv[2]
   else
       set weight = 0
   endif
endif

if ($weight > 0) then
   set cols = "1:2:3"
   set errbar = "with errorbars"
else
   set cols = "1:2"
   set errbar = ""
endif


#set fitting functions
cat << EOF > gnuplot.dat
set terminal png
set output "outpng"
set xlabel "XNAME"
set ylabel "YNAME"
f(x)=2*a0*sin(2*x)*(sin(x)**2-a1); #fitting function
a0=-30; a1=0.5; #intial values
fit f(x) 'datafile' using $cols via a0,a1
plot 'datafile' using $cols $errbar title "Data", f(x) title "Fit"
EOF
cat << EOF > gnuplot2.dat
set terminal png
set output "outpng"
set xlabel "XNAME"
set ylabel "YNAME"
f(x)=a0*sin(x)**4+a1*sin(x)**2+a2; #fitting function
fit f(x) 'datafile' using $cols via a0,a1,a2
plot 'datafile' using $cols $errbar title "Data", f(x) title "Fit"
EOF
cat << EOF > gnuplot3.dat
set terminal png
set output "B.theta.png"
set xlabel "Theta"
set ylabel "B(theta)"
f(x)=a0; #fitting function
fit f(x) 'B.theta' using $cols via a0
plot 'B.theta' using $cols $errbar title "Data", f(x) title "Fit"
EOF

#theta: no pi/2 for Asp/Glu; No 0 for His
if ($name == "glu" || $name == "asp" || $name == "penta-as2" || $name == "penta-gl2") then
    set list_theta = "0.0 0.2 0.4 0.6 0.7854 1.0 1.2 1.4" # No pi/2 for Asp/Glu; No 0 for His
else
  echo "Only use for Asp/Glu!"
  exit
endif
set list_thetx = "0.0 0.2 0.4 0.6 0.7854 1.0 1.2 1.4 1.5708"

printf "#Theta\tA(theta)\tAerror\n" > A.theta
printf "#Theta\tB(theta)\tBerror\n" > B.theta
foreach theta ($list_theta)

    awk -v theta=$theta '{if($1~/^#/) printf "#"; if(($1~/^#/||$1==theta)&&$5!=0) print $2,$5,$6}' $name.pmf.dat > $name.pmf.theta$theta.dat
    sed "s/datafile/$name.pmf.theta$theta.dat/;s/outpng/$name.pmf.theta$theta.png/;s/XNAME/Thetx/;s/YNAME/F(thetx)/" gnuplot.dat > gnuplot.tmp
    gnuplot < gnuplot.tmp >& $name.pmf.theta$theta.fit
    display $name.pmf.theta$theta.png
    set A = `grep -A5 'Final' $name.pmf.theta$theta.fit | grep "a0" | awk '{print $3}'`
    set Aerr = `grep -A5 'Final' $name.pmf.theta$theta.fit | grep "a0" | awk '{print $5}'`
    set B = `grep -A5 'Final' $name.pmf.theta$theta.fit | grep "a1" | awk '{print $3}'`
    set Berr = `grep -A5 'Final' $name.pmf.theta$theta.fit | grep "a1" | awk '{print $5}'`
#    xmgrace -hardcopy $name.pmf.theta$theta.dat -batch ~/charmm_scripts/grace-1.fit > $name.pmf.theta$theta.fit
#    set A = `grep "a0 =" $name.pmf.theta$theta.fit | sed -n '2 p' | awk '{print $3}'`
#    set B = `grep "a1 =" $name.pmf.theta$theta.fit | sed -n '2 p' | awk '{print $3}'`
    printf "$theta\t$A\t$Aerr\n" >>  A.theta
    printf "$theta\t$B\t$Berr\n" >>  B.theta
    if ($theta == 0.0) then
       set A10 = $A
       set A10err = $Aerr
       set B10 = $B
       set B10err = $Berr
    endif
end

printf "#Thetx\tA(thetx)\tAerror\n" > A.thetx
printf "#Thetx\tB(thetx)\tBerror\n" > B.thetx
foreach thetx ($list_thetx)
    awk -v thetx=$thetx '{if($1~/^#/) printf "#"; if(($1~/^#/||$2==thetx)&&$3!=0) print $1,$3,$4}' $name.pmf.dat > $name.pmf.thetx$thetx.dat
    sed "s/datafile/$name.pmf.thetx$thetx.dat/;s/outpng/$name.pmf.thetx$thetx.png/;s/XNAME/Theta/;s/YNAME/F(theta)/" gnuplot.dat > gnuplot.tmp
    gnuplot < gnuplot.tmp >& $name.pmf.thetx$thetx.fit
    display    $name.pmf.thetx$thetx.png
    set A = `grep -A5 'Final' $name.pmf.thetx$thetx.fit | grep "a0" | awk '{print $3}'`
    set Aerr = `grep -A5 'Final' $name.pmf.thetx$thetx.fit | grep "a0" | awk '{print $5}'`
    set B = `grep -A5 'Final' $name.pmf.thetx$thetx.fit | grep "a1" | awk '{print $3}'`
    set Berr = `grep -A5 'Final' $name.pmf.thetx$thetx.fit | grep "a1" | awk '{print $5}'`
#    xmgrace -hardcopy $name.pmf.thetx$thetx.dat -batch ~/charmm_scripts/grace-1.fit > $name.pmf.thetx$thetx.fit
#    set A = `grep "a0 =" $name.pmf.thetx$thetx.fit | sed -n '2 p' | awk '{print $3}'`
#    set B = `grep "a1 =" $name.pmf.thetx$thetx.fit | sed -n '2 p' | awk '{print $3}'`
    printf "$thetx\t$A\t$Aerr\n" >>  A.thetx
    printf "$thetx\t$B\t$Berr\n" >>  B.thetx
    if ($thetx == 1.5708) then
       set A1 = $A
       set A1err = $Aerr
       set B1 = $B
       set B1err = $Berr
    else if ($thetx == 0.0) then
       set A0 = $A
       set A0err = $Aerr
       set B0 = $B
       set B0err = $Berr       
    endif
end

sed "s/datafile/A.theta/;s/outpng/A.theta.png/;s/XNAME/Theta/;s/YNAME/A(theta)/" gnuplot2.dat > gnuplot2.tmp
gnuplot < gnuplot2.tmp >& A.theta.fit
display A.theta.png
set R1 = `grep -A5 'Final' A.theta.fit | grep "a0" | awk '{print $3}'`
set R1err = `grep -A5 'Final' A.theta.fit | grep "a0" | awk '{print $5}'`
set R2 = `grep -A5 'Final' A.theta.fit | grep "a1" | awk '{print $3}'`
set R2err = `grep -A5 'Final' A.theta.fit | grep "a1" | awk '{print $5}'`
set R3 = `grep -A5 'Final' A.theta.fit | grep "a2" | awk '{print $3}'`
set R3err = `grep -A5 'Final' A.theta.fit | grep "a2" | awk '{print $5}'`

gnuplot < gnuplot3.dat >& B.theta.fit
display B.theta.png
set R4 = `grep -A5 'Final' B.theta.fit | grep "a0" | awk '{print $3}'`
set R4err = `grep -A5 'Final' B.theta.fit | grep "a0" | awk '{print $5}'`

sed "s/datafile/A.thetx/;s/outpng/A.thetx.png/;s/XNAME/Thetx/;s/YNAME/A(thetx)/" gnuplot2.dat > gnuplot2.tmp
gnuplot < gnuplot2.tmp >& A.thetx.fit
display A.thetx.png
set R5 = `grep -A5 'Final' A.thetx.fit | grep "a2" | awk '{print $3}'`
set R5err = `grep -A5 'Final' A.thetx.fit | grep "a2" | awk '{print $5}'`

sed "s/datafile/B.thetx/;s/outpng/B.thetx.png/;s/XNAME/Thetx/;s/YNAME/B(thetx)/" gnuplot2.dat > gnuplot2.tmp
gnuplot < gnuplot2.tmp >& B.thetx.fit
display B.thetx.png
set R6 = `grep -A5 'Final' B.thetx.fit | grep "a2" | awk '{print $3}'`
set R6err = `grep -A5 'Final' B.thetx.fit | grep "a2" | awk '{print $5}'`

#output all parameters
printf "#Para\tValue\tError\n" > Para.dat
printf "A1\t$A1\t$A1err\n" >> Para.dat
printf "B1\t$B1\t$B1err\n" >> Para.dat
printf "A0\t$A0\t$A0err\n" >> Para.dat
printf "B0\t$B0\t$B0err\n" >> Para.dat
printf "A10\t$A10\t$A10err\n" >> Para.dat
printf "B10\t$B10\t$B10err\n" >> Para.dat
printf "R1\t$R1\t$R1err\n" >> Para.dat
printf "R2\t$R2\t$R2err\n" >> Para.dat
printf "R3\t$R3\t$R3err\n" >> Para.dat
printf "R4\t$R4\t$R4err\n" >> Para.dat
printf "R5\t$R5\t$R5err\n" >> Para.dat
printf "R6\t$R6\t$R6err\n" >> Para.dat

rm gnuplot.dat gnuplot2.dat gnuplot3.dat gnuplot.tmp gnuplot2.tmp fit.log

exit
