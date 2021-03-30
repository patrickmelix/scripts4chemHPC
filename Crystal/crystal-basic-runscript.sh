#! /bin/sh
#SBATCH -J JOBNAME
#SBATCH --time=08:00:00
#SBATCH --nodes=3
#SBATCH --ntasks-per-node=24
#SBATCH --mem-per-cpu=2583M
#SBATCH --signal=INT@300

##Basic Runscript
#################### OVERWRITES AN ALREADY PRESENT ./INPUT !!!!!!######################################
# To be used directly in the running directory. Preferrably an SSD workspace (Crystal writes many files).
# No file cleanup, restart or anything yet.
# So make sure you have all the files with proper naming set up. Some examples:
# * fort.34: EXTERNAL geometry input, e.g. for GO restarts renamed from optc***
# * fort.20: SCF guess, e.g. for restarts
# * OPTINFO.dat: For GO restarts
# * fort.33: Coordinates of all GO steps
#
# Most of the time, you can delete the *.pe* files after the run.

###Edit these to your needs:

# Make sure you use the binary you want to use by setting the variable below to the right one.
BIN="Pcrystal"

#load the module
module load crystal/17

#parse the input to ./INPUT
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
#### Rest should be static

srun "${BIN}"
