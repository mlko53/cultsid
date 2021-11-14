#!/bin/bash

masks=(acingf caudatef dlpfcf insf mpfcf nacc8mmf)
masks_both=(wm csf rtpj ramyg lamyg)
subject=${1}
script_dir=`pwd`
TLRC_TEMPLATE=/home/groups/jltsai/mlko53/cultsid/masks/TT_N27.nii

cd ../data/fmri/${subject}

# make timecourse folder
if [ ! -d mid_tcs ]; then
    mkdir mid_tcs
fi  

if [ ! -d sid_tcs ]; then
    mkdir sid_tcs
fi  

# make func_proc folder
if [ ! -d func_proc ]; then
    mkdir func_proc
fi  
cd func_proc

# make xfs folder
if [ ! -d xfs ]; then
    mkdir xfs
fi  

# define files
ANAT_FILE=../T1/*.gz
EPI0_FILE=../EPI0/*.gz
EPI1_FILE=../EPI1/*.gz

# copy and rename anatomical
3dcopy -overwrite $ANAT_FILE anat

# skull strip anatomical
3dSkullStrip -overwrite -prefix anat_ss.nii.gz -input anat+orig

# coregister anatomical
@auto_tlrc -overwrite -no_ss -base $TLRC_TEMPLATE -suffix _tlrc -input anat_ss.nii.gz

# clean and move files
gzip anat_ss_tlrc.nii
mv anat_ss_tlrc.Xat.1D xfs/t12mni_xform
mv anat_ss_tlrc.nii_WarpDrive.log xfs/t12mni_xform.log
rm anat_ss_tlrc.nii.Xaff12.1D

# cut off leadin/leadout
3dTcat -overwrite -prefix epi0 $EPI0_FILE[6..389]
3dTcat -overwrite -prefix epi1 $EPI1_FILE[6..389]

# refit and correct time
3drefit -TR 2.0 epi0+orig
3dTshift -overwrite -slice 0 -tpattern altplus -prefix epi0_ts epi0+orig

3drefit -TR 2.0 epi1+orig
3dTshift -overwrite -slice 0 -tpattern altplus -prefix epi1_ts epi1+orig

#### Estimate xform #####

# create reference volume, skull strip, estimate xform
3dTcat -overwrite -prefix ref_vol_sid epi0_ts+orig[4]
3dSkullStrip -prefix ref_vol_sid_ns.nii.gz -input ref_vol_sid+orig
align_epi_anat.py -epi2anat -epi ref_vol_sid_ns.nii.gz -anat anat_ss.nii.gz\
                  -epi_base 0 -tlrc_apar anat_ss_tlrc.nii.gz -epi_strip None -anat_has_skull no

3dTcat -overwrite -prefix ref_vol_mid epi1_ts+orig[4]
3dSkullStrip -prefix ref_vol_mid_ns.nii.gz -input ref_vol_mid+orig
align_epi_anat.py -epi2anat -epi ref_vol_mid_ns.nii.gz -anat anat_ss.nii.gz\
                  -epi_base 0 -tlrc_apar anat_ss_tlrc.nii.gz -epi_strip None -anat_has_skull no

# move files
3dAFNItoNIFTI -prefix ref_vol_sid_tlrc.nii.gz ref_vol_sid_ns_tlrc_al+tlrc
rm ref_vol_sid_ns_tlrc_al+tlrc*
rm ref_vol_sid_ns_al+orig*
cp anat_ss_al_mat.aff12.1D xfs/t12func_sid_xform
mv ref_vol_sid_ns_al_mat.aff12.1D xfs/func2t1_sid_xform
mv ref_vol_sid_ns_al_tlrc_mat.aff12.1D xfs/func2tlrc_sid_xform
rm ref_vol_sid_ns_al_reg_mat.aff12.1D

3dAFNItoNIFTI -prefix ref_vol_mid_tlrc.nii.gz ref_vol_mid_ns_tlrc_al+tlrc
rm ref_vol_mid_ns_tlrc_al+tlrc*
rm ref_vol_mid_ns_al+orig*
mv anat_ss_al_mat.aff12.1D xfs/t12func_mid_xform
mv ref_vol_mid_ns_al_mat.aff12.1D xfs/func2t1_mid_xform
mv ref_vol_mid_ns_al_tlrc_mat.aff12.1D xfs/func2tlrc_mid_xform
rm ref_vol_mid_ns_al_reg_mat.aff12.1D

#### Back to preprocessing #####

# tcat functional dataset together
3dTcat -overwrite -prefix sid epi0_ts+orig
3dTcat -overwrite -prefix mid epi1_ts+orig

# motion correction, censor vector and motion graph
3dvolreg -overwrite -Fourier -twopass -prefix sid_m -base ref_vol_sid+orig -dfile 3dmotion_sid.1D sid+orig
1d_tool.py -infile 3dmotion_sid.1D[1..6] -show_censor_count -censor_prev_TR -censor_motion 0.5 sid
1dplot -png motion_plot_sid 3dmotion_sid.1D[4..6]

3dvolreg -overwrite -Fourier -twopass -prefix mid_m -base ref_vol_mid+orig -dfile 3dmotion_mid.1D mid+orig
1d_tool.py -infile 3dmotion_mid.1D[1..6] -show_censor_count -censor_prev_TR -censor_motion 0.5 mid
1dplot -png motion_plot_mid 3dmotion_mid.1D[4..6]

# gaussian blur
3dmerge -overwrite -1blur_fwhm 4 -doall -prefix sid_mb sid_m+orig
3dmerge -overwrite -1blur_fwhm 4 -doall -prefix mid_mb mid_m+orig

# normalize
3dTstat -overwrite -prefix sid_average sid_mb+orig
3dcalc -overwrite -datum float -a sid_mb+orig -b sid_average+orig -expr "((a-b)/b)*100" -prefix sid_mbn

3dTstat -overwrite -prefix mid_average mid_mb+orig
3dcalc -overwrite -datum float -a mid_mb+orig -b mid_average+orig -expr "((a-b)/b)*100" -prefix mid_mbn

# fourier highpass filter
3dFourier -highpass 0.011 -prefix sid_mbnf sid_mbn+orig
3dFourier -highpass 0.011 -prefix mid_mbnf mid_mbn+orig

# refit to anatomical
3drefit -apar anat+orig sid_mbnf+orig
3drefit -apar anat+orig mid_mbnf+orig

# write final preprocessed dataset and warp to template
3dAFNItoNIFTI -prefix sid_pp_orig.nii.gz sid_mbnf+orig
3dAllineate -overwrite -base anat_ss_tlrc.nii.gz -1Dmatrix_apply xfs/func2tlrc_sid_xform\
            -prefix sid_pp_tlrc -input sid_pp_orig.nii.gz -verb -master BASE\
            -mast_dxyz 2.9 -weight_frac 1.0 -maxrot 6 -maxshf 10 -VERB -warp aff -source_automask+4 -onepass

3dAFNItoNIFTI -prefix mid_pp_orig.nii.gz mid_mbnf+orig
3dAllineate -overwrite -base anat_ss_tlrc.nii.gz -1Dmatrix_apply xfs/func2tlrc_mid_xform\
            -prefix mid_pp_tlrc -input mid_pp_orig.nii.gz -verb -master BASE\
            -mast_dxyz 2.9  -weight_frac 1.0 -maxrot 6 -maxshf 10 -VERB -warp aff -source_automask+4 -onepass

# dump time series
for mask in ${masks[@]}
do
    3dmaskave -mask ../../../../masks/${mask}+tlrc -quiet -mrange 1 1 mid_pp_tlrc+tlrc > ../mid_tcs/l_${mask}.1D
    3dmaskave -mask ../../../../masks/${mask}+tlrc -quiet -mrange 2 2 mid_pp_tlrc+tlrc > ../mid_tcs/r_${mask}.1D
    3dmaskave -mask ../../../../masks/${mask}+tlrc -quiet -mrange 1 2 mid_pp_tlrc+tlrc > ../mid_tcs/b_${mask}.1D

    3dmaskave -mask ../../../../masks/${mask}+tlrc -quiet -mrange 1 1 sid_pp_tlrc+tlrc > ../sid_tcs/l_${mask}.1D
    3dmaskave -mask ../../../../masks/${mask}+tlrc -quiet -mrange 2 2 sid_pp_tlrc+tlrc > ../sid_tcs/r_${mask}.1D
    3dmaskave -mask ../../../../masks/${mask}+tlrc -quiet -mrange 1 2 sid_pp_tlrc+tlrc > ../sid_tcs/b_${mask}.1D
done

for mask in ${masks_both[@]}
do
    3dmaskave -mask ../../../../masks/${mask}+tlrc -quiet -mrange 1 2 mid_pp_tlrc+tlrc > ../mid_tcs/${mask}.1D
    3dmaskave -mask ../../../../masks/${mask}+tlrc -quiet -mrange 1 2 sid_pp_tlrc+tlrc > ../sid_tcs/${mask}.1D
done

# remove useless files
rm anat+orig*
rm epi0+orig*
rm epi0_ts+orig*
rm ref_vol_sid+orig*
rm sid_average+orig*
rm sid+orig*
rm sid_m+orig*
rm sid_mb+orig*
rm sid_mbn+orig*
rm epi1+orig*
rm epi1_ts+orig*
rm ref_vol_mid+orig*
rm mid_average+orig*
rm mid+orig*
rm mid_m+orig*
rm mid_mb+orig*
rm mid_mbn+orig*

cd $script_dir
