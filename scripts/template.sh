#!/bin/bash
#SBATCH --time 02:00:00

#SBATCH --job-name="template"
#SBATCH --output=runs/template.out

# list out some useful information
echo "SLURM_JOBID="$SLURM_JOBID
echo "SLURM_JOB_NODELIST"=$SLURM_JOB_NODELIST
echo "SLURM_NNODES"=$SLURM_NNODES
echo "SLURMTMPDIR="$SLURMTMPDIR
echo "working directory = "$SLURM_SUBMIT_DIR
echo "subject = template"

ml biology
ml afni
ml py-scipystack

# preprocessing
csh fmri/preprocess_nocsfwm template

# mask and tc dump
csh fmri/mask_wmcsf template
python fmri/tc.py --subject template

# motion
python fmri/motiongraph.py --subject template

# regression
csh fmri/reg template

echo "Done"
