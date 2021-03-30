#!/bin/sh
#exit if any command fails
set -e
#more advanced pattern matching
shopt -s extglob

###README
# Prepare for restarting a Crystal GO
# Needs a single *.run file that should be restarted
# No input is changed, just files moved
#

######EDIT THESE
#search string for steps

#Maximum number of restarts
MAXCALC=50

NAME="$(basename *.run .run)"
RUNSCRIPT="${NAME}.run"
if [ ! -f ${RUNSCRIPT} ]; then
   echo "runscript file ${RUNSCRIPT} missing!"
   exit 1
fi
#find highest numeric subfolder
n="$(find . -maxdepth 1 -name "*[0-9]" -type d | sort -Vr | head -1 |  sed 's/.\///')"
n=$((n+1))
echo "Moving files to subdir ${n}"

#move files to subfolder $N
mkdir ${n} || { echo 'mkdir failed' ; exit 1; }
#remove pe files
rm *.pe*
#move all files to subfolder n
find . -maxdepth 1 -type f ! -name "optc*"  -exec mv {} ./${n}/ \; || { echo 'moving files failed' ; exit 1; }
#move all .pe files and slurm file
#find . -maxdepth 1 -type f  -name '*.pe*' -exec mv {} ./${n}/ \; || { echo 'moving files failed' ; exit 1; }
#find . -maxdepth 1 -type f  -name 'slurm*' -exec mv {} ./${n}/ \; || { echo 'moving slurm file failed' ; exit 1; }
#copy all other files
#find . -maxdepth 1 -type f  -exec cp {} ./${n}/ \; || { echo 'copying files failed' ; exit 1; }
#create list of further files to copy back
COPYFILES=("INPUT" "OPTINFO.DAT" "fort.9" "fort.20" "fort.33" "optc*" "${RUNSCRIPT}")
#now copy the files
for file in "${COPYFILES[@]}"
do
   cp ./${n}/${file} . || { echo 'cp ${file} failed' ; exit 1; }
done

#Make sure RESTART keyword is set, if not set it.
if grep -q "RESTART" INPUT
then
   echo "RESTART key is already set"
else
   echo "Setting RESTART key in INPUT"
   sed -i '/.*OPTGEOM.*/a\RESTART' INPUT
fi

#find last geometry
geom="$(find . -maxdepth 1 -name "optc*" -type f | sort -Vr | head -1)"
cp "${geom}" ./fort.34

#check if geometry changed
cmp --silent ./fort.34 ./${n}/fort.34 && { echo "Geometry did not change, aborting!"; exit 1; } 

#scf guess
#fort.9 might be empty, then use existing fort.20
if [ ! -f fort.9 -a ! -f fort.20 ]; then
   echo "neither fort.9 nor fort.20 found"
   exit 1
elif [ ! -f fort.9 ]; then
   echo "fort.9 missing"
   exit 1
elif [ ! -s fort.9 -a -f fort.20 ]; then
   echo "fort.9 empty, using existing fort.20"
   rm fort.9
else
   mv fort.9 fort.20
fi

#submit
#sbatch $SCRIPTNAME

exit 0
