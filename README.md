# scripts4chemHPC
My set of useful HPC scripts for chemistry software packages. Very basic but helpful for running standard jobs. So far SLURM only.

Happy for any contributions.

## CP2K

* Scripts to run GO and MD with limited walltime and automatic restart.

## Crystal

* Scripts to run GO with automatic restart.
* Wrapper for properties calculations.
* Script to clean the workdir of a Crystal calculation.

## ORCA

* Multinode ORCA runscript with automatic GO restart/continuation.
* Example input file with variables to be set by runscript.

## VASP

* VASP runscript with automatic GO, DIMER and NEB restart/continuation.
* Script to combine all `vasprun.xml` recursively into one ASE-xyz trajectory.
* Script to extract magnetization of all OUTCARs in subdirs of the current folder (helpful during NEB)
