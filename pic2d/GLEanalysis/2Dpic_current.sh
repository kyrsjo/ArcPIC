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

if [ "$#" -ne 1 ] ; then
    echo "Usage: 2Dpic_current.sh <ionsteps>" > /dev/stderr
    echo "Generates current flow plots for 2D Arc-PIC code. " > /dev/stderr
    echo "Run in folder run_name/gle " > /dev/stderr
    echo "Eg. 2Dpic_current.sh 5000"
    exit
fi

#min=$1
#max=$2
isteps=$1

step1=`head -2 ../out/timeIndex.dat | tail -1 | awk '{print $1}'`
step2=`head -3 ../out/timeIndex.dat | tail -1 | awk '{print $1}'`
step=`echo | awk -v step1=$step1 -v step2=$step2 '{ printf "%d", step2-step1}'`


### RESCALING DATA TO DIMENSIONAL VALUES ###

ne=`grep "Reference density in 1/cm3:" ../input.txt | awk '{print $5}'`
Te=`grep "Reference temperature in eV:" ../input.txt | awk '{print $5}'`
#dz=`grep "Grid size dz in Debyes:" ../input.txt | awk '{print $6}'`
dt=`grep "Timestep dt in Omega_pe-s:" ../input.txt | awk '{print $5}'`
#dt_out=`grep "Outputting time dt_out in O_pe-s:" ../input.txt | awk '{print $6}'`
dt_ion=`grep "Injection timestep in dt, neutrals:" ../input.txt | awk '{print $6}'`
Nd=`grep "Particles in a Debye cube Ndb:" ../input.txt | awk '{print $7}'`
#Cext=`grep "External capacitance in F:" ../input.txt | awk '{print $5}'`
#Cext=`grep "Gap capacitance in F:" ../input.txt | awk '{print $5}'`
#UNz=`grep "Potential at Zmax, UNz in Te:" ../input.txt | awk '{print $7}'`
#U0=`grep "Potential at Zmin, U0 in Te:" ../input.txt | awk '{print $7}'`

echo "Parameters"
echo "ne = $ne Te = $Te"
echo "Nd = $Nd dt = $dt" 
#echo "dz = $dz Cext = $Cext"
#echo "U0 = $U0 UNz = $UNz"
echo "dt_ion = $dt_ion"

steps=`echo $dt_ion $isteps | awk '{printf "%d", $1*$2;}'`
echo "steps = $steps"


# OUTWARD PARTICLE COUNT

echo ../arcbounds.dat | awk -v dt=$dt -v ne=$ne -v steps=$steps '{
file=$1"";
omega=56414.6*sqrt(ne);
getline < file;
getline < file;
while ((getline < file) > 0) {
  t=$1; ein0+=$2; e0+=$10; e1+=$11; e2+=$12; Cup0+=$16; Cup1+=$17; Cup2+=$18; Cu0+=$19; Cu1+=$20; Cu2+=$21;
  if ( t == 0 || t % steps == 0) {
    time=t*dt*1e+9/omega; 
    printf "%.4e %.4e %.4e %.4e %.4e %.4e %.4e %.4e %.4e %.4e %.4e\n", time,e0,Cup0,Cu0,e1,Cup1,Cu1,e2,Cup2,Cu2,ein0;
    ein0=0; e0=0; e1=0; e2=0; Cup0=0; Cup1=0; Cup2=0; Cu0=0; Cu1=0; Cu2=0;    
    }
  }
}' > out_counts.dat-tmp
string=`wc -l out_counts.dat-tmp`
lines=`echo $string | awk '{l=$1-1; print l}'`
head -n $lines out_counts.dat-tmp > out_counts.dat
rm out_counts.dat-tmp


# TOTAL CURRENT (in A) 

