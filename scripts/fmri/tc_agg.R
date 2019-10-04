### NOTES ###

# packages
library(tibble)

########### Create  SID/MID matrix with ROI for each participant ##############
scripts_dir = getwd()

missing_mid_CH = c('mh071418', 'wh071918', 'xz071218', 'yd081018', 'yl070418', 
                   'yl070518', 'yl080118', 'yp070418', 'yw070618', 'yw081018', 
                   'yx072518')
missing_mid_EA = c('ac081918', 'kt082818', 'mp083018')

ch <- c()
ea <- c()

#### subject list ####
subjects = c('ac081918', 'ac082219', 'al052019', 'ao082819', 'az072519',
            'ch102218','dj051418','dv111518','dy051818','fd111018',
            'gl052518','hc101818','he042718','hw111117','is060118',
            'jd051818','jd072919','jk102518','jl053119','js082419',
            'js101518','kl112918','kt082818','lh102418','lp102118',
            'mc111218','mh071418','mp083018','mp110618','nb102318',
            'pw073019','qh111717','rt022718','sh101518','sm110518',
            'sw050818','sw110818','tl111017','wh071918','wx060119',
            'xl042618','xz071218','yd072319','yd081018','yg042518',
            'yl070418','yl070518','yl073119','yl080118','yp070418',
            'yq052218','yw070618','yw081018','yx072518','yy072919')

#### epi list ####
epi = c('sid', 'mid')

#### create dataframe to store values ####
d.f=data.frame(
  subject=character(),
  b_dlpfcf_raw.tc=character(),b_insf_raw.tc=character(),
  b_mpfcf_raw.tc=character(),b_nacc8mmf_raw.tc=character(),
  b_acingf_raw.tc=character(),b_caudatef_raw.tc=character(),
  r_dlpfcf_raw.tc=character(),r_insf_raw.tc=character(),
  r_mpfcf_raw.tc=character(),r_nacc8mmf_raw.tc=character(),
  r_acingf_raw.tc=character(),r_caudatef_raw.tc=character(),
  l_dlpfcf_raw.tc=character(),l_insf_raw.tc=character(),
  l_mpfcf_raw.tc=character(),l_nacc8mmf_raw.tc=character(),
  l_acingf_raw.tc=character(),l_caudatef_raw.tc=character(),
  stringsAsFactors=F)

for(task in epi){
  #### for each subject ####
  for (sub in subjects){
    print(paste0('Processing ', sub))
    # construct filenames to load data
    matrix_filename = paste0(dirname(scripts_dir), '/data/bhvr/fmri/', sub, '_', toupper(task),'.csv')
    write_fullskewmat_filename = paste0(dirname(scripts_dir), '/timecourse/', task, '/', sub,'_', task, 'tc8tr.csv')
    
    filenames = c()
    for (roi in 1:length(colnames(d.f))){
      filenames[roi] = paste0(dirname(scripts_dir), '/data/fmri/', sub, '/', task, '_tcs/', sub,"_",colnames(d.f)[roi])
    }
    
    # load matrix into dataframe
    d.mat = read.csv(matrix_filename, head=T)

    if(task == 'sid'){
        if(d.mat[1,'ethni_r'] == 1){
            ch <- c(ch, sub)
        }
        if(d.mat[1,'ethni_r'] == 0){
            ea <- c(ea, sub)
        }
    }

    # fix missing columns
    if(task == 'mid'){
        if(sub %in% ch){
            d.mat <- add_column(d.mat, ethni_r = 1, .after = 'TR')
        }
        if(sub %in% ea){
            d.mat <- add_column(d.mat, ethni_r = 0, .after = 'TR')
        }
    }
    
    # load time courses
    dataframenames = c()
    for (roi in 1:length(colnames(d.f))){
      dataframenames[roi] = paste('d.',colnames(d.f)[roi], sep='')
    }
    
    # append time courses into data frame
    timecourses = data.frame(matrix(nrow=384,ncol=length(colnames(d.f))))
    timecourses[,1] = rep(sub,384)
    for (tc in 2:length(colnames(d.f))){
      timecourses[,tc] = read.table(filenames[tc])
    }
    colnames(timecourses) = colnames(d.f) # get ROI for colnames
    # 4 TR's of interest per trial (*2 seconds per TR), so we want 8 TR's per trial, 64*8=512
    tc512 = cbind(d.mat, timecourses)
    # make each trial 8 TRs long, with proper trial number, condition, etc.
    tc8tr = c()
    trialonset = which(d.mat$TR==1)
    for(start in trialonset){
      end=start+7
      TR=c(1:8)
      trial.tmp = data.frame(rep(tc512[start,'trial'], 8),
                             TR,
                             rep(tc512[start, 'ethni_r'],8),
                             rep(tc512[start, 'trialonset'],8),
                             rep(tc512[start, 'trialtype'],8),
                             rep(tc512[start, 'target_ms'],8),
                             rep(tc512[start, 'rt'],8),
                             rep(tc512[start, 'cue_value'],8),
                             rep(tc512[start, 'hit'],8),
                             rep(tc512[start, 'iti'],8),
                             rep(tc512[start, 'drift'],8),
                             rep(tc512[start, 'total_winpercent'],8),
                             rep(tc512[start, 'binned_winpercent'],8))
      if(task == 'sid'){
        trial.tmp.2 = data.frame(rep(tc512[start, 'valence'],8),
                             rep(tc512[start, 'level'],8),
                             rep(tc512[start, 'ethni_t'],8),
                             rep(tc512[start, 'gender_t'],8),
                             tc512[start:end, colnames(d.f)])
      } else if(task == 'mid'){
        trial.tmp.2 = data.frame(tc512[start:end, colnames(d.f)])
      }
      tc8tr = rbind(tc8tr, cbind(trial.tmp, trial.tmp.2))
    }
    
    if (task == 'sid'){
      colnames(tc8tr)[1:17] = colnames(tc512[1:17])
    }
    else if(task == 'mid'){
      colnames(tc8tr)[1:13] = colnames(tc512[1:13])
    }
    trialnum = c(1:64)
    x = tc8tr
    # exclude last row with NA's
    d.tc8tr = as.data.frame(tc8tr[1:511,])
    write.csv(d.tc8tr, write_fullskewmat_filename, row.names=F)
  }
}

###### Concat all the subjects together ################
for(task in epi){
  d = c()
  for(sub in subjects){
    loadfilename = paste0(dirname(scripts_dir), '/timecourse/',task, '/', sub, '_', task, 'tc8tr.csv')
    temp_d = read.csv(loadfilename, head=T)
    d = rbind(d, temp_d)
  }
  write.csv(d, paste0(dirname(scripts_dir), '/timecourse/', task, '/', task, '_timecourse.csv'), row.names=F)
}
