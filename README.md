# ahpcc_slurmjob_watcher

This script should be able to be used on any computer system employing the SLURM scheduler.
Certain features of the script may not work exactly as expected, depending on the exact way SLURM was configured for your HPC. Fortunately, the actual code is heavily commented, so it should be (hopefully) easy to find problems and modify the script if needed to suit your purposes. 

Here is the manual/"man page" associated with the script, which can also be found at the top of the script, or by executing the script with the "--help" option: 
===================================================================================
 ahpcc_slurmjob_watcher.sh      (Arkansas High Performance Computing Center's tool
                                 to help you be a good WATCHER of your SLURM JOBs)

 Written by:           T. Ryan Rogers (trr007@email.uark.edu)
 Last modified:        09/02/2020
-----------------------------------------------------------------------------------
__USAGE__
     ahpcc_slurmjob_watcher.sh   [OPTIONS]

__SYNOPSIS__
     This script prints custom-formatted information about the user's SLURM jobs.
 Currently, this program can not be used (unlike SLURM\'s squeue command) to see
 information about another user's jobs.
     None of the options are required. Without any additional arguments, the script
 will display default information for all the user\'s running jobs. Options can be
 used to display pending jobs, extra information, & selective output.

__OPTIONS__
    -h, --help
        Print this usage/help/manual info, then exit.

    NUM, all, oo, 00
        NUM is Any integer. If provided, information for all running jobs belonging
        to \$USER, along with NUM pending (\"PD\" status) jobs, is displayed.
        Other symbols, including \"all\" or either of the \"infinity\" symbols
        cause information to be printed for all running and all pending jobs.

    -v, --verbose
        Any string containing \"-v\" can be used. If used, extra information about
        all running jobs belonging to \$USER are displayed.

    -j SLURM_JOB_ID
        Any string containing \"-j\" can be used. When used, also enter the
        SLURM_JOB_ID associated with a particular job. Only information about job
        SLURM_JOB_ID will be printed.

-----------------------------------------------------------------------------------
__NOTE_1__
     To make full use of this script, the user should use a special setting with
 the SLURM \"--job-name=\" designation. Specifically, the job name argument
 should be set to PROGRAM~~OUTFILE, where \"~~\" is the required separator. The
 PROGRAM and OUTFILE keywords are described below.
     Currently, this script only recognizes the following options for PROGRAM:

         COMSOL     : COMSOL Multiphysics simulation software
         CRYOFF     : CReate Your Own Force Field parameterization program
         GAMESS     : General Atomic and Molecular Electronic Structure System
         GAUSSIAN   : (computational chemistry software)
         GROMACS    : GROningen MAchine for Chemical Simulations
         MOLPRO     : Molpro Quantum Chemistry Software
         PQS        : Parallel Quantum Solutions
         SAPT       : Symmetry Adapted Perturbation Theory, specifically SAPT2016.1
         STRFACT    : STRucture FACTor program
                      (https://webpages.ciencias.ulisboa.pt/~cebernardes/index.html)
         VASP       : Vienna Ab initio Simulation Package

 If you do not see your job type listed there, you can email the author to update
 the script to include new options for PROGRAM. New PROGRAM strings must be 10
 characters or less.
     For the OUTFILE keyword, any string can be used, as long at the string matches
 the name of a file present in your running job's scratch directory.

__NOTE_2__
     The -v flag's \"Comment\" feature may not work properly if a wildcard is
 used in the \"--job-name=\" designation. Whenever possible, the exact output
 filename should be used without wildcards. E.g. instead of,
     --job-name=SAPT~~*.out
 use something like,
     --job-name=SAPT~~ch3oh-h2o_277_.out

__NOTE_3__
     This script assumes that your output file(s) are located at one of the two
 default locations prepared by the AHPCC, viz. either at
 /scratch/\$SLURM_JOB_ID/   or   /local_scratch/\$SLURM_JOB_ID/.
 Running jobs in other locations may not be recognized by the script and is
 therefore discouraged.

__NOTE_4__
     When using the -j flag, -v is still functional, but printing of PD jobs is
 disabled. If you wish to see PD jobs, consider executing the script again without
 the -j flag.
===================================================================================