echo ../arcbounds.dat | awk -v dt=$dt -v ne=$ne -v Te=$Te -v Nd=$Nd -v steps=$steps '{
file=$1"";
omega=56414.6*sqrt(ne);
I=2.693026e5*steps*dt*Nd/Te/sqrt(Te);
getline < file;
getline < file;
while ((getline < file) > 0) {
  t=$1; e0+=$10; e1+=$11; e2+=$12; ein0+=$2; Cup0+=$16; Cup1+=$17; Cup2+=$18; Cu0+=$19; Cu1+=$20; Cu2+=$21;
  if ( t == 0 || t % steps == 0) {
    time=t*dt*1e+9/omega; 
    printf "%.6e %.6e %.6e \n", time,(Cup0-e0+ein0)/I, (e1-Cup1)/I;
    e0=0; e1=0; e2=0; ein0=0; Cup0=0; Cup1=0; Cup2=0; Cu0=0; Cu1=0; Cu2=0;    
    }
  }
}' > I.dat-tmp
head -n $lines I.dat-tmp > I.dat
rm I.dat-tmp


# Cathode erosion rate 

echo ../arcbounds.dat | awk -v dt=$dt -v ne=$ne -v Te=$Te -v Nd=$Nd -v steps=$steps '{
file=$1"";
omega=56414.6*sqrt(ne);
Q=658.058;
getline < file;
getline < file;
while ((getline < file) > 0) {
  t=$1; e0+=$10; e1+=$11; e2+=$12; ein0+=$2; Cup0+=$16; Cup1+=$17; Cup2+=$18; Cu0+=$19; Cu1+=$20; Cu2+=$21; Cuin0+=$8;
  if ( t == 0 || t % steps == 0) {
    time=t*dt*1e+9/omega; 
    if ( Cup0-e0+ein0 == 0 ) { printf "%.6e %.6e \n", time, 0;}
    else
    printf "%.6e %.6e \n", time, Cuin0/(Cup0-e0+ein0)*Q;
    e0=0; e1=0; e2=0; ein0=0; Cup0=0; Cup1=0; Cup2=0; Cu0=0; Cu1=0; Cu2=0; Cuin0=0;    
    }
  }
}' > erosion.dat-tmp
head -n $lines erosion.dat-tmp > erosion.dat
rm erosion.dat-tmp




# TOTAL CURRENT AND EXTERNAL POTENTIAL (in kV)

#cat ../arcbounds.dat | awk -v dt_out=$dt_out -v dt=$dt -v ne=$ne -v Te=$Te -v Nd=$Nd '{I=2.693026e5*dt_out*Nd/Te/sqrt(Te); Qfac=1.519260e10*Nd*sqrt(ne)/Te/sqrt(Te); omega=56414.6*sqrt(ne); t=$1; e1=$10; Cup1=$16; ein1=$2; e2=$11; Cup2=$17; u=$16; Q=$17; time=t*dt*1e+9/omega; tot1=Cup1-e1+ein1; tot2=e2-Cup2; u=u*Te/1000; printf "%.6e %.6e %.6e %.6e %.6e\n", time,tot1/I,tot2/I,u,Q/Qfac;}' > UI.dat


# INWARD PARTICLE COUNT

#cat ../IonWall3.dat | awk -v dt=$dt -v ne=$ne '{omega=56414.6*sqrt(ne); t=$1; eFE=$5; eSEY=$6; CuY1=$7; CuY2=$8; Cuev=$9; time=t*dt*1e+9/omega; e=e*j*1e-8; Cu=Cu*j*1e-8; printf "%.4e %.4e %.4e %.4e %.4e %.4e \n", time,eFE,eSEY,CuY1,CuY2,Cuev;}' > inw_counts.dat


# BETA EROSION, LOCAL FIELD (in GV/m)

#cat ../IonWall1.dat | awk -v dt=$dt -v ne=$ne '{omega=56414.6*sqrt(ne); t=$1; B=$7; F=$8; time=t*dt*1e+9/omega; printf "%.4e %.4e %.4e \n", time,B,F;}' > FE.dat


# POWER CONSUMED

