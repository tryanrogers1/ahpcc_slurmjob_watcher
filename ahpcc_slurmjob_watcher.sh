#!/bin/bash                                                                 

function help {
    echo "
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

";
}


args=("$@")     #SAVE ALL COMMANDLINE ARGUMENTS TO THE SCRIPT TO A MORE READABLE ARRAY NAME.
show_n_pd=0     #BEFORE PARSING THE (OPTIONAL) INPUT ARGUMENTS, SET NUMBER OF "PD" JOBS TO DISPLAY =0.
verbose=0       #BEFORE PARSING THE (OPTIONAL) INPUT ARGUMENTS, SET VERBOSE PRINTING FLAG TO "OFF."
special_ids=0   #BEFORE PARSING THE (OPTIONAL) INPUT ARGUMENTS, SET FLAG FOR ONLY PRINTING INFO ON SPECIAL JOB ID'S TO "OFF."


#===================================================
#===== PRINT HELP/MAN PAGE OR IMPORT ARGUMENTS =====
if [[ "${args[@]}" =~ "-h" ]]; then    #IF ANY ONE OF THE INPUT ARGUMENTS CONTAINS THE STRING "-h", THEN...
    help                               #...EXECUTE THE "help" SUBROUTINE TO PRINT HELP PAGE, THEN...
    exit 1                             #...EXIT SCRIPT.
else                                   #HOWEVER, IF THE HELP PAGE WAS NOT REQUESTED, THEN...
#    echo "${args[@]}"                 #---DEBUGGING.
    for i in "${args[@]}"; do          #...PARSE EACH OF THE INPUT ARGUMENTS, &...
	if [[ $i == "all" || $i == "oo" || $i == "00" ]]; then   #IF "all" OR "infinite" JOBS WERE REQUESTED...
	    show_n_pd=9999999999       #...SET THE NUMBER OF "PENDING" JOBS DISPLAYED TO AN UNIMAGINABLY HUGE NUMBER OF JOBS.
	elif [[ $i =~ [0-9] ]]; then   #IF THE ARGUMENT CONTAINS A NUMBER...
	    show_n_pd=$i               #...SET THE NUMBER OF QUEUED/"PENDING" JOBS SHOWN EQUAL TO THAT ARGUMENT.
	elif [[ $i =~ "-v" ]]; then    #IF THE USER USED A "-v" IN ONE OF THE ARGUMENTS...
	    verbose=1                  #...THEN TURN ON "VERBOSE" PRINTING.
	elif [[ $i =~ "-j" ]]; then    #IF THE USER USED A "-j" IN ONE OF THE ARGUMENTS...
	    special_ids=1              #...THEN TURN ON THE FLAG TO ONLY PRINT INFO FOR JOB ID'S GIVEN AS ARGUMENTS.
	fi                             #
    done                               #FINISH PARSING COMMANDLINE ARGUMENTS.
fi



