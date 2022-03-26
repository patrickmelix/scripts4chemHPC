#!/bin/bash

#make some PBS derived commands work with SLURM
alias qstat='squeue -u $USER | less'
alias qs='squeue -u $USER --format="%12i %.20P %.40j %.8u %.2t %.10M %.6D %R"'
alias q='squeue -u $USER'

#some SLURM abbreviations
alias si='sinfo -o "%20P %5a %15l %10m %10c %16A %10w %N"' #queue info
alias ji='scontrol -d show job' #job info
alias qprio='squeue -o "%.18i %12P %20J %T %10M %9L %12B %6D %C %R %p" -u $USER | sort -k 11' #print prioity
alias cpu_usage='sshare -U'
alias sb='sbatch *.run' #submit all run files in this folder


#some helpers to get job information
#get rundir of job ID
alias get_dir='function _get_dir(){ sacct -j $1 -X --format=WorkDir%-1000 -n | sed -e "s/[[:space:]]*$//"; unset -f _get_dir; }; _get_dir'
#go to workdir of job ID
alias goto='function _goto(){ cd $(sacct -j $1 -X --format=WorkDir%-1000 -n); unset -f _goto; }; _goto'
#get estimate of starting time of job ID
alias get_starttime="squeue --start -j"
#get runtime and memory in G of job ID
alias get_runtime_and_memory="sacct --format=JobID,JobName%30,MaxRSS,Elapsed,TotalCPU --units=G -j"
#list yesterdays jobs
alias check_yesterday="sacct -u $USER -S $(date -d "1 day ago" '+%Y-%m-%d') -E $(date '+%Y-%m-%d') --format=JobID,JobName%30,Partition,MaxRSS,Elapsed,TotalCPU,AllocCPUS,State --units=G -X"
#list toddays jobs
alias check_today="sacct -u $USER -S $(date '+%Y-%m-%d') --format=JobID,JobName%30,Partition,MaxRSS,Elapsed,TotalCPU,AllocCPUS,State --units=G -X"
#list jobs of last week
alias check_week="sacct -u $USER -S $(date -d "7 day ago" '+%Y-%m-%d') -E $(date '+%Y-%m-%d') --format=JobID,JobName%30,Partition,MaxRSS,Elapsed,TotalCPU,AllocCPUS,State --units=G -X"