#cat UI.dat | awk '{I=$2; u=$4; printf "%.4e \n", I*u*1000;}' > power_sign.dat
#cat UI.dat | awk -v C=$Cext '{t=$1; I=$2; Q=$5; printf "%.4e %.4e \n",t,I*Q/C;}' > charge_temp.dat

  #abs value for power
#  awk '{ for (i=1; i<=NF; i=i+1) {if ($i<0) {$i=-$i;} print; }}' < power_sign.dat > power_sign2.dat
#  paste UI.dat power_sign2.dat | awk '{t=$1; p=$6; printf "%.4e %.4e \n", t,p;}' > power_temp.dat

#  lines=`wc -l power_temp.dat | awk '{print $1}'`
#  lines=`echo $(($lines-1))`

#  head -$lines power_temp.dat > power_1.dat
#  tail -$lines power_temp.dat > power_2.dat
#  paste power_1.dat power_2.dat | awk '{ t1=$1; p1=$2; t2=$3; p2=$4; P=(p2+p1)*(t2-t1)/2; E+=P; printf "%.4e %.4e %.4e \n",t2,P,1e-9*E;}' > power_integral.dat
#  tail -1 power_integral.dat | awk '{printf "%s %.3e %s \n", "!energy",$3,"J";}' > power_header.dat
#  cat power_header.dat power_temp.dat > power.dat

#  head -$lines charge_temp.dat > charge_1.dat
#  tail -$lines charge_temp.dat > charge_2.dat
#  paste charge_1.dat charge_2.dat | awk '{ t1=$1; p1=$2; t2=$3; p2=$4; P=(p2+p1)*(t2-t1)/2; E+=P; printf "%.4e %.4e %.4e \n",t2,P,1e-9*E;}' > charge_integral.dat
#  tail -1 charge_integral.dat | awk '{printf "%s %.3e %s \n", "!energy",$3,"J";}' > charge_header.dat
#  cat charge_header.dat charge_temp.dat > charge.dat

#  tail -1 power_header.dat
#  tail -1 charge_header.dat
#  writeE=`tail -1 power_header.dat | awk '{print $2}'`
#  writeE2=`tail -1 charge_header.dat | awk '{print $2}'`

#  eval "sed -e '/!write_here/ c\write \"$writeE J\" !write_here ' -e '/!write_2here/ c\write \"$writeE2 J\" !write_2here ' <power.gle >power_tmp.gle "
#  rm power_1.dat power_2.dat power_header.dat power_temp.dat power_sign.dat power_sign2.dat
#  rm charge_1.dat charge_2.dat charge_header.dat charge_temp.dat


# PLASMA RESISTANCE

#head -299 tot.dat > tmp1_tot.dat
#tail -299 tot.dat > tmp2_tot.dat
#head -299 ext_pot.dat > tmp1_ext_pot.dat 
#tail -299 ext_pot.dat > tmp2_ext_pot.dat

#paste tmp1_tot.dat tmp2_pot.dat tmp1_ext_pot.dat tmp2_ext_pot.dat | awk '{t1=$1; t2=$3; j1=$2; j2=$4; u1=$6; u2=$8; dj=j2-j1; du=u2-u1; at=(t1+t2)/2; if(dj>0) {printf "%.4e %.4e \n", at,du/dj;}}' > plasma_resistance.dat
#paste tot.dat ext_pot.dat | awk '{ j=$2; u=$4; printf "%.4e %.4e \n", u,j;}' > characteristics.dat
#rm tmp1_tot.dat tmp2_tot.dat tmp1_ext_pot.dat tmp2_ext_pot.dat 

#####

gle -d png -r 100 -o plot_I.png I.gle
#gle -d png -o plot_FE.png FE.gle
#gle -d png -o plot_P.png power_tmp.gle
gle -d png -r 100 -o plot_erosion.png erosion.gle
gle -d png -o plot_e.png count_e.gle
gle -d png -o plot_Cup.png count_Cup.gle
gle -d png -o plot_Cu.png count_Cu.gle

#gle -d png -o resistance.png plasma_resistance.gle

#rm power_tmp.gle