#==============================================================================
#===== SUBROUTINE FOR OBTAINING STANDARD INFO FOR ALL YOUR "RUNNING" JOBS =====
function standard_running {
    echo "============================================================================================================="
    echo " #       JOBID   PARTITION  NODES  CPUS    HEAD_NODE    TIME_LIMIT            ELAP_TIME    JOB_NAME  WORK_DIR"
    echo "-------------------------------------------------------------------------------------------------------------"
#    squeue -h -o "%A  %P  %D  %C  %B  %l  %M  %j  %Z" --states=R  > __TMP_RUNNING_$$           #---DEBUGGING.
    squeue -h -u $USER -o "%A  %P  %D  %C  %B  %l  %M  %j  %Z" --states=R  > __TMP_RUNNING_$$   #SAVE squeue DATA WITH NO HEADER OF $USER'S RUNNING JOBS TO A TEMPORARY FILE.
#    cat __TMP_RUNNING_$$   #---DEBUGGING.
    njob=1

    if [[ $special_ids == 1 ]]; then   #IF INFO ON ONLY CERTAIN JOB ID'S WAS REQUESTED, THEN DO A SPECIAL LOOP...

	while read -r jobid part nodes cpus head timelim elap jobname workdir; do        #READ DATA FROM THE TEMPORARY FILE AS WHITESPACE-SEPARATED VARIABLES NAMED THUS.
#	while IFS= read -r jobid part nodes cpus head timelim elap jobname workdir; do   #---DEBUGGING.
	    jname=`echo $jobname | awk -F "~~" '{print $1}'`                             #FIELD SEPARATED ON "~~" & ONLY 1ST FIELD KEPT.
	    if [[ "${args[@]}" == *"$jobid"* ]]; then                                    #IN THIS SPECIAL LOOP, ONLY PRINT INFO IF $jobid IS ONE OF THE INPUT ARGUMENTS.
		printf " %-4s  %7s  %10s  %5s  %4s  %11s  %12s  %19s  %10s  %s\n" $njob $jobid $part $nodes $cpus $head $timelim $elap $jname $workdir   #FORMATTED OUTPUT PRINTING.
	    fi                      #END "IF" REGARDING WHETHER THE JOB ID IS ONE OF THE INPUT ARGUMENTS.
	    ((njob++))              #ADD 1 TO $njob; PROGRESS VARIABLE FORWARD BY 1. EQUIVALENT TO njob=$((njob+1)).
	done < "__TMP_RUNNING_$$"   #READ THE TEMPORARY FILE INTO THE "while read..." LOOP.

    else                            #...ELSE, PRINT INFO ON ALL JOBS, NOT JUST CERTAIN JOB ID'S.

	#NOTE: THIS "WHILE" BLOCK IS IDENTICAL TO THE PREVIOUS ONE, OTHER THAN THE "PRINT ONLY IF..." CONDITION.
	while read -r jobid part nodes cpus head timelim elap jobname workdir; do        #READ DATA FROM THE TEMPORARY FILE AS WHITESPACE-SEPARATED VARIABLES NAMED THUS.
#	while IFS= read -r jobid part nodes cpus head timelim elap jobname workdir; do   #---DEBUGGING.
	    jname=`echo $jobname | awk -F "~~" '{print $1}'`                             #FIELD SEPARATED ON "~~" & ONLY 1ST FIELD KEPT.
	    printf " %-4s  %7s  %10s  %5s  %4s  %11s  %12s  %19s  %10s  %s\n" $njob $jobid $part $nodes $cpus $head $timelim $elap $jname $workdir   #FORMATTED OUTPUT PRINTING.
	    ((njob++))              #ADD 1 TO $njob; PROGRESS VARIABLE FORWARD BY 1. EQUIVALENT TO njob=$((njob+1)).
	done < "__TMP_RUNNING_$$"   #READ THE TEMPORARY FILE INTO THE "while read..." LOOP.

    fi                              #END "IF" REGARDING WHETHER TO PRINT INFO ON ALL OR ONLY CERTAIN JOB ID'S.
    echo "============================================================================================================="
    rm __TMP_RUNNING_$$             #DELETE THE TEMPORARY FILE AFTER READING/USING ALL ITS INFORMATION.
}



