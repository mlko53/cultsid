#!/bin/bash
#SBATCH --time 00:20:00

#SBATCH --job-name="yy072919"
#SBATCH --output=runs/yy072919.out

# list out some useful information
echo "SLURM_JOBID="$SLURM_JOBID
echo "SLURM_JOB_NODELIST"=$SLURM_JOB_NODELIST
echo "SLURM_NNODES"=$SLURM_NNODES
echo "SLURMTMPDIR="$SLURMTMPDIR
echo "working directory = "$SLURM_SUBMIT_DIR
echo "subject = yy072919"

ml biology
ml afni
ml py-scipystack

# preprocessing
#csh fmri/preprocess_nocsfwm yy072919

# mask and tc dump
#csh fmri/mask_wmcsf yy072919
#python fmri/tc.py --subject yy072919

# motion
#python fmri/motiongraph.py --subject yy072919

# regression
csh fmri/reg_csfwm yy072919

echo "Done"
