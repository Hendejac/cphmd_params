#!/bin/sh

# usage : getS_fitpKa_plot.sh pH-#[infile(s)].sx [project name] [low pH] [high pH]

# Shen Lab: University of Oklahoma: Jason Wallace {9/17/2008}

######################################################################################################
# FILES/PROGRAMS REQUIRED:
# .sx files at multiple pH or one pH condition,xmgrace,gnuplot

# WHAT SCRIPT DOES:
# The script extracts the fraction of deprotonated states {S} for the selected residues then fits them to the correct functional form where pka and hill coefficient are adjustable parameters. There is a file created called {project}_all_pka.data that contains all pKa informattion for easy viewing. The script then plots the S data for the different pH conditions along with the fitted curve. {There also are notes in each 'section' of the script that gives more detail.}

#FILES CREATED:

# There are generic input files created each time for using gnuplot and xmgrace in batch mode. These files are modified for each set of data to be fit and plotted.
# The output of the script is three files for each residue chosen. One file contains the raw S vs pH data "{project}-{resnumber}.data". Notice that only protonation fraction is of interest. .sx file also has tauromeric fraction you may want to check out. The second file contains the parameters ( pka and n ) fit to the data, as well as information about the quality of the fit "fit_pka_{project}-{resnumber}.data". The third file is a figure for each selected residue in .ps format "{project}-{resnumber}.data-gnuplot.ps". Notice also that there is one line of the .sx file for each residue not used. This is tauromer fraction.
#######################################################################################################

