#!/bin/bash
########################################################################
# README
#
# Warning:
# Use this script with caution. Not understanding what and how it does may lead to data loss!
#
# You need:
# - Timed out / not converged NEB
# - This script
# - A single INCAR (multiple not supported)
#
# DO NOT CHANGE:
# -
#
# Does not support:
# - Automatic copying of WAVECAR/CHGCAR
#
##################

##################
# Defaults
# change with care to suit your setup
##################
########################################################################

##################
# Script
##################
set -e

function restart()
{
   echo "Preparing restart..."
   #find highest numeric subfolder
   n="$(find . -maxdepth 1 -name "*[0-9]-NEB" -type d | sort -Vr | head -1 | sed 's/.\///' | sed 's/-NEB//')"
   n=$((n+1))
   echo -n "Moving files to subdir ${n}-NEB, "
   mkdir ${n}-NEB || { echo 'mkdir failed' ; exit 1; }
   #move files to subfolder n-NEB
   mv vasprun.xml ./${n}-NEB/
   mv *.out ./${n}-NEB/
   echo "... Done!"

   nImages="$(find . -maxdepth 1 -name "*[0-9]" -type d | sort -Vr | head -1 | sed 's/.\///')"
   for (( i=1; i<$nImages; i++  ))
   do
      pi=$(printf "%02d" $i)
      echo "Image $pi"
      mv $pi ${n}-NEB/
      mkdir $pi
      cd $pi
      #save space by creating symlinks
      ln -s ../${n}-NEB/$pi/CONTCAR POSCAR
      cd ..
   done
   echo "Resubmit your calculation now"
}

restart
exit 0