#================================================================================================
#===== SUBROUTINE FOR FINDING THE SPECIAL STATUS "COMMENT" FROM A RUNNING JOB'S OUTPUT FILE =====
function get_comment {
    jobid=$1      #1ST ARGUMENT PASSED TO THIS SUBROUTINE IS THE $SLURM_JOB_ID.
    jname=$2      #2ND ARGUMENT IS THE 1ST FIELD OF "#SBATCH --job-name", SEPARATED ON "~~".
    headnode=$3   #3RD ARGUMENT IS THE HEAD NODE ON WHICH THE JOB IS RUNNING.
    outfile=$4    #4TH ARGUMENT IS THE OUTPUT FILE, DESIGNATED TO BE THE 2ND FIELD OF THE "~~"-SEPARATED "#SBATCH --job-name".

    #--------------------------------------------------
    #----- HPC-SPECIFIC LOCATIONS OF RUNNING JOBS -----
##    size_gscr=`du /scratch/$jobid | awk '{print $1}'`                          #MEASURE THE DISK SIZE OF GLOBAL SCRATCH'S JOB DIRECTORY.
##    size_lscr=`ssh -n $headnode du /local_scratch/$jobid | awk '{print $1}'`   #MEASURE THE DISK SIZE OF LOCAL SCRATCH'S JOB DIRECTORY.
##    if [[ $size_gscr > $size_lscr ]]; then   #IF YOUR JOB'S GLOBAL SCRATCH DIRECTORY IS LARGER THAN YOUR LOCAL SCRATCH DIRECTORY...
    if [ -d "/scr1/$jobid" ]; then            #IF A JOB DIRECTORY EXISTS IN /scr1/...
	if [[ `du -s /scr1/$jobid | awk '{print $1}'` -gt 20 ]]; then     #...& AN EMPTY DIRECTORY + THE machinefile_${SLURM_JOB_ID} HAS SIZE OF 20.
	    scrdir="/scr1/$jobid"             #...THEN YOU ARE USING GLOBAL SCRATCH...
	else                                  #...OTHERWISE...
	    scrdir="/local_scratch/$jobid"    #...ASSUME YOU ARE USING LOCAL SCRATCH.
	fi                                    #END "IF GLOBAL OR LOCAL SCRATCH." 
    elif [ -d "/scr2/$jobid" ]; then
	if [[ `du -s /scr2/$jobid | awk '{print $1}'` -gt 20 ]]; then     #AN EMPTY DIRECTORY + THE machinefile_${SLURM_JOB_ID} HAS SIZE OF 20.
	    scrdir="/scr2/$jobid"             #...THEN YOU ARE USING GLOBAL SCRATCH...
	else                                  #...OTHERWISE...
	    scrdir="/local_scratch/$jobid"    #...ASSUME YOU ARE USING LOCAL SCRATCH.
	fi
    fi                                        #END "IF /scr1/, /scr2/, OR /local_scratch/".
#   echo "scrdir = $scrdir"                   #---DEBUGGING.
    #--------------------------------------------------

    #UNIQUE JOBS MAY NEED UNIQUE OPERATIONS... A SIMPLE GREP DOESN'T ALWAYS SUFFICE.
    if [[ $jname == "CRYOFF" ]]; then
	comment=`ssh -n $headnode grep -- 'Ymax-Ymin' $scrdir/$outfile | tail -1`   #SHOULD BE THE CRYOFF .off FILE.

    elif [[ $jname == "GAMESS" ]]; then
	comment=`ssh -n $headnode grep -B1 -- ----- $scrdir/$outfile | tail -2 | head -1`   #CURRENTLY EXPERIMENTAL!!!

    elif [[ $jname == "GROMACS" ]]; then
	comment=`ssh -n $headnode tail -15 $scrdir/$outfile | grep -A1 Time | tail -1`   #FILE THAT GROMACS CALLS "md.log".

    elif [[ $jname == "MOLPRO" ]]; then
#	comment="nope"   #---DEBUGGING.
	comment=`ssh -n $headnode "grep -e 'Starting' -e 'PROGRAM ' $scrdir/$outfile | tail -1" ` 
	#SOMETHING LIKE THIS:     PROGRAM * RHF-SCF (CLOSED SHELL)       Authors: W. Meyer, H.-J. Werner

    elif [[ $jname == "SAPT" ]]; then
	comment=`ssh -n $headnode grep -i -e energy -e integral $scrdir/$outfile | tail -1`   #FIND LAST OCCURANCE OF EITHER "ENERGY" OR "INTEGRAL".

    elif [[ $jname == "STRFACT" ]]; then
#	comment=`ssh -n $headnode grep -e RDF $scrdir/$outfile | tail -1`   #FIND LAST OCCURANCE OF CAPITAL "RDF".
	comment=`ssh -n $headnode grep -e RDF $workdir/$outfile | tail -1`   #FIND LAST OCCURANCE OF CAPITAL "RDF".

    elif [[ $jname == "VASP" ]]; then
	comment=`ssh -n $headnode grep F $scrdir/$outfile | tail -1`   #FILE THAT VASP CALLS "OSZICAR".

    elif [[ $jname == "COMSOL" ]]; then
	comment='Comment not yet implement for COMSOL. Want to help?'
    elif [[ $jname == "PQS" ]]; then   #PARALLEL QUANTUM SOLUTIONS.
	comment='Comment not yet implement for PQS. Want to help?'
    elif [[ $jname == "GAUSSIAN" ]]; then
	comment='No comment implemented for GAUSSIAN. Want to help?'

    elif [[ $jname == "bash" ]]; then   #"bash" SEEMS TO BE THE NAME FOUND IF NO "--job-name=" WAS PROVIDED.
	comment='Could be an interactive job.'

    else
	comment="No comment programmed for $jname jobs in this version of ahpcc_slurmjob_watcher.sh"
    fi
    echo "$comment"   #PRINT TO STDOUT WHICHEVER "COMMENT" STRING WAS FOUND TO BE APPROPRIATE.
}



