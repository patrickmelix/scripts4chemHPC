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
ORCAINPUT="orca.inp"
STRUCTURE="input.xyz"
RUNSCRIPT="orca.run"
ignore=("$RUNSCRIPT" "full_traj.xyz" "traj.xyz" "$ORCAINPUT") #files to remain where they are
########################################################################

##################
# Script
##################
set -e
echo "Preparing restart..."
NAME=$(basename *.prop .prop)
echo "Jobname seems to be ${NAME}"
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
[ -e ./${n}/$NAME.xyz ] && ln -s ./${n}/$NAME.xyz $STRUCTURE
ln -s ./${n}/$NAME.gbw restart.gbw
[ -e ./${n}/$NAME.opt ] && ln -s ./${n}/$NAME.opt restart.opt
#ln -s ./${n}/$NAME.inp "$ORCAINPUT"
echo "... Done!"

echo "Checking input file for restart settings."
#set hessian input if GO
if grep -i "opt" "$ORCAINPUT"
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
   if grep -i "[[:space:]]*Guess[[:space:]]*" "$ORCAINPUT"
   then
      echo "- Removing old Guess Key"
      sed -i "/guess /Id" "$ORCAINPUT"
   fi
   sed -i "/.*scf.*/a\ Guess MORead\n MOInp \"restart.gbw\"" "$ORCAINPUT"
fi
echo "... Done! Resubmit manually now"
