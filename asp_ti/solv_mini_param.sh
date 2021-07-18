#!/usr/bin/bash 

#########
# Paths #
#########

amberdir="/state/partition1/home/jana/software/amber_dev_hybrid"
ambertoppar="/state/partition1/home/jana/simulation/amber_toppar"
robertScript="/state/partition1/home/rharris/projects/amber_phmd/scripts"

######################
# Standard Variables #
######################

protein="asp"    # Name of titratable residue 
                 # Current Options: [asp] [glu] [lys] [arg] [cys] [his] 
conc=0.15        # Salt Concentration, Implicent Salt Concentration 
#exions=0        # Adding an explicit number of ions is a feature that we will add later
stemp=50         # Start temp for heating 
etemp=300        # End temp for heating 
itemp=50         # Temp to incrment the heating by 
crysph=7.0       # Starting pH, can come from cyrstal structure for protein 

cutoff=8.0       # Nonbond cutoff small system 9.0 ang, otherwise use 12.0 ang.

########################
# Minimization Options #
########################

nsteps=5000      # Number of total minimization steps
nsdsteps=1000     # Initial amount of total minimization as SD steps 
wfrq=50         # How often to write ene. vel. temp. restart and lamb.

################
# PHMD Options #
################

lfrq=250         # How often to print lambda values for heating, equil., and prod. 

################################################
# 1.) Building $protein in a water box - TLEaP #
#----------------------------------------------#
#     Make build.in                            #
################################################


declare -A titras

titras=(["asp"]="AS2" ["glu"]="GL2" ["lys"]="LYS" ["arg"]="ARG" ["his"]="HIP" ["cys"]="CYS")


echo "# Reads in the FF
source $amberdir/dat/leap/cmd/leaprc.protein.ff14SB     # Load protein 
source $amberdir/dat/leap/cmd/leaprc.water.tip3p        # Load pre-equilibrated water

set default PBradii mbondi3                             # Modifies GB radii to mbondi3 set, needed for IGB8 this is the version of the GB
loadOff $ambertoppar/phmd.lib                           # load modified library file, loads definitions for AS2 GL2 (ASPP AND GLUPP)
phmdparm = loadamberparams $ambertoppar/frcmod.phmd     # load modifications to bond length and dihedrals, and raises dihe barrier.
$protein = sequence { ACE ${titras[$protein]}  NHE }                     # Builds a blocked asp  ACE-ASP-NHE
saveamberparm $protein solute.parm7 temp.rst7           # generates the parameter files and coords file
solvateoct $protein TIP3PBOX 12.0                       # solvate the molecule in an octahedral water box with a cushion of 12 Ang. 
#addions $protein Cl- $exions                           # Add ions, in this case no ions are added.
saveamberparm $protein ${protein}.parm7 ${protein}.rst7 # Outputs solvated parm and restart files
quit" > build.in

# Run tleap
$amberdir/bin/tleap -f build.in
#rm build.in  ----------------------------------------------------------------------------------------> rm build.in 

###  Following allows for the construction of a PDB file for view in PDB 
source $amberdir/amber.sh 

# Make a PDB File 
$amberdir/bin/cpptraj -p ${protein}.parm7 -y ${protein}.rst7 -x ${protein}.pdb 

$robertScript/generate_exclusions $protein.pdb $protein > temp.in  
cat temp.in | $amberdir/bin/parmed

# Changes the radii of the N atoms in HIS to 1.17 Ang. and rewrite *.parm7 file. 
$robertScript/radii_change ${protein}.pdb ${protein}_exclusions.parm7 > ${protein}.parm7
rm ${protein}_exclusions.parm7 

#############################
# 2.)  Perform Minimization #
#---------------------------#
#      Make mini.mdin       #
#############################

nres=$( grep "FLAG POINTERS" -A 3 solute.parm7 | tail -n 1 | awk '{print $2}' )  

echo "Solvated minimization
&cntrl                                         ! cntrl is a name list, it stores all conrol parameters for amber
  imin = 1, maxcyc = $nsteps, ncyc = $nsdsteps ! Do minimization, max number of steps (Run both SD and Conjugate Gradient), first 250 steps are SD
  ntx = 1,                                     ! Initial coordinates
  ntwe = 0, ntwr = $wfrq, ntpr = $wfrq,        ! Print frq for energy and temp to mden file, write frq for restart trj, print frq for energy to mdout 
  ntc = 1, ntf = 1, ntb = 1, ntp = 0,          ! Shake (1 = No Shake), Force Eval. (1 = complete interaction is calced), Use PBC (1 = const. vol.), Use Const. Press. (0 = no press. scaling)
  cut = $cutoff,                               ! Nonbond cutoff (Ang.)
  ntr = 1, restraintmask = ':1-$nres&!@H=',    ! restraint atoms (1 = yes), Which atoms are restrained 
  restraint_wt = 100.0,                        ! Harmonic force to be applied as the restraint
  ioutfm = 1, ntxo = 2,                        ! Fomrat of coor. and vel. trj files, write NetCDF restrt fuile for final coor., vel., and box size
/" > mini.mdin

mpirun -np 2 $amberdir/bin/pmemd.MPI -O -i mini.mdin -c ${protein}.rst7 -p ${protein}.parm7 -ref ${protein}.rst7 -r mini.rst7 -o mini.out 

rm mini.mdin 

##################################################
# 3.) Create the phmdin file for following steps #
##################################################

nsolute=$( grep "FLAG POINTERS" -A 2 solute.parm7 | tail -n 1 | awk '{print $1}' )

echo "&phmdin
    nsolute = $nsolute,                         ! Number of Solute Atoms
    QMass_PHMD = 10,                            ! Mass of the Lambda Particle
    Temp_PHMD = 300,                            ! Temp of the lambda particle
    phbeta = 5,                                 ! Friction Coefficient (1/ps) for titration integrator
    iphfrq = 5,                                 ! Frequency to update the lambda forces
    NPrint_PHMD = $lfrq,                        ! How often to print the lambda
    PrLam = .false.,                             ! Should lambda be printed
    PrDeriv = .true.,                          ! Do you want to print the derivatives?
    PRNLEV = 7,                                 ! Sets what is printed out, (7) normal print level
    PHTest = 1,                                 ! Are lambda and theta fixed, (0) = not fixed, (1) = fixed
    MaskTitrRes(:) = 'AS2','GL2','HIP',         ! Residues to include as titratable
    MaskTitrResTypes = 3,                       ! number of titratable residues
    QPHMDStart = .false.,                        ! Initialize velocities of titration varibles with a Boltzmann distribution
/" > phmdin 

rm logfile mdinfo temp.in temp.rst7 leap.log 
rm ${protein}.pdb  