#Input variables
#######################################################################################################
if [ $# -lt 4 ]; then
	echo -e "Usage : getS_fitpKa_plot.sh pH-#[infile(s)].sx [project name] [low pH] [high pH] [initial a1 (default: 4.0)] [initial a0 (default: 1.0)]"
    exit
fi

infile=$1   #some set of ph-X${infile}$.sx files less .sx# 
project=$2  #the name {protein name?} you choose to associate with this set of .sx
lowph=$3    #lower boundary of pH
hiph=$4     #upper boundary of pH

if [ $# -gt 4 ]; then
    a1=$5
else
    a1=4.0
fi
if [ $# -gt 5 ]; then
    a0=$6
else
    a0=1.0
fi

lres=`wc -l *${infile}*.sx | sed -n '1p' | awk '{print $1}'`

# getS_fitpka_plot.sh ph-X[infile].sx [arbitrary name]
######################################################################################################

rm -f *${project}*ps
rm -f *${project}*png
rm -f *${project}*pka*.dat
rm -f *${project}*pka*.data

numfiles=0
echo "---------------------------------------"
echo "---------------------------------------"
echo "The following .sx files are being read:"
echo "---------------------------------------"
for files in `ls *${infile}*.sx` ; do
    echo "$files"
    numfiles=$(($numfiles+1))
done
echo "---------------------------------------"

if [ $numfiles != 1 ] ; then
echo "THERE ARE $numfiles FILES."
fi
if [ $numfiles -eq 1 ] ; then
echo "THERE IS $numfiles FILE."
fi

######################################################################################################

# Make generic files that will be modified and used with xmgrace and gnuplot
# gnuplot file
if [ $numfiles != 1 ] ; then
#echo 'set term post color land enhan "Helvetica"' > gnuplot_file
echo 'set term epslatex size 2.6in, 2.6in color' > gnuplot_file
echo 'set output "NAMEOUT_partial.tex"' >> gnuplot_file
echo 'set xtics nomirror out' >> gnuplot_file
echo 'set ytics nomirror out' >> gnuplot_file
echo 'set title "TITLE"' >> gnuplot_file
echo 'set xlabel "pH"' >> gnuplot_file
echo 'set ylabel "S"' >> gnuplot_file
echo 'set border 3' >> gnuplot_file
echo "set xrange [$lowph:$hiph]" >> gnuplot_file
echo 'set yrange [-.1:1.1]' >> gnuplot_file
echo 'unset key' >> gnuplot_file
echo "plot 'DATA' ti 'data' pt 7 lc rgb 'black', 1 / (1 + 10**(N_PARAM*(PKA_PARAM-x))) lt -1 lc rgb 'black' ti 'fit'" >> gnuplot_file
fi

if [ $numfiles -eq 1 ] ; then
#echo 'set term post' > gnuplot_file
echo 'set term png' > gnuplot_file
echo 'set output "NAMEOUT.png"' >> gnuplot_file
echo 'set title "TITLE"' >> gnuplot_file
echo 'set pointsize 2.5' >> gnuplot_file
echo 'set xlabel "pH"' >> gnuplot_file
echo 'set ylabel "S"' >> gnuplot_file
echo 'set xrange [0:14]' >> gnuplot_file
echo 'set yrange [-.1:1.1]' >> gnuplot_file
echo 'set key right bottom' >> gnuplot_file
echo "plot 'DATA' ti 'data' pt 2, 1 / (1 + 10**(1*(PKA_PARAM-x))) ti 'fit'" >> gnuplot_file
fi


# xmgrace file
if [ $numfiles != 1 ] ; then 
echo 'fit formula "y = 1 / (1 + 10^( a0*( a1-x )))"' > grace_file
echo "fit with 2 parameters" >> grace_file
echo "fit prec 0.01" >> grace_file
echo "a0 = $a0" >> grace_file
echo "a0 constraints off" >> grace_file
#echo "a0 constraints on" >> grace_file
#echo "a0min = 0" >> grace_file
#echo "a0max = 2" >> grace_file
echo "a1 = $a1" >> grace_file
echo "a1 constraints off" >> grace_file
#echo "a1 constraints on" >> grace_file
#echo "a1min = 0" >> grace_file
#echo "a1max = 14" >> grace_file
echo "nonlfit (s0, 100)" >> grace_file
fi

grace_input=./grace_file
gnuplot_input=./gnuplot_file

#####################################################################################################
# Write some things to the screen####################################################################

echo "---------------------------------------"
echo "Project is called '$project'"

######################################################################################################
#get S values for different ph conditions
#fraction deprotonated will be saved as {project}-{resnumber}.data
######################################################################################################

echo "---------------------------------------"
echo "Extracting S for '$project' "

filenum=1
for file in `ls *$infile*.sx` ; do
 
    ph=`awk '{print $4}' < $file | sed -n '2 p'`   
     
    for i in `seq 2 1 $lres` ; do
        k=`echo $i | awk '{print $1-1}'`
        j=`echo $i | awk '{print $1+1}'`
        lastres=`head -$k ${file} | tail -1 | awk '{print $2}'`
        thisres=`head -$i ${file} | tail -1 | awk '{print $2}'`
        nextres=`head -$j ${file} | tail -1 | awk '{print $2}'`
       if [ $thisres != $lastres ] ; then
             taut=0
             s=`sed -n "$i p" $file | awk '{print $5}'`
	     echo "$s"
                if [ $filenum -eq 1 ] ; then 
                    echo "$ph" "$s" > ${project}-${thisres}.data
                    if [ $numfiles -eq 1 ] ; then
                         s=`awk '{print $2}' ${project}-${thisres}.data | head -1`
                         ph=`awk '{print $1}' ${project}-${thisres}.data | head -1` 
                         pka=`echo $s $ph | awk '{print $2 + (1/2.303)*log((1/$1)-1)}'`
                         echo $pka > ${project}-${thisres}_pka.data
                    fi
                fi
                if [ $filenum != 1 ] ; then 
                    echo "$ph" "$s" >> ${project}-${thisres}.data
                fi
       #For tautomers
       else
             s=`sed -n "$i p" $file | awk '{print $5}'`
             taut=`expr $taut + 1`;
             echo "$s"
                if [ $filenum -eq 1 ] ; then
                    echo "$ph" "$s" > ${project}-${thisres}-taut${taut}.data
                    if [ $numfiles -eq 1 ] ; then
                         s=`awk '{print $2}' ${project}-${thisres}-taut${taut}.data | head -1`
                         ph=`awk '{print $1}' ${project}-${thisres}-taut${taut}.data | head -1`
                         pka=`echo $s $ph | awk '{print $2 + (1/2.303)*log((1/$1)-1)}'`
                         echo $pka > ${project}-${thisres}-taut${taut}_pka.data
                    fi
                fi
                if [ $filenum != 1 ] ; then
                    echo "$ph" "$s" >> ${project}-${thisres}-taut${taut}.data
                fi
       fi
    done

    filenum=$(($filenum+1))

done

######################################################################################################
#use grace to fit equation
#fitting info will be saved for each res as fit_pka_{project}-{resnumber}.data
#all pKas are compiled in pka_all_{project}.data
######################################################################################################

if [ $numfiles != 1 ] ; then
echo "---------------------------------------"
   echo "Fitting data for '$project'"

   for name in $project*.data ; do

        graceout=`echo $name | sed 's/.data/_pka.data/g'`

        xmgrace -hardcopy $name -batch $grace_input > $graceout

        rm -f $project*.png
   done 
           echo "#resi" "pka" "n" "corr" > ${project}_all_pka.dat
       
   for name in ${project}-*_pka.data; do        
        resi=`echo $name | sed "s/_pka.data//g;s/${project}-//g"`
        p1=`sed -n '8p' $name | awk '{print $3}'`
        p2=`sed -n '9p' $name | awk '{print $3}'`
        p3=`sed -n '12p' $name | awk '{print $3}'`
        echo "$resi   " "$p2  " "$p1  " "$p3  " >> ${project}_all_pka.dat
       
   done
else
    echo "#resi" "pka" > ${project}_all_pka.dat
    for name in ${project}-*_pka.data ; do
       resi=`echo $name | sed "s/_pKa.data//g;s/${project}//g"`
       pka=`sed -n '1p' $name | awk '{print $1}'`
       echo "$resi" "$pka" >> ${project}_all_pka.dat
    done
fi

cat ${project}_all_pka.dat | sort -k1 -n > tmp
mv tmp ${project}_all_pka.dat

######################################################################################################
#use gnuplot to plot data and fitted function then save as .ps 
#image of fit and data will be saved as {project}-{resnumber}.data-gnuplot.ps
######################################################################################################
echo "---------------------------------------"
echo "Making nice plot(s) for '$project'"
echo "---------------------------------------"

for name in ${project}-*_pka.data ; do 

    psout=`echo $name | sed 's/_pka.data//g'`
    data=`echo $name | sed 's/_pka.data/.data/g'` 
 
    if [ $numfiles != 1 ] ; then
       p1=`sed -n '8p' $name | awk '{print $3}'`
       p2=`sed -n '9p' $name | awk '{print $3}'`
    fi
 
    if [ $numfiles -eq 1 ] ; then
       p1=1
       p2=`sed -n '1p' ${name} | awk '{print $1}'`
    fi

    testinf=`echo "$p2" | sed s/-//g | sed s/+//g`
    if [ $testinf != Infinity ] ; then
    sed s/NAMEOUT/$psout/ $gnuplot_input > temp.file
    sed s/TITLE/$psout/ temp.file > temp1.file
    sed s/DATA/$data/ temp1.file > temp2.file
    sed s/N_PARAM/$p1/ temp2.file > temp3.file
    sed s/PKA_PARAM/$p2/ temp3.file > $name-gnuplot
    rm -f temp*.file

    gnuplot $name-gnuplot

    fi
    rm -f $name-gnuplot

done


# END 

