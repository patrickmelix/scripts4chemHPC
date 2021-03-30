#!/bin/sh
#SBATCH -J JOBNAME
#SBATCH --time=08:00:00
#SBATCH --nodes=3
#SBATCH --ntasks-per-node=24
#SBATCH --mem-per-cpu=2583M
#SBATCH --mail-user=mail@mydomain.com
#SBATCH --mail-type=ALL #Recommend to not forget running jobs
#SBATCH --signal=INT@300 #send INT signal to process 300s before walltime exceeded
#SBATCH --output=%x.out #JOBNAME.out
#SBATCH --error=%x.out #JOBNAME.out

##GO Chainjob Runscript
##################### ONLY TESTED FOR GO RUNS ##########################################################
# To be used directly in the running directory. Preferrably an SSD workspace (Crystal writes many files).
# Minor file cleanup, basic automatic GO restarts.
# So make sure you have all the files with proper naming set up. Some examples:
# * fort.34: EXTERNAL geometry input, e.g. for GO restarts renamed from optc***
# * fort.20: SCF guess, e.g. for restarts
# * OPTINFO.dat: For GO restarts
# * fort.33: Coordinates of all GO steps
#
# The *.pe* files are deleted after every run!

###Edit these to your needs:

# Make sure you use the binary you want to use by setting the variable below to the right one.
BIN="Pcrystal"
#Maximum number of restarts
MAXCALC=50
#stdout is written to
OUTPUTFILE="${SLURM_JOB_NAME}.out"

#load the module
module load crystal/17

#parse the input to ./INPUT if not present
if [ ! -f INPUT ]; then
   echo "No INPUT present, writing it now."
   cat << eof > INPUT
Title
EXTERNAL
OPTGEOM
RESTART
FULLOPTG
ENDGEOM
BASISSET
POB-DZVP
DFT
PBE0
END
DFTD3
VERSION
4
ABC
FUNCTIONAL
PBE0
END
UHF
EXCHSIZE
5325408
BIPOSIZE
5343400
TOLINTEG
7 7 7 7 14
SHRINK
3 6
ATOMSPIN
2
57 1
58 -1
SPINLOCK
0 -3
SCFDIR
MAXCYCLE
300
DIIS
END
eof
else
   echo "INPUT already present, using it."
fi
#### Rest should be static

srun "${BIN}"

#Find out if converged
if grep -q "OPT END - CONVERGED" "${OUTPUTFILE}"
then
    echo "GO converged, nothing more to do."
    exit 0
fi

#check for errors in output
if grep -q "PXK TOO SMALL" "${OUTPUTFILE}"
then
   echo "Error found: PXK TOO SMALL"
   exit 1
fi

#Restart Procedure
NAME="$(basename *.run .run)"
RUNSCRIPT="${NAME}.run"
if [ ! -f ${RUNSCRIPT} ]; then
   echo "runscript file ${RUNSCRIPT} missing!"
   exit 1
fi
#find highest numeric subfolder
n="$(find . -name "*[0-9]" -type d | sort -Vr | head -1 |  sed 's/.\///')"
n=$((n+1))
echo "Moving files to subdir ${n}"

#move files to subfolder $N
mkdir ${n} || { echo 'mkdir failed' ; exit 1; }
#remove pe files
rm *.pe*
#move all files to subfolder n, except optc*
find . -maxdepth 1 -type f ! -name "optc*"  -exec mv {} ./${n}/ \; || { echo 'moving files failed' ; exit 1; }
#move all .pe files and slurm file
#find . -maxdepth 1 -type f  -name '*.pe*' -exec mv {} ./${n}/ \; || { echo 'moving files failed' ; exit 1; }
#find . -maxdepth 1 -type f  -name 'slurm*' -exec mv {} ./${n}/ \; || { echo 'moving slurm file failed' ; exit 1; }
#copy all other files
#find . -maxdepth 1 -type f  -exec cp {} ./${n}/ \; || { echo 'copying files failed' ; exit 1; }
#create list of further files to copy back
COPYFILES=("INPUT" "OPTINFO.DAT" "fort.9" "fort.20" "fort.33" "${RUNSCRIPT}")
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
cmp --silent ./fort.34 ./${n}/fort.34 && { echo "Geometry did not change, aborting"; exit 1; }

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
sbatch "${RUNSCRIPT}"

exit 0
