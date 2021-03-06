#! /bin/bash
#
# Copyright 2010-2015 CERN and Helsinki Institute of Physics.
# This software is distributed under the terms of the
# GNU General Public License version 3 (GPL Version 3),
# copied verbatim in the file LICENCE.md. In applying this
# license, CERN does not waive the privileges and immunities granted to it
# by virtue of its status as an Intergovernmental Organization
# or submit itself to any jurisdiction.
#
# Project website: http://arcpic.web.cern.ch/
# Developers: Helga Timko, Kyrre Sjobak, Lotta Mether
#

if [ "$#" -ne 3 ] ; then
    echo "Usage: 2Dpic_zoomcoord.sh <mintime> <maxtime> <every nth frame to analyse>" > /dev/stderr
    echo "Zoom in on coordinate plots for 2D Arc-PIC code. " > /dev/stderr
    echo "Run in folder run_name/gle " > /dev/stderr
    echo "Eg. to analyse all frames: 2Dpic_zoomcoord.sh 10 200010 1"
    exit
fi

min=$1
max=$2
nth=$3

step1=`head -2 ../out/timeIndex.dat | tail -1 | awk '{print $1}'`
step2=`head -3 ../out/timeIndex.dat | tail -1 | awk '{print $1}'`
step=`echo | awk -v step1=$step1 -v step2=$step2 -v nth=$nth '{ printf "%d", step2-step1*nth}'`
code=`echo | awk -v m=$min '{ printf "%08ld", m}'`

echo "Starting code is $code"
echo "Timestep is $step"


### RESCALING DATA TO DIMENSIONAL VALUES ###

ne=`grep "Reference density in 1/cm3:" ../input.txt | awk '{print $5}'`
Te=`grep "Reference temperature in eV:" ../input.txt | awk '{print $5}'`
nr=`grep "Number of cells nr, nz:" ../input.txt | awk '{print $6}'`
nz=`grep "Number of cells nr, nz:" ../input.txt | awk '{print $7}'`
dz=`grep "Grid size dz in Debyes:" ../input.txt | awk '{print $6}'`
dt=`grep "Timestep dt in Omega_pe-s:" ../input.txt | awk '{print $5}'`
dt_out=`grep "Outputting time dt_out in O_pe-s:" ../input.txt | awk '{print $6}'`

echo "Parameters"
echo "ne= $ne Te= $Te"
echo "nr= $nr nz= $nz"
echo "dz= $dz dt= $dt"
echo "dt_out= $dt_out"

### *** ###


# PRINT OUT TIME (in ns)
rm time.dat
cat ../out/timeIndex.dat | awk -v dt=$dt -v ne=$ne '{omega=56414.6*sqrt(ne); t=$1; time=t*dt*1e+9/omega; printf "%08ld %1.2f \n", t, time}' > time.dat

rm -r pngs/zoomcoord
mkdir pngs/zoomcoord




k=1
for ((i=$min; i<=$max; i=i+$step)); do

  now_is=`grep "$code" time.dat | awk '{print $2}'`
  echo "Now is $now_is"
  #echo "$i"


### COORDINATES ###

    rm re.dat rCu.dat rCup.dat

    # dummy line
    echo | awk '{printf "%.4e %.4e %.4e \n", -10,0,0;}' > re.dat
    echo | awk '{printf "%.4e %.4e %.4e \n", -10,0,0;}' > rCu.dat
    echo | awk '{printf "%.4e %.4e %.4e \n", -10,0,0;}' > rCup.dat

    # create temporary file with rescaled values
    cat ../out/re${code}.dat | awk -v ne=$ne -v Te=$Te '{Ld=sqrt(552635*Te/ne); z=$1; r=$2; z=z*Ld*10000; r=r*Ld*10000; if (($1<5.0)&&($2<5.0)) {printf "%.4e %.4e %.4e \n", z,r,-1*r;}}' >> re.dat	
    cat ../out/rCu${code}.dat | awk -v ne=$ne -v Te=$Te '{Ld=sqrt(552635*Te/ne); z=$1; r=$2; z=z*Ld*10000; r=r*Ld*10000; if (($1<5.0)&&($2<5.0)) {printf "%.4e %.4e %.4e \n", z,r,-1*r;}}' >> rCu.dat	
    cat ../out/rCup${code}.dat | awk -v ne=$ne -v Te=$Te '{Ld=sqrt(552635*Te/ne); z=$1; r=$2; z=z*Ld*10000; r=r*Ld*10000; if (($1<5.0)&&($2<5.0)) {printf "%.4e %.4e %.4e \n", z,r,-1*r;}}' >> rCup.dat	



### GLE FILE ###

    eval "sed -e '/ ns / c\write \" $now_is ns \" ' <zoomcoord.gle >zoomcoord_tmp.gle "

# HIGH RESOLUTION/LOW RESOLUTION
#    gle -d png -dpi 300 -o coord${k} coord_tmp.gle
    kk=`echo | awk -v k=$k '{ printf "%03ld", k}'`
    #gle -d png -dpi 400 -o zoomcoord${kk} zoomcoord_tmp.gle
    gle -d png -o zoomcoord${kk} zoomcoord_tmp.gle
    mv zoomcoord${kk}.png pngs/zoomcoord/.


  k=`echo $(($k+1))`
  code=`echo | awk -v i=$i -v s=$step '{x=i+s; printf "%08ld", x;}'`
  echo "code is $code"
		


done


#rm coord_tmp.gle
#ffmpeg -sameq -r 20 -f image2 -i pngs/zoomcoord/zoomcoord%03d.png  pngs/zoomcoord/movie_zoomcoord.mpg # only with low-resolution pictures

echo "Done with analysis!"






