#!/bin/bash
########################################################################
# README
#
# Warning:
# Use this script with caution. Not understanding what and how it does may lead to data loss!
# Only tested for GO so far.
#
# You need:
# - Input files
# - This script
# - Settings in INCAR to write either WAVECAR or CHGCAR for restarts
#
# DO NOT CHANGE:
# -
#
# Supports (tested):
# - Automatic restart of GO optimizations until convergence
#
#
##################

##################
# Defaults
# change with care to suit your setup
##################
RUNSCRIPT="vasp-chainjob.run" # name of the runscript 
ISTART_RESTART=1 #https://www.vasp.at/wiki/index.php/ISTART, if you want continous GO with varying volume you might want to change to 2
ignore=("KPOINTS" "POTCAR" "$RUNSCRIPT" "INCAR") # files that stay where they are during restart
########################################################################

##################
# Script
##################
set -e

function set_incar_option()
{
   #$1: keyword, $2 value
   echo "Processing INCAR for key $1"
   if grep -i "[[:space:]]*$1[[:space:]]*=[[:space:]]*$2" INCAR | grep -qv "[[:space:]]*#[[:space:]]*$1[[:space:]]*=[[:space:]]*"
   then
      echo "- $1=$2 already set"
   else
      echo -n "- Setting $1=$2"
      if grep -iq "$1" INCAR
      then
         echo " by changing value"
         sed -i "s/[[:space:]]*$1[[:space:]]*=[[:space:]]*[0-9]/$1=$2/I" INCAR
      else
         echo " by appending to INCAR"
         echo "$1=$2" >> INCAR
      fi
   fi
}

function set_wavecar_chgcar()
{
   echo "Copying WAVECAR+CHGCAR+INCAR and setting options..."
   cp ./${1}/WAVECAR .
   cp ./${1}/CHGCAR .
   cp INCAR ./${1}/
   set_incar_option ISTART $ISTART_RESTART
   set_incar_option ICHARG 1
   echo "... Done!"
}
function set_wavecar()
{
   echo "Copying WAVECAR+INCAR and setting options..."
   cp ./${1}/WAVECAR .
   cp INCAR ./${1}/
   set_incar_option ISTART $ISTART_RESTART
   set_incar_option ICHARG 0
   echo "... Done!"
}
function set_chgcar()
{
   echo "Copying CHGCAR+INCAR and setting options..."
   cp ./${1}/CHGCAR .
   cp INCAR ./${1}/
   set_incar_option ISTART 0
   set_incar_option ICHARG 1
   echo "... Done!"
}

function restart()
{
   echo "Preparing restart..."
   #find highest numeric subfolder
   n="$(find . -name "*[0-9]" -type d | sort -Vr | head -1 | sed 's/.\///')"
   n=$((n+1))
   echo -n "Moving files to subdir ${n}, "
   mkdir ${n} || { echo 'mkdir failed' ; exit 1; }
   #move all files to subfolder n, except these:
   #not sure why joint f l does not work, so have to run second time for symlinks
   echo -n "Ignoring these files: ${ignore[*]}, moving all others..."
   find . -maxdepth 1 -type f -not -name "${ignore[0]}" $(printf -- '-not -name %s ' "${ignore[@]:1}") -exec mv -t ./${n}/ {} + || { echo 'moving files failed' ; exit 1; }
   find . -maxdepth 1 -type l -not -name "${ignore[0]}" $(printf -- '-not -name %s ' "${ignore[@]:1}") -exec mv -t ./${n}/ {} + || { echo 'moving symlinks failed' ; exit 1; }
   echo "... Done!"

   #save space by creating symlinks
   echo -n "Create symlinks..."
   ln -s ./${n}/CONTCAR POSCAR
   echo "... Done!"

   if [[ -s ./${n}/WAVECAR ]] && [[ -s ./${n}/CHGCAR ]]; then #WAVECAR and CHGCAR restart
      set_wavecar_chgcar $n
   elif [[ -s ./${n}/WAVECAR ]]; then #WAVECAR restart
      set_wavecar $n
   elif [[ -s ./${n}/CHGCAR ]]; then #CHGCAR restart
      set_chgcar $n
   else
      echo "Neither WAVECAR or CHGCAR exist to restart from, exiting"
      exit 1
   fi

   echo "Resubmit your calculation now"
}

restart
exit 0
