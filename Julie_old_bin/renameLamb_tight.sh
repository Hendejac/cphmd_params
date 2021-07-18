#!/bin/sh

if [ $# -lt 2 ]; then
    echo -e "Usage : renameLamb.sh [start cycle] [end cycle]"
    exit
fi

start=$1
stop=$2

for lamb in `ls *lamb*` ; do
 
    new=`echo $lamb | sed "s/.*ph/ph/g;s/temp.*lamb.*/lambda/g;s/lamb.*/lambda/g;s/_lambda/.lambda/g"`
    ph=`echo $new | sed "s/.lambda//g;s/ph//"`
    echo $lamb $new $ph

    mv $lamb $new

#    CptSX_lessx.pl $new $start $stop $ph
    CptSX_lessx_taut_tight.pl $new $start $stop $ph

done


#for i in `ls *lambda*`; do 
#cp $i BACE2.${i}
#rm $i
#done






