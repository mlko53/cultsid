library(tidyverse)
library(tidyselect)
library(stringr)
library(readr)


SUBJECTS <- c('ac081918', 'ac082219', 'al052019', 'az072519',
              'bg102919', 'ch102218', 'dv111518',
              'fd111018', 'gl052518', 'he042718',
              'hw111117', 'is060118', 'jd051818', 'jd072919', 'jk102518',
              'jl053119', 'js082419', 'js101518', 'jv102919', 'kl112918',
              'kt082818', 'lh102418', 'lp102118', 'mc111218', 'mh071418',
              'mp083018', 'mp110618', 'mr111019', 'nb102318', 'pw073019',
              'qh111717', 'rt022718', 'sm110518',
              'sw050818', 'sw110818', 'tl111017', 'wx060119',
              'xl042618', 'xz071218', 'yd072319', 'yd081018', 'yg042518',
              'yl070418', 'yl070518', 'yl073119', 'yl080118', 'yp070418',
              'yq052218', 'yw070618', 'yw081018', 'yx072518', 'yy072919', 'zp111019')
# hd102119
RUNS <- c("mid", "sid")
SIDES <- c("b", "l", "r")
TR_LEN <- 2
TR_DELAY <- 8
VOIS <- c("acing", "caudate", "dlpfc", "ins", "mpfc", "nacc8mm")
VOIS_SINGLES <- c("wm", "csf", "rtpj", "ramyg", "lamyg")

BHVR_PATH <- "../data/bhvr/fmri/subject_run.csv"
CENSOR_PATH <- "../data/fmri/subject/func_proc/run_censor.1D"
VOI_PATH <- "../data/fmri/subject/run_tcs/side_voif.1D"
VOI_SINGLE_PATH <- "../data/fmri/subject/run_tcs/voi.1D"

for(run in RUNS){
    
    allSubjects <- NULL
    output_file <- str_replace_all("../timecourse/run_timecourse.csv", c("run"=run))

    for(subject in SUBJECTS){
        print(subject)

        bhvr <- read_csv(str_replace_all(BHVR_PATH, c("subject"=subject,"run"=toupper(run))), col_type=cols())
        censor <- read_delim(str_replace_all(CENSOR_PATH, c("subject"=subject, "run"=run)),
                             "\t", col_names="censor", col_types=cols(), escape_double=FALSE, trim_ws=TRUE)

        for(voi in c(VOIS, VOIS_SINGLES)){
            for(side in SIDES){
        
                if(voi %in% VOIS_SINGLES && side != "b"){
                    next
                }

                if(voi %in% VOIS_SINGLES){
                    col_name <- voi
                    file_path <- str_replace_all(VOI_SINGLE_PATH, c("subject"=subject, "run"=run, "voi"=voi))
                } else{
                    col_name <- paste(side, voi, sep="_")
                    file_path <- str_replace_all(VOI_PATH, c("subject"=subject, "run"=run, "side"=side, "voi"=voi))
                }
                df_voi <- read_delim(file_path, "\t", col_names=col_name, col_types=cols(), escape_double=FALSE, trim_ws=TRUE)

                m <- mean(df_voi[[1]], na.rm=TRUE)
                s <- sd(df_voi[[1]], na.rm=TRUE)
                upper <- m + 3*s
                lower <- m - 3*s
                
                df_voi <- df_voi %>% 
                    bind_cols(censor) %>%
                    mutate(!!col_name := ifelse(.[[1]] > upper | .[[1]] < lower, yes = .[[1]], no = .[[1]])) %>%
                    transmute(!!col_name := ifelse(censor == 0, yes = NA, no = .[[1]]))


                for(tr in 1:TR_DELAY){
                    df_voi <- df_voi %>%
                        mutate(!! str_c(as.name(col_name), "-TR-", as.name(tr)) := lead(.[[1]], tr - 1))
                }
                df_voi <- df_voi %>% select(-1)
                bhvr <- bind_cols(bhvr, df_voi)
            }
        }
        bhvr <- bhvr %>% subset(TR == 1) %>% mutate(subject = subject)
        allSubjects <-  bind_rows(allSubjects, bhvr)
        #### DO SOMETHING MORE HERE ####
    }
    
    allSubjects <- allSubjects %>%
        pivot_longer(cols = contains("-TR-"),
                     names_to = c("voi", "tr"),
                     names_sep = "-TR-",
                     values_to = "BOLD") %>%
        mutate(TR = as.numeric(tr),
               time = (TR-1) * TR_LEN) %>%
        select(-tr)

    write_csv(allSubjects, file=output_file, append=FALSE)
}