#===========================================================================
#===== SUBROUTINE FOR OBTAINING EXTRA INFO FOR ALL YOUR "RUNNING" JOBS =====
function verbose_running {
#    comment="Comments not yet implemented."   #---DEBUGGING.
    echo "========================================================================================================================================"
    echo " #       JOBID   PARTITION  NODES  CPUS    NODE_LIST  CPU_1m  CPU_15m    TIME_LIMIT            ELAP_TIME    JOB_NAME  WORK_DIR / COMMENT"
    echo "----------------------------------------------------------------------------------------------------------------------------------------"
#    squeue -h -o "%A  %P  %D  %C  %B  %l  %M  %j  %Z  %N" --states=R  > __TMP_RUNNING_$$           #---DEBUGGING.
    squeue -h -u $USER -o "%A  %P  %D  %C  %B  %l  %M  %j  %Z  %N" --states=R  > __TMP_RUNNING_$$   #SAVE squeue DATA WITH NO HEADER OF $USER'S RUNNING JOBS TO A TEMPORARY FILE.
    njob=1
    if [[ $special_ids == 1 ]]; then   #IF INFO ON ONLY CERTAIN JOB ID'S WAS REQUESTED, THEN DO A SPECIAL LOOP...

	while read -r jobid part nodes cpus headnode timelim elap jobname workdir nodelist; do      #READ DATA FROM THE TEMPORARY FILE AS "\s+"-SEPARATED VARIABLES NAMED THUS.
	    jname=`echo $jobname   | awk -F "~~" '{print $1}'`                                      #FIELD SEPARATED ON "~~" & ONLY 1ST FIELD KEPT.
	    outfile=`echo $jobname | awk -F "~~" '{print $2}'`                                      #FIELD SEPARATED ON "~~" & ONLY 2ND FIELD KEPT.
#	    echo "outfile is $outfile"                                                              #---DEBUGGING.
	    cpu_use=(`ssh -n $headnode uptime | awk -F ", |: " '{print $(NF-2),$NF}'`)              #MEASURE HEAD NODE'S CPU USAGE IN LAST 1 & 15 MINUTES VIA uptime.
	    
	    if [[ "${args[@]}" == *"$jobid"* ]]; then           #IN THIS SPECIAL LOOP, ONLY PRINT INFO IF $jobid IS ONE OF THE INPUT ARGUMENTS.		
		printf " %-4s  %7s  %10s  %5s  %4s  %11s  %6s  %7s  %12s  %19s  %10s  %s\n" $njob $jobid $part $nodes $cpus $headnode ${cpu_use[0]} ${cpu_use[1]} $timelim $elap $jname $workdir
		allnodes=(`scontrol show hostname $nodelist`)   #MAKE ARRAY OF ALL NODE NAMES EXPLICITLY. E.G., NOT "c[1309-1323]".
#		echo "${allnodes[@]}"                           #---DEBUGGING.
		unset allnodes[0]                               #THIS IS THE HEAD NODE, WHICH WE ALREADY KNOW AND ALREADY PRINTED.
#		echo "      ${allnodes[@]}"                     #---DEBUGGING.	
		comment=`get_comment $jobid $jname $headnode $outfile`   #USE THE "get_comment" SUBROUTINE WITH APPROPRIATE ARGUMENTS.
#		get_comment $jobid $jname $headnode $outfile    #---DEBUGGING.
	
		if [[ ${#allnodes[@]} > 0 ]]; then              #IF THE JOB IS USING MORE THAN ONE NODE, THEN...
#		    echo "need to do node2!"                    #---DEBUGGING.
		    node2=${allnodes[1]}                        #...SAVE 2ND NODE TO SPECIAL VARIABLE.
#		    echo "node2=$node2"                         #---DEBUGGING.
		    unset allnodes[1]                           #TAKE 2ND NODE OUF OF NODE LIST, SINCE WE DO DO SPECIAL PRINTING FOR IT (VIZ. PRINT COMMENT ON THIS LINE).
#		    echo "            ${allnodes[@]}"           #---DEBUGGING.
		    cpu_use=(`ssh -n $node2 uptime | awk -F ", |: " '{print $(NF-2),$NF}'`)
		    printf " %-4s  %7s  %10s  %5s  %4s  %11s  %6s  %7s  %12s  %19s  %10s  %s\n" ''   ''    ''    ''     ''  $node2 ${cpu_use[0]} ${cpu_use[1]}   ''      ''    ''   "$comment"
		    for each in ${allnodes[@]}; do      #FOR ALL NODES AFTER 1ST & 2ND IN NODE LIST:
			cpu_use=(`ssh -n $each uptime | awk -F ", |: " '{print $(NF-2),$NF}'`)   #MEASURE EACH NODE'S CPU USAGE IN LAST 1 & 15 MINUTES VIA uptime.
			printf " %-4s  %7s  %10s  %5s  %4s  %11s  %6s  %7s  %12s  %19s  %10s  %s\n"  ''  ''  ''  ''     ''  $each  ${cpu_use[0]} ${cpu_use[1]}   ''      ''    ''   ''
		    done                #END OF LOOPING OVER NODES IN LIST "allnodes".
		else                    #IF JOB ONLY USED 1 NODE, JUST PRINT A LINE THAT IS BLANK, SAVE FOR THE COMMENT:
		    printf " %-4s  %7s  %10s  %5s  %4s  %11s  %6s  %7s  %12s  %19s  %10s  %s\n" ''   ''    ''    ''     ''  ''     ''            ''              ''      ''    ''   "$comment"
		fi                      #END "IF" REGARDING WHETHER THERE ARE MULTIPLE NODES ASSIGNED TO ONE JOB.
		echo                    #PRINT A BLANK LINE TO SEPARATE DATA BLOCKS OF EACH JOB.
		
	    fi                          #END "IF" REGARDING WHETHER THE JOB ID IS ONE OF THE INPUT ARGUMENTS.

	    ((njob++))                  #ADD 1 TO $njob; PROGRESS VARIABLE FORWARD BY 1. EQUIVALENT TO njob=$((njob+1)).
	done < "__TMP_RUNNING_$$"       #READ THE FILE INTO THE "while read..." LOOP.

    else                                #...ELSE, PRINT INFO ON ALL JOBS, NOT JUST CERTAIN JOB ID'S.

	#NOTE: THIS "WHILE" BLOCK IS IDENTICAL TO THE PREVIOUS ONE, OTHER THAN THE "PRINT ONLY IF..." CONDITION.
	while read -r jobid part nodes cpus headnode timelim elap jobname workdir nodelist; do   #READ DATA FROM THE TEMPORARY FILE AS "\s+"-SEPARATED VARIABLES NAMED THUS.
	    jname=`echo $jobname   | awk -F "~~" '{print $1}'`                                   #FIELD SEPARATED ON "~~" & ONLY 1ST FIELD KEPT.
	    outfile=`echo $jobname | awk -F "~~" '{print $2}'`                                   #FIELD SEPARATED ON "~~" & ONLY 2ND FIELD KEPT.
	    cpu_use=(`ssh -n $headnode uptime | awk -F ", |: " '{print $(NF-2),$NF}'`)           #MEASURE HEAD NODE'S CPU USAGE IN LAST 1 & 15 MINUTES VIA uptime.
	    printf " %-4s  %7s  %10s  %5s  %4s  %11s  %6s  %7s  %12s  %19s  %10s  %s\n" $njob $jobid $part $nodes $cpus $headnode ${cpu_use[0]} ${cpu_use[1]} $timelim $elap $jname $workdir
	    allnodes=(`scontrol show hostname $nodelist`)            #MAKE ARRAY OF ALL NODE NAMES EXPLICITLY. E.G., NOT "c[1309-1323]".
	    unset allnodes[0]                                        #THIS IS THE HEAD NODE, WHICH WE ALREADY KNOW AND ALREADY PRINTED.
	    comment=`get_comment $jobid $jname $headnode $outfile`   #USE THE "get_comment" SUBROUTINE WITH APPROPRIATE ARGUMENTS.
	    if [[ ${#allnodes[@]} > 0 ]]; then                       #IF THE JOB IS USING MORE THAN ONE NODE, THEN...
		node2=${allnodes[1]}                                 #...SAVE 2ND NODE TO SPECIAL VARIABLE.
		unset allnodes[1]                                    #TAKE 2ND NODE OUF OF NODE LIST, SINCE WE DO DO SPECIAL PRINTING FOR IT (VIZ. PRINT COMMENT ON THIS LINE).
		cpu_use=(`ssh -n $node2 uptime | awk -F ", |: " '{print $(NF-2),$NF}'`)
		printf " %-4s  %7s  %10s  %5s  %4s  %11s  %6s  %7s  %12s  %19s  %10s  %s\n" ''   ''    ''    ''     ''  $node2 ${cpu_use[0]} ${cpu_use[1]}   ''      ''    ''   "$comment"
		for each in ${allnodes[@]}; do                       #FOR ALL NODES AFTER 1ST & 2ND IN NODE LIST:
		    cpu_use=(`ssh -n $each uptime | awk -F ", |: " '{print $(NF-2),$NF}'`)   #MEASURE EACH NODE'S CPU USAGE IN LAST 1 & 15 MINUTES VIA uptime.
		    printf " %-4s  %7s  %10s  %5s  %4s  %11s  %6s  %7s  %12s  %19s  %10s  %s\n"  ''  ''  ''  ''     ''  $each  ${cpu_use[0]} ${cpu_use[1]}   ''      ''    ''   ''
		done                    #END OF LOOPING OVER NODES IN LIST "allnodes".
	    else                        #IF JOB ONLY USED 1 NODE, JUST PRINT A LINE THAT IS BLANK, SAVE FOR THE COMMENT:
		printf " %-4s  %7s  %10s  %5s  %4s  %11s  %6s  %7s  %12s  %19s  %10s  %s\n" ''   ''    ''    ''     ''  ''     ''            ''              ''      ''    ''   "$comment"
		echo                    #PRINT A BLANK LINE TO SEPARATE DATA BLOCKS OF EACH JOB.
	    fi
	    ((njob++))                  #ADD 1 TO $njob; PROGRESS VARIABLE FORWARD BY 1. EQUIVALENT TO njob=$((njob+1)).
	done < "__TMP_RUNNING_$$"       #READ THE FILE INTO THE "while read..." LOOP.
	
    fi                                  #END "IF" REGARDING WHETHER TO PRINT INFO ON ALL OR ONLY CERTAIN JOB ID'S.
    
    echo "========================================================================================================================================"
    rm __TMP_RUNNING_$$                 #DELETE THE TEMPORARY FILE AFTER READING/USING ALL ITS INFORMATION.
}



#==============================================================================
#===== SUBROUTINE FOR OBTAINING STANDARD INFO FOR ALL YOUR "PENDING" JOBS =====
function standard_pending {
    echo " #       JOBID   PARTITION  NODES  CPUS   SCHEDNODES    TIME_LIMIT       EST_START_TIME    JOB_NAME  WORK_DIR"
    echo "-------------------------------------------------------------------------------------------------------------"
#   squeue -h -o "%A  %P  %D  %C  %Y  %l  %S  %j  %Z" --states=PD | head -n $show_n_pd > __TMP_PENDING_$$           #---DEBUGGING.
    squeue -h -u $USER -o "%A  %P  %D  %C  %Y  %l  %S  %j  %Z" --states=PD | head -n $show_n_pd > __TMP_PENDING_$$   #COLLECT squeue DATA ON "PD" JOBS, BUT ONLY NUMBER REQUESTED!
#   cat __TMP_PENDING_$$   #---DEBUGGING.
    njob=1
#   while IFS= read -r line; do
#       printf " %-4s  %7s  %10s  %5s  %4s  %11s  %12s  %19s  %s\n" $njob $line   #---DEBUGGING.
    while read -r jobid part nodes cpus schedn timelim starttime jobname workdir; do
	jname=`echo $jobname | awk -F "~~" '{print $1}'`                       #FIELD SEPARATED ON "~~" & ONLY 1ST FIELD KEPT.
	printf " %-4s  %7s  %10s  %5s  %4s  %11s  %12s  %19s  %10s  %s\n" $njob $jobid $part $nodes $cpus $schedn $timelim $starttime $jname $workdir
    njob=$((njob+1))            #ADD 1 TO $njob; PROGRESS VARIABLE FORWARD BY 1. EQUIVALENT TO ((njob++)).
    done < "__TMP_PENDING_$$"   #READ THE FILE INTO THE "while read..." LOOP.
    echo "============================================================================================================="
    rm __TMP_PENDING_$$         #DELETE THE TEMPORARY FILE AFTER READING/USING ALL ITS INFORMATION.
}



#==========================================================================
#===== PRODUCE THE EXPECTED OUTPUT SECTIONS BASED ON INPUT CONDITIONS =====
if [[ $verbose > 0 ]]; then                          #IF "VERBOSE PRINTING" FLAG IS SET TO "ON"...
#    echo "verbose printing requested"               #---DEBUGGING.
#    standard_running                                #---DEBUGGING. SHOULD BE "verbose_running"!
    verbose_running                                  #...RUN SUBROUTINE FOR VERBOSE OUTOUT...
else                                                 #...OTHERISE...
    standard_running                                 #...JUST PRINT NON-VERBOSE OUTPUT.
fi

if [[ $show_n_pd > 0 && $special_ids == 0 ]]; then   #IF PENDING JOBS WERE REQUESTED TO BE DISPLAYED & PRINTING FOR ONLY CERTAIN JOB ID'S WAS *NOT* REQUESTED...
    standard_pending                                 #...THEN RUN THE "PD" JOB SUBROUTINE.
fi
