#!/bin/bash
##SBATCH --partition condo
##SBATCH --constraint fwang
#SBATCH --job-name=GROMACS~~md.log
#SBATCH -o Qjob.%j
#SBATCH --partition comp06
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=16
#SBATCH --time=06:00:00
#SBATCH --mail-user=trr007@uark.edu
#SBATCH --mail-type=FAIL,END

starttime=`date`
_starttime=`date +%s`

exec_host=`qstat -f $SLURM_JOB_ID | grep exec_host | awk '{print $3}' `
run_date=`date +%D`
echo "$run_date     $exec_host     $SLURM_JOB_ID     $SLURM_SUBMIT_DIR" >> /home/$USER/SLURM_JOBS.log

# MAKE SURE NOTHING OLD IS HANGING AROUND IN SHARED MEMORY
rm -rf /dev/shm/*

cd $SLURM_SUBMIT_DIR
rsync -av --exclude={slurm*,qjob*,Q*} $SLURM_SUBMIT_DIR/ /local_scratch/$SLURM_JOB_ID/
cd /local_scratch/$SLURM_JOB_ID/


module purge
module load impi/18.0.2 mkl/18.0.2 intel/18.0.2
source /home/trr007/gromacs/gromacs-2018.4/GMX2018.4_raz/intel-18.0.2/impi-18.0.2/bin/GMXRC

# CREATE A "machinefile" FOR USE WITH MPI JOBS
scontrol show hostname $SLURM_NODELIST | tr 'ec' 'ic' | sort -u > machinefile_${SLURM_JOB_ID}

mpirun -np 16 -machinefile machinefile_${SLURM_JOB_ID} gmx_mpi_d mdrun -table table -tablep table -tableb table_b0.xvg -dd 3 4 1 -npme 4


echo "------------------------------"
echo "Scratch directory: /local_scratch/$SLURM_JOB_ID/"
echo "Used and created files: "
ls -lhrt /local_scratch/$SLURM_JOB_ID/
echo "------------------------------"

rsync -av --exclude={table*xvg,traj.trr} --remove-source-files /local_scratch/$SLURM_JOB_ID/ $SLURM_SUBMIT_DIR/
cp Qjob.* $SLURM_SUBMIT_DIR/

cd $SLURM_SUBMIT_DIR/


echo ""
echo "=============================="
echo "SLURM job statistics:"
squeue -h -j $SLURM_JOB_ID -o "%A  %P  %D  %C  %B  %l  %M  %j  %Z  %N"  > __TMP_RUNNING_$$
while read -r jobid part nodes cpus headnode timelim elap jobname workdir nodelist; do
    allnodes=(`scontrol show hostname $nodelist`)
    echo "Job_ID:      $jobid";
    echo "Job_name:    $jobname";
    echo "Partition:   $part";
    echo "Nodes:       $nodes";
    echo "CPUs:        $cpus";
    echo "Headnode:    $headnode";
    echo "Node_list:   ${allnodes[@]}"
    echo "Work_dir:    $workdir";
done < "__TMP_RUNNING_$$"

endtime=`date`
_endtime=`date +%s`
runtime=$((_endtime-_starttime))
echo "Start time:  $starttime"
echo "End time:    $endtime"
printf 'Run time:    %03dh:%02dm:%02ds\n' $((runtime/3600)) $((runtime%3600/60)) $((runtime%60))

#mv slurm-${SLURM_JOB_ID}.out Qjob.${SLURM_JOB_ID}
rm machinefile_${SLURM_JOB_ID}
