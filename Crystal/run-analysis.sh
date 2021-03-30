#!/bin/bash
# Pass the desired base jobname as final argument
set -e

function usage() {
ME=`basename $0`
echo "
Usage: $ME [-h] [-d DENSITY] [-o ORBITAL] [-l LORBITAL] [-w WAIT] jobname walltime

  -h Print this message

  -d or --density DENSITY
   Density calculation using ECH3 input DENSITY

  -a or --anisotropic
   Anisotropic calculation using ANISOTRO

  -f or --fieldgradient
   Field-Gradient calculation using ISOTROPIC and POTC keywords

  -o or --orbital ORBITAL
   Orbital calculation with NEWK input ORBITAL

  -l or --lorbital LORBITAL
   Localized orbital calculation with NEWK input LORBITAL

  -w or --wait WAIT
   SLURM ID of job to wait for (dependency).

  jobname
   Jobname of all produced jobs

  All *.pe* files are deleted automatically!
"
}


POSITIONAL=()
while [[ $# -gt 0 ]]
do
   key="$1"

   case $key in
       -h|--help)
       usage
       exit 0
       ;;
       -o|--orbital)
       ORBITAL="$2"
       shift # past argument
       shift # past value
       ;;
       -d|--density)
       DENSITY="$2"
       shift # past argument
       shift # past value
       ;;
       -f|--fieldgradient)
       FIELDGRADIENT="True"
       shift # past argument
       ;;
       -a|--anisotropic)
       ANISOTROPIC="True"
       shift # past argument
       ;;
       -l|--lorbital)
       LORBITAL="$2"
       shift # past argument
       shift # past value
       ;;
       -w|--wait)
       WAIT="$2"
       shift # past argument
       shift # past value
       ;;
       *)    # unknown option
       POSITIONAL+=("$1") # save it in an array for later
       shift # past argument
       ;;
   esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

function main () {
   JOBNAME="$1"
   WALLTIME="$2"
   x="asdf"
   echo $JOBNAME

   if [ ! -z ${DENSITY+x} ]; then
      echo "Running Density Calculation"
      density $1 "${DENSITY}"
   fi
   if [ ! -z ${LORBITAL+x} ]; then
      echo "Running Localized Orbital Calculation"
      lorbitals $1 "${LORBITAL}" $1-LORB
   fi
   if [ ! -z ${ORBITAL+x} ]; then
      echo "Running Orbital Calculation"
      orbitals $1 "${ORBITAL}" $1-ORB
   fi
   if [ ! -z ${FIELDGRADIENT+x} ]; then
      echo "Running Field Gradient Calculation"
      fieldgradient $1
   fi
   if [ ! -z ${ANISOTROPIC+x} ]; then
      echo "Running Anisotriopic Calculation"
      anisotropic $1
   fi
}

#################################################################
function write_runscript () { #filename, jobname, walltime, nodes, ntaskspernode, memorypercpu
   echo "#!/bin/sh" > $1
   echo "#SBATCH -J $2" >> $1
   echo "#SBATCH --time=$3" >> $1
   echo "#SBATCH --nodes=$4" >> $1
   echo "#SBATCH --ntasks-per-node=$5" >> $1
   echo "#SBATCH --mem-per-cpu=$6" >> $1
   echo "#SBATCH --output=%x.out #JOBNAME.out" >> $1
   echo "#SBATCH --error=%x.out #JOBNAME.out" >> $1
   if [ ! -z "${WAIT+x}" ]; then
      echo "#SBATCH --dependency=afterok:${WAIT}" >> $1
   fi
   cat << eof >> $1
module load crystal/17
properties < INPUT
rm *.pe*
exit 0
eof
}
#################################################################
function fieldgradient () { #jobname
   SUBDIR='fieldgradient'
   mkdir "${SUBDIR}"
   ln -s ../fort.9 "${SUBDIR}"/fort.9
   jn="$1-fieldgradient"
   write_runscript ${SUBDIR}/$jn.run $jn $WALLTIME 1 1 2583M
   cat << eof > ${SUBDIR}/INPUT
SETPRINT
1
18 1
ISOTROPIC
UNIQUE
POTC
0 0 0
END
eof
   cd ${SUBDIR}
   sbatch $jn.run
   cd ..
}
#################################################################
function anisotropic () { #jobname
   SUBDIR='anisotropic'
   mkdir "${SUBDIR}"
   ln -s ../fort.9 "${SUBDIR}"/fort.9
   jn="$1-anisotropic"
   write_runscript ${SUBDIR}/$jn.run $jn $WALLTIME 1 1 2583M
   cat << eof > ${SUBDIR}/INPUT
SETPRINT
1
18 1
ANISOTRO
UNIQUE
END
eof
   cd ${SUBDIR}
   sbatch $jn.run
   cd ..
}
#################################################################
function density () { #jobname and ECH3 input
   SUBDIR='density'
   mkdir "${SUBDIR}"
   ln -s ../fort.9 "${SUBDIR}"/fort.9
   jn="$1-denisty"
   write_runscript ${SUBDIR}/$jn.run $jn $WALLTIME 1 1 2583M
   cat << eof > ${SUBDIR}/INPUT
ECH3
$2
END
eof
   cd ${SUBDIR}
   sbatch $jn.run
   cd ..
}
#################################################################
function lorbitals () { #jobname, NEWK-Input, orbital file name
   SUBDIR='lorbitals'
   mkdir "${SUBDIR}"
   ln -s ../fort.9 "${SUBDIR}"/fort.9
   jn="$1-LORB"
   write_runscript ${SUBDIR}/$jn.run $jn $WALLTIME 1 1 2583M
   cat << eof > ${SUBDIR}/INPUT
NEWK
$2
1 0
LOCALI
END
ORBITALS
$3
1
1
END
END
eof
   cd ${SUBDIR}
   sbatch $jn.run
   cd ..
}
#################################################################
function orbitals () { #jobname, NEWK-Input, orbital file name
   SUBDIR='orbitals'
   mkdir "${SUBDIR}"
   ln -s ../fort.9 "${SUBDIR}"/fort.9
   jn="$1-ORB"
   write_runscript ${SUBDIR}/$jn.run $jn $WALLTIME 1 1 2583M
   cat << eof > ${SUBDIR}/INPUT
NEWK
$2
1 0
ORBITALS
$3
1
0
END
END
eof
   cd ${SUBDIR}
   sbatch $jn.run
   cd ..
}
#################################################################
main "$@"
exit 0
