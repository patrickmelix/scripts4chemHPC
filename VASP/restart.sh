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
ignore=("KPOINTS" "POTCAR" "$RUNSCRIPT" "INCAR") # files that stay where they are during restart
########################################################################

##################
# Script
##################

function set_wavecar()
{
   echo -n "Copying WAVECAR+INCAR and setting options..."
   cp ./${1}/WAVECAR .
   cp INCAR ./${1}/
   echo "... Done!"

   echo "Checking input file for restart settings."
   #ISTART
   if grep -i "[[:space:]]*ISTART[[:space:]]*=[[:space:]]*1" INCAR | grep -qv "[[:space:]]*#[[:space:]]*ISTART[[:space:]]*=[[:space:]]*1"
   then
      echo "- ISTART=1 already set"
   else
      echo -n "- Setting ISTART=1"
      if grep -iq "istart"
      then
         echo " by chaning value"
         sed -ie "s/[[:space:]]*ISTART[[:space:]]*=[[:space:]]*[0-9]/ISTART=1/I" INCAR
      else
         echo " by appending to INCAR"
         echo "ISTART=1" >> INCAR
      fi
   fi
   #ICHARG
   if grep -i "[[:space:]]*ICHARG[[:space:]]*=[[:space:]]*0" INCAR | grep -qv "[[:space:]]*#[[:space:]]*ICHARG[[:space:]]*=[[:space:]]*0"
   then
      echo "- ICHARG=0 already set"
   else
      echo -n "- Setting ICHARG=0"
      if grep -iq "icharg"
      then
         echo " by chaning value"
         sed -ie "s/[[:space:]]*ICHARG[[:space:]]*=[[:space:]]*[0-9]/ICHARG=0/I" INCAR
      else
         echo " by appending to INCAR"
         echo "ICHARG=0" >> INCAR
      fi
   fi
   echo "... Done!"

}
function set_chgcar()
{
   echo -n "Copying CHGCAR+INCAR and setting options..."
   cp ./${1}/CHGCAR .
   cp INCAR ./${1}/
   echo "... Done!"

   echo "Checking input file for CHGCAR restart settings."
   if grep -i "[[:space:]]*ISTART[[:space:]]*=[[:space:]]*0" INCAR | grep -qv "[[:space:]]*#[[:space:]]*ISTART[[:space:]]*=[[:space:]]*0"
   then
      echo "- ISTART=0 already set"
   else
      echo -n "- Setting ISTART=1"
      if grep -iq "istart"
      then
         echo " by chaning value"
         sed -ie "s/[[:space:]]*ISTART[[:space:]]*=[[:space:]]*[0-9]/ISTART=0/I" INCAR
      else
         echo " by appending to INCAR"
         echo "ISTART=0" >> INCAR
      fi
   fi
   #ICHARG
   if grep -i "[[:space:]]*ICHARG[[:space:]]*=[[:space:]]*1" INCAR | grep -qv "[[:space:]]*#[[:space:]]*ICHARG[[:space:]]*=[[:space:]]*1"
   then
      echo "- ICHARG=1 already set"
   else
      echo -n "- Setting ICHARG=0"
      if grep -iq "icharg"
      then
         echo " by chaning value"
         sed -ie "s/[[:space:]]*ICHARG[[:space:]]*=[[:space:]]*[0-9]/ICHARG=1/I" INCAR
      else
         echo " by appending to INCAR"
         echo "ICHARG=1" >> INCAR
      fi
   fi
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

   if [[ -s ./${n}/WAVECAR ]]; then #WAVECAR restart
      set_wavecar $n
   elif [[ -s ./${n}/CHGCAR ]]; then #CHGCAR restart
      set_chgcar $n
   else
      echo "Neither WAVECAR or CHGCAR exist to restart from, exciting"
      exit 1
   fi

   echo "Resubmit your calculation now"
}

restart
exit 0
