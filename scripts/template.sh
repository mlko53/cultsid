#!/bin/bash
#SBATCH --time 01:30:00
#SBATCH --mem 20G

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

csh fmri/preprocess_nocsfwm template
csh fmri/mask_wmcsf template
python fmri/tc.py --subject template
python fmri/motiongraph.py --subject template

echo "Done"
