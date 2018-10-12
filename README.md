# Cultsid 

SID and MID fMRI and behavioral analysis files. 

## Requirements

* AFNI installed
* python 2 installed
* 30+ GB of memory

## Preprocess Pipeline

1. `preprocess_nocsfwm`
	* anatomical warp, time shift, motion correct, gaussian blur, normalize, fourier highpass
	* sanity check - motiongraph.py
2. `mask_wmcsf`
	* creates wm and csf masks

## Regression Pipeline

1. Run prepro and wmcsf mask first
2. `reg_csfwm`
	* reads SID and MID csv files to create regressors
	* convolve with GAM 
	* create standardized z score dataset
3. `ttest` (not ready yet)

## Timecourse Pipeline

1. `tc_sid.py` (not ready)
	* create individual area TC
2. `d_sid_tc8tr.R` (not ready)
3. `d_catsubs_sidtc8tr.R` (not ready)
4. `p_timecourse_sid.R` (not ready)
