# store all ROI timecourses in one csv with mid matrix for each subject jl161220
scripts_dir = getwd()

#### subject list ####
subvec = c('test')

#### create dataframe to store values ####
d.f=data.frame(
  subject=character(),
  b_dlpfc_raw.tc=character(),b_ins_raw.tc=character(),b_antins_desai_mpm_raw.tc=character(),
  b_mpfc_raw.tc=character(),b_nacc8mm_raw.tc=character(),b_nacc_desai_mpm_raw.tc=character(),
  b_acing_raw.tc=character(),b_caudate_raw.tc=character(),b_vlpfc_raw.tc=character(),
  r_dlpfc_raw.tc=character(),r_ins_raw.tc=character(),r_antins_desai_mpm_raw.tc=character(),
  r_mpfc_raw.tc=character(),r_nacc8mm_raw.tc=character(),r_nacc_desai_mpm_raw.tc=character(),
  r_acing_raw.tc=character(),r_caudate_raw.tc=character(),r_vlpfc_raw.tc=character(),
  l_dlpfc_raw.tc=character(),l_ins_raw.tc=character(),l_nacc_desai_mpm_raw.tc=character(),
  l_mpfc_raw.tc=character(),l_nacc8mm_raw.tc=character(),l_antins_desai_mpm_raw.tc=character(),
  l_acing_raw.tc=character(),l_caudate_raw.tc=character(),l_vlpfc_raw.tc=character(),
  stringsAsFactors=F)

#### for each subject ####
for (i in 1:length(subvec)){
  # construct filenames to load data
  matrix_filename = paste0(dirname(scripts_dir), '/data/bhvr/', subvec[i],'_sid_matrix.csv')
  write_fullskewmat_filename = paste0(dirname(scripts_dir), '/data/sid_tcs/', subvec[i],'_sidtc8tr.csv')
  
  filenames = c()
  for (roi in 1:length(colnames(d.f))){
    filenames[roi] = paste0(dirname(scripts_dir), '/data/fmri/', subvec[i], '/sid_tcs/', subvec[i],"_",colnames(d.f)[roi])
  }
  
  # load sid matrix into dataframe
  d.sidmat = read.csv(matrix_filename, head=T)

  # load time courses
  dataframenames = c()
  for (roi in 1:length(colnames(d.f))){
    dataframenames[roi] = paste('d.',colnames(d.f)[roi], sep='')
  }
  
  # append time courses into data frame
  timecourses = data.frame(matrix(nrow=384,ncol=length(colnames(d.f))))
  timecourses[,1] = rep(subvec[i],384)
  for (tc in 2:length(colnames(d.f))){
    timecourses[,tc] = read.table(filenames[tc])
  }
  colnames(timecourses) = colnames(d.f) # get ROI for colnames
  
  # 4 TR's of interest per trial (*2 seconds per TR), so we want 8 TR's per trial, 64*8=512
  d.sidtc512 = cbind(d.sidmat, timecourses)

  # make each trial 8 TRs long, with proper trial number, condition, etc.
  sidtc8tr = c()
  trialonset = which(d.sidmat$TR==1)
  for(start in trialonset){
    end=start+7
    TR=c(1,2,3,4,5,6,7,8)
    trial.tmp = data.frame(rep(d.sidtc512[start,1],8),# trial
                           TR,
                           rep(d.sidtc512[start,3],8),# ethni_r
                           rep(d.sidtc512[start,4],8),# trialonset
                           rep(d.sidtc512[start,5],8),# trialtype
                           rep(d.sidtc512[start,6],8),# target_ms
                           rep(d.sidtc512[start,7],8),# rt
                           rep(d.sidtc512[start,8],8),# cue_value
                           rep(d.sidtc512[start,9],8),# hit
                           rep(d.sidtc512[start,10],8),# iti
                           rep(d.sidtc512[start,11],8),# drift
                           rep(d.sidtc512[start,12],8),# total_winpercent
                           rep(d.sidtc512[start,13],8),# binned_winpercent
                           rep(d.sidtc512[start,14],8),# valence
                           rep(d.sidtc512[start,15],8),# level
                           rep(d.sidtc512[start,16],8),# ethni_t
                           rep(d.sidtc512[start,17],8),# gender_t
                           d.sidtc512[start:end,18:45])
    sidtc8tr = rbind(sidtc8tr,trial.tmp)
  }
  colnames(sidtc8tr)[1:17] = colnames(d.sidtc512[1:17])
  trialnum = c(1:64)
  
  # exclude last row with NA's
  d.sidtc8tr = as.data.frame(sidtc8tr[1:511,])
  write.csv(d.sidtc8tr, write_fullskewmat_filename, row.names=F)
}
