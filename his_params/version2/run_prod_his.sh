#/bin/bash 

##########################
#  General Information   #
##########################

amberdir="/home/jackh/Software/amber_dev_gpu"
pmemddir="/home/jackh/Software/amber_dev_gpu/bin/pmemd.cuda"
toppar="../amber_toppar"
robertScript="../scripts"

# Standard Variables 
protein="his"    # Name 
conc=0.15        # Salt Concentration, Implicent Salt Concentration 
exions=0
etemp=300        # Temp.
crysph=7.0       # Starting pH, can come from cyrstal structure for protein 

cutoff=999.0       # Nonbond cutoff small system 9.0 ang, otherwise use 12.0 ang.

#######################
# Production Specific #
#######################

pnsteps=50000    
pwfrq=500       
pwrst=50000      
pts=0.002

##############
# Production #
##############

echo "Production of $protein
 &cntrl
  imin=0, nstlim=$pnsteps, dt=$pts, 
  irest=0, ntx=1, ig=-1, 
  tempi=$etemp, temp0=$etemp, 
  ntc=2, ntf=2, tol = 0.00001,
  ntwx=$pwfrq, ntwe=$pwfrq, ntwr=$pwrst, ntpr=$pwfrq, 
  cut=$cutoff, iwrap=0, 
  ntt=3, gamma_ln=1.0,
  iphmd=1, igb=8, solvph=$crysph, saltcon=$conc,
/" > prod.mdin

count=1
thetxs1=( 0.2 0.4 0.6 0.7854 1.0 1.2 1.4 )  
for thetx in ${thetxs1[@]}
do
    theta=1.5708
    echo "&phmdstrt
           ph_theta = $theta,$thetx
           vph_theta = 0.0,0.0
         /" > phmdstrt_${theta}_${thetx}.in
    if (( $count % 2 == 0 ))
    then
        export CUDA_VISIBLE_DEVICES=1
        $pmemddir -O -i prod.mdin -c mini.rst7 -p ${protein}.parm7 -phmdparm $toppar/input_original.parm -phmdout prod_${theta}_${thetx}.lambda -phmdstrt phmdstrt_${theta}_${thetx}.in -o prod_${theta}_${thetx}.mdout -r prod_${theta}_${thetx}.rst7 &
        wait
        #echo "1: Theta: $theta, Theta X: $thetx"
        #echo "wait"
    else
        export CUDA_VISIBLE_DEVICES=0
        $pmemddir -O -i prod.mdin -c mini.rst7 -p ${protein}.parm7 -phmdparm $toppar/input_original.parm -phmdout prod_${theta}_${thetx}.lambda -phmdstrt phmdstrt_${theta}_${thetx}.in -o prod_${theta}_${thetx}.mdout -r prod_${theta}_${thetx}.rst7 &
        #echo "0: Theta: $theta, Theta X: $thetx"
    fi
    count=$((count+1))
done

thetxs2=( 0.0 1.5708 )
thetas2=( 0.2 0.4 0.6 0.7854 1.0 1.2 1.4 )
for thetx in ${thetxs2[@]}
do
    for theta in ${thetas2[@]}
    do
        echo "&phmdstrt
              ph_theta = $theta,$thetx
              vph_theta= 0.0,0.0
             /" > phmdstrt_${theta}_$thetx.in
        if (( $count % 2 == 0 ))
        then
            export CUDA_VISIBLE_DEVICES=1
            $pmemddir -O -i prod.mdin -c mini.rst7 -p ${protein}.parm7 -phmdparm $toppar/input_original.parm -phmdout prod_${theta}_${thetx}.lambda -phmdstrt phmdstrt_${theta}_${thetx}.in -o prod_${theta}_${thetx}.mdout -r prod_${theta}_${thetx}.rst7 &
            wait
            #echo "1: Theta: $theta, Theta X: $thetx"
            #echo "wait"
        else
            export CUDA_VISIBLE_DEVICES=0
            $pmemddir -O -i prod.mdin -c mini.rst7 -p ${protein}.parm7 -phmdparm $toppar/input_original.parm -phmdout prod_${theta}_${thetx}.lambda -phmdstrt phmdstrt_${theta}_${thetx}.in -o prod_${theta}_${thetx}.mdout -r prod_${theta}_${thetx}.rst7 &
            #echo "0: Theta: $theta, Theta X: $thetx"
        fi 
        count=$((count+1))
    done
done 

exit
