########################################################################
# README
#
# Warning:
# Use this script with caution. Not understanding what and how it does may lead to data loss!
# Only tested for GO so far. See the example input file.
#
# DO NOT CHANGE:
# - SLURM output and error log file names
# - If restarting the SCF, the gbw needs to be named restart.gbw
# - If restarting the GO, the hessian file needs to be named restart.opt
#
#
#
##################

##################
# Defaults
# change with care to suit your setup
##################
STRUCTURE="input.xyz"
########################################################################

##################
# Script
##################
set -e
echo "Preparing restart..."
NAME=$(basename *.run .run)
SLURM_JOB_NAME="${NAME}"
echo "Jobname seems to be ${NAME}"
ORCAINPUT="${NAME}.in"
RUNSCRIPT="${NAME}.run"
ignore=("$RUNSCRIPT" "full_traj.xyz" "$ORCAINPUT" "$INTEGRALFILE") #files that stay where they are during restart

if [ ! -f $RUNSCRIPT ]; then
   echo "$RUNSCRIPT not found"
   exit 1
fi

if [ ! -f $ORCAINPUT ]; then
   echo "$ORCAINPUT not found"
   exit 1
fi

function restart()
{
   #find highest numeric subfolder
   n="$(find . -name "*[0-9]" -type d | sort -Vr | head -1 | sed 's/.\///')"
   n=$((n+1))
   echo -n "Moving files to subdir ${n}, "
   mkdir ${n} || { echo 'mkdir failed' ; exit 1; }
   #ignore input geometry if no new one was written
   [ ! -e $SLURM_JOB_NAME.xyz ] && ignore+=("$STRUCTURE")
   #move all files to subfolder n, except these:
   #not sure why joint f l does not work, so have to run second time for symlinks
   echo -n "Ignoring these files: ${ignore[*]}, moving all others..."
   find . -maxdepth 1 -type f -not -name "${ignore[0]}" $(printf -- '-not -name %s ' "${ignore[@]:1}") -exec mv -t ./${n}/ {} + || { echo 'moving files failed' ; exit 1; }
   find . -maxdepth 1 -type l -not -name "${ignore[0]}" $(printf -- '-not -name %s ' "${ignore[@]:1}") -exec mv -t ./${n}/ {} + || { echo 'moving symlinks failed' ; exit 1; }
   echo "... Done!"

   #save space by creating symlinks
   echo -n "Create symlinks..."
   [ -e ./${n}/$SLURM_JOB_NAME.xyz ] && ln -s ./${n}/$SLURM_JOB_NAME.xyz $STRUCTURE
   ln -s ./${n}/$SLURM_JOB_NAME.gbw restart.gbw
   [ -e ./${n}/$SLURM_JOB_NAME.opt ] && ln -s ./${n}/$SLURM_JOB_NAME.opt restart.opt
   #ln -s ./${n}/$SLURM_JOB_NAME.inp "$ORCAINPUT"
   echo "... Done!"

   echo "Checking input file for restart settings."
   #set hessian input if GO
   if grep -iq "opt" "$ORCAINPUT"
   then
      if grep -i "[[:space:]]*InHess[[:space:]]*Read" "$ORCAINPUT" | grep -qv "[[:space:]]*#[[:space:]]*InHess[[:space:]]*Read"
      then
         echo "- Hessian Restart already set"
      else
         echo "- Setting Hessian Restart Key"
         sed -i "/.*geom.*/a\ InHess Read\n InHessName \"restart.opt\"" "$ORCAINPUT"
      fi
   fi
   #set scf guess input
   if grep -i "[[:space:]]*MOInp[[:space:]]*\"restart.gbw\"" "$ORCAINPUT" | grep -qv "[[:space:]]*#[[:space:]]*MOInp[[:space:]]*\"restart.gbw\""
   then
      echo "- SCF Restart already set"
   else
      echo "- Setting SCF Restart Key"
      if grep -iwq "Guess" "$ORCAINPUT"
      then
         echo "- Removing old Guess Key"
         sed -i "/\bguess\b/Id" "$ORCAINPUT"
      fi
      sed -i "/.*scf.*/a\ Guess MORead\n MOInp \"restart.gbw\"" "$ORCAINPUT"
   fi
   #set integral file restart options
   if grep -i "KeepInts[[:space:]]*True" "$ORCAINPUT" | grep -qv "[[:space:]]*#[[:space:]]*KeepInts[[:space:]]*True"
   then
      if grep -i "[[:space:]]*ReadInts[[:space:]]*True" "$ORCAINPUT" | grep -qv "[[:space:]]*#[[:space:]]*ReadInts[[:space:]]*True"
      then
         echo "- ReadInts already set"
      else
         echo "- Setting ReadInts Key"
         sed -i "/.*keepints.*/a\ ReadInts true" "$ORCAINPUT"
      fi
   fi
   echo "... Done! Resubmit manually now"
}

restart
