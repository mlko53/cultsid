# plot time courses by TR and MID condition jl160202
# updated by eb for SID 062018
require("ggplot2")
require("ggthemes")
require("reshape2")
require("extrafont")
require("tidyr")
require("plyr")
require("dplyr")
require("forcats")
require("grid")
require("stringr")
library("Hmisc")

# exclude list
exclude = c('dj051418', 'dy051818', 'wh071918')
borderline_exclude = c('tl111017', 'hw111117')

sid.tc = read.csv('../output/sid_tcs/sid_timecourse.csv', head=T)

# exclude participants for motion
sid.tc = sid.tc %>%
  filter(!(subject %in% exclude))

sid.tc$subject = droplevels(sid.tc$subject)

# reoder columns and drop unnecessary variables
sid.tc <- sid.tc[c('trial','TR','trialtype','subject','ethni_r','hit',
                       'l_nacc8mm_raw.tc','r_nacc8mm_raw.tc',
                       'l_nacc_desai_mpm_raw.tc','r_nacc_desai_mpm_raw.tc',
                       'l_ins_raw.tc','r_ins_raw.tc',
                       'l_antins_desai_mpm_raw.tc','r_antins_desai_mpm_raw.tc',
                       'l_mpfc_raw.tc','r_mpfc_raw.tc',
                       'l_dlpfc_raw.tc','r_dlpfc_raw.tc',
                       'l_acing_raw.tc','r_acing_raw.tc',
                       'l_vlpfc_raw.tc','r_vlpfc_raw.tc',
                       'l_caudate_raw.tc','r_caudate_raw.tc')]

# format data columns
sid.tc = sid.tc %>%
  # convert ethnicity to factor and recode 
  mutate(ethni_r = factor(ethni_r, levels = c("0","1"))) %>%
  mutate(ethni_r = fct_recode(ethni_r, "EA"= "0", "CH" = "1")) %>%
  # convert trialtype to factor and recode
  mutate(trialtype = factor(trialtype, levels = c("1","2","3","4","5","6","7","8"))) %>%
  mutate(trialtype = fct_recode(trialtype,
                                  "lan"= "1", "man" = "2", "han" = "3",
                                  "lap"= "4", "map" = "5", "hap" = "6",
                                  "neun" = "7", "neup" = "8"))

# convert to factors
sid.tc$hit = as.factor(sid.tc$hit)
sid.tc$hit = fct_recode(sid.tc$hit, "miss" = "0", "hit" = "1")

####### Tidy Data #######
#########################

# convert to long form
sid.tc.long.sum.bin = sid.tc %>%
  gather(variable, value, l_nacc8mm_raw.tc:r_caudate_raw.tc) %>%
  group_by(TR, trialtype, variable, ethni_r, subject) %>%
  summarise(mean.subject = mean(value),
            se.subject = sd(value)/sqrt(length(value))) %>%
  summarise(mean = mean(mean.subject),
            se.mean = sd(mean.subject)/sqrt(length(unique(sid.tc$subject)))) %>%
  # add column for valence
  mutate(vale = case_when(grepl("n$", trialtype) ~ 'neg',
                          grepl("p$", trialtype) ~ 'pos')) %>%
  # add column for hemisphere
  mutate(hemi = case_when(grepl("l_", variable) ~ 'left',
                          grepl("r_", variable) ~ 'right'))

sid.tc.long.sum = sid.tc %>%
  gather(variable, value, l_nacc8mm_raw.tc:r_caudate_raw.tc) %>%
  group_by(TR, trialtype, variable, hit, ethni_r, subject) %>%
  summarise(mean.subject = mean(value),
            se.subject = sd(value)/sqrt(length(value))) %>%
  summarise(mean = mean(mean.subject),
            se.mean = sd(mean.subject)/sqrt(length(unique(sid.tc$subject)))) %>%
  # add column for valence
  mutate(vale = case_when(grepl("n$", trialtype) ~ 'neg',
                            grepl("p$", trialtype) ~ 'pos')) %>%
  # add column for hemisphere
  mutate(hemi = case_when(grepl("l_", variable) ~ 'left',
                          grepl("r_", variable) ~ 'right'))

sid.tc.long.sum.bin$vale = as.factor(sid.tc.long.sum.bin$vale)
sid.tc.long.sum.bin$variable = as.factor(sid.tc.long.sum.bin$variable)
sid.tc.long.sum.bin$variable = substr(sid.tc.long.sum.bin$variable, start = 3, stop = 999)

sid.tc.long.sum$vale = as.factor(sid.tc.long.sum$vale)
sid.tc.long.sum$variable = as.factor(sid.tc.long.sum$variable)
sid.tc.long.sum$variable = substr(sid.tc.long.sum$variable, start = 3, stop = 999) 

# Created inverse weighted variance dataframes
sid.tc.long.sum.bin.inv = sid.tc %>%
  gather(variable, value, l_nacc8mm_raw.tc:r_caudate_raw.tc) %>%
  group_by(TR, trialtype, variable, ethni_r, subject) %>%
  summarise(mean.subject = mean(value),
            var.subject = var(value)) %>%
  summarise(mean = wtd.mean(mean.subject, 1/var.subject),
            se.mean = sqrt(wtd.var(mean.subject, 1/var.subject))/sqrt(length(unique(sid.tc$subject)))) %>%
  # add column for valence
  mutate(vale = case_when(grepl("n$", trialtype) ~ 'neg',
                            grepl("p$", trialtype) ~ 'pos')) %>%
  # add column for hemisphere
  mutate(hemi = case_when(grepl("l_", variable) ~ 'left',
                          grepl("r_", variable) ~ 'right'))

sid.tc.long.sum.inv = sid.tc %>%
  gather(variable, value, l_nacc8mm_raw.tc:r_caudate_raw.tc) %>%
  group_by(TR, trialtype, variable, hit, ethni_r, subject) %>%
  summarise(mean.subject = mean(value),
            var.subject = var(value)) %>%
  summarise(mean = wtd.mean(mean.subject, 1/var.subject),
            se.mean = sqrt(wtd.var(mean.subject, 1/var.subject))/sqrt(length(unique(sid.tc$subject)))) %>%
  # add column for valence
  mutate(vale = case_when(grepl("n$", trialtype) ~ 'neg',
                            grepl("p$", trialtype) ~ 'pos')) %>%
  # add column for hemisphere
  mutate(hemi = case_when(grepl("l_", variable) ~ 'left',
                          grepl("r_", variable) ~ 'right'))

# convert to factors
sid.tc.long.sum.bin.inv$vale = as.factor(sid.tc.long.sum.bin.inv$vale)
sid.tc.long.sum.bin.inv$variable = as.factor(sid.tc.long.sum.bin.inv$variable)
sid.tc.long.sum.bin.inv$variable = substr(sid.tc.long.sum.bin.inv$variable, start = 3, stop = 999)

sid.tc.long.sum.inv$vale = as.factor(sid.tc.long.sum.inv$vale)
sid.tc.long.sum.inv$variable = as.factor(sid.tc.long.sum.inv$variable)
sid.tc.long.sum.inv$variable = substr(sid.tc.long.sum.inv$variable, start = 3, stop = 999)

## Read and Precompute MID csv

mid.tc = read.csv('../output/mid_tcs/mid_timecourse.csv', head=T)

# exclude participants for motion
mid.tc = mid.tc %>%
  filter(!(subject %in% exclude))

mid.tc$subject = droplevels(mid.tc$subject)

# reoder columns and drop unnecessary variables
mid.tc <- mid.tc[c('trial','TR','trialtype','subject','ethni_r','hit',
                       'l_nacc8mm_raw.tc','r_nacc8mm_raw.tc',
                       'l_nacc_desai_mpm_raw.tc','r_nacc_desai_mpm_raw.tc',
                       'l_ins_raw.tc','r_ins_raw.tc',
                       'l_antins_desai_mpm_raw.tc','r_antins_desai_mpm_raw.tc',
                       'l_mpfc_raw.tc','r_mpfc_raw.tc',
                       'l_dlpfc_raw.tc','r_dlpfc_raw.tc',
                       'l_acing_raw.tc','r_acing_raw.tc',
                       'l_vlpfc_raw.tc','r_vlpfc_raw.tc',
                       'l_caudate_raw.tc','r_caudate_raw.tc')]

####### Tidy Data #######
#########################

mid.tc.long.sum.bin = mid.tc %>%
  gather(variable, value, l_nacc8mm_raw.tc:r_caudate_raw.tc) %>%
  group_by(TR, trialtype, variable, ethni_r, subject) %>%
  summarise(mean.subject = mean(value),
            se.subject = sd(value)/sqrt(length(value))) %>%
  summarise(mean = mean(mean.subject),
            se.mean = sd(mean.subject)/sqrt(length(unique(mid.tc$subject)))) %>%
  # convert ethnicity to factor and recode
  mutate(ethni_r = factor(ethni_r, levels = c("0","1"))) %>%
  mutate(ethni_r = fct_recode(ethni_r, "EA"= "0", "CH" = "1")) %>%
  # convert trialtype to factor and recode
  mutate(trialtype_f = factor(trialtype, levels = c("1","2","3","4","5","6","7","8"))) %>%
  mutate(trialtype_f = fct_recode(trialtype_f,
                                  "lan"= "1", "man" = "2", "han" = "3",
                                  "lap"= "4", "map" = "5", "hap" = "6",
                                  "neun" = "7", "neup" = "8")) %>%
  # add column for valence
  mutate(vale = case_when(grepl("n$", trialtype_f) ~ 'neg',
                          grepl("p$", trialtype_f) ~ 'pos')) %>%
  # add column for hemisphere
  mutate(hemi = case_when(grepl("l_", variable) ~ 'left',
                          grepl("r_", variable) ~ 'right'))

# convert to long form
mid.tc.long.sum = mid.tc %>%
  gather(variable, value, l_nacc8mm_raw.tc:r_caudate_raw.tc) %>%
  group_by(TR, trialtype, variable, hit, ethni_r, subject) %>%
  summarise(mean.subject = mean(value),
            se.subject = sd(value)/sqrt(length(value))) %>%
  summarise(mean = mean(mean.subject),
            se.mean = sd(mean.subject)/sqrt(length(unique(mid.tc$subject)))) %>%
  # convert ethnicity to factor and recode
  mutate(ethni_r = factor(ethni_r, levels = c("0","1"))) %>%
  mutate(ethni_r = fct_recode(ethni_r, "EA"= "0", "CH" = "1")) %>%
  # convert trialtype to factor and recode
  mutate(trialtype_f = factor(trialtype, levels = c("1","2","3","4","5","6","7","8"))) %>%
  mutate(trialtype_f = fct_recode(trialtype_f,
                                  "lan"= "1", "man" = "2", "han" = "3",
                                  "lap"= "4", "map" = "5", "hap" = "6",
                                  "neun" = "7", "neup" = "8")) %>%
  # add column for valence
  mutate(vale = case_when(grepl("n$", trialtype_f) ~ 'neg',
                          grepl("p$", trialtype_f) ~ 'pos')) %>%
  # add column for hemisphere
  mutate(hemi = case_when(grepl("l_", variable) ~ 'left',
                          grepl("r_", variable) ~ 'right'))

# convert to factors
mid.tc.long.sum.bin$vale = as.factor(mid.tc.long.sum.bin$vale)
mid.tc.long.sum.bin$variable = as.factor(mid.tc.long.sum.bin$variable)
mid.tc.long.sum.bin$variable = substr(mid.tc.long.sum.bin$variable, start = 3, stop = str_length(mid.tc.long.sum.bin$variable))

mid.tc.long.sum$vale = as.factor(mid.tc.long.sum$vale)
mid.tc.long.sum$variable = as.factor(mid.tc.long.sum$variable)
mid.tc.long.sum$variable = substr(mid.tc.long.sum$variable, start = 3, stop = str_length(mid.tc.long.sum$variable))
mid.tc.long.sum$hit = as.factor(mid.tc.long.sum$hit)
mid.tc.long.sum$hit = fct_recode(mid.tc.long.sum$hit,
                               "miss" = "0", "hit" = "1")

# Created inverse weighted variance dataframes

mid.tc.long.sum.bin.inv = mid.tc %>%
  gather(variable, value, l_nacc8mm_raw.tc:r_caudate_raw.tc) %>%
  group_by(TR, trialtype, variable, ethni_r, subject) %>%
  summarise(mean.subject = mean(value),
            var.subject = var(value)) %>%
  summarise(mean = wtd.mean(mean.subject, 1/var.subject),
            se.mean = sqrt(wtd.var(mean.subject, 1/var.subject))/sqrt(length(unique(mid.tc$subject)))) %>%
  # convert ethnicity to factor and recode
  mutate(ethni_r = factor(ethni_r, levels = c("0","1"))) %>%
  mutate(ethni_r = fct_recode(ethni_r, "EA"= "0", "CH" = "1")) %>%
  # convert trialtype to factor and recode
  mutate(trialtype_f = factor(trialtype, levels = c("1","2","3","4","5","6","7","8"))) %>%
  mutate(trialtype_f = fct_recode(trialtype_f,
                                  "lan"= "1", "man" = "2", "han" = "3",
                                  "lap"= "4", "map" = "5", "hap" = "6",
                                  "neun" = "7", "neup" = "8")) %>%
  # add column for valence
  mutate(vale = case_when(grepl("n$", trialtype_f) ~ 'neg',
                          grepl("p$", trialtype_f) ~ 'pos')) %>%
  # add column for hemisphere
  mutate(hemi = case_when(grepl("l_", variable) ~ 'left',
                          grepl("r_", variable) ~ 'right'))

mid.tc.long.sum.inv = mid.tc %>%
  gather(variable, value, l_nacc8mm_raw.tc:r_caudate_raw.tc) %>%
  group_by(TR, trialtype, variable, hit, ethni_r, subject) %>%
  summarise(mean.subject = mean(value),
            var.subject = var(value)) %>%
  summarise(mean = wtd.mean(mean.subject, 1/var.subject),
            se.mean = sqrt(wtd.var(mean.subject, 1/var.subject))/sqrt(length(unique(mid.tc$subject)))) %>%
  # convert ethnicity to factor and recode
  mutate(ethni_r = factor(ethni_r, levels = c("0","1"))) %>%
  mutate(ethni_r = fct_recode(ethni_r, "EA"= "0", "CH" = "1")) %>%
  # convert trialtype to factor and recode
  mutate(trialtype_f = factor(trialtype, levels = c("1","2","3","4","5","6","7","8"))) %>%
  mutate(trialtype_f = fct_recode(trialtype_f,
                                  "lan"= "1", "man" = "2", "han" = "3",
                                  "lap"= "4", "map" = "5", "hap" = "6",
                                  "neun" = "7", "neup" = "8")) %>%
  # add column for valence
  mutate(vale = case_when(grepl("n$", trialtype_f) ~ 'neg',
                          grepl("p$", trialtype_f) ~ 'pos')) %>%
  # add column for hemisphere
  mutate(hemi = case_when(grepl("l_", variable) ~ 'left',
                          grepl("r_", variable) ~ 'right'))

# convert to factors
mid.tc.long.sum.bin.inv$vale = as.factor(mid.tc.long.sum.bin.inv$vale)
mid.tc.long.sum.bin.inv$variable = as.factor(mid.tc.long.sum.bin.inv$variable)
mid.tc.long.sum.bin.inv$variable = substr(mid.tc.long.sum.bin.inv$variable, start = 3, stop = str_length(mid.tc.long.sum.bin.inv$variable))

mid.tc.long.sum.inv$vale = as.factor(mid.tc.long.sum.inv$vale)
mid.tc.long.sum.inv$variable = as.factor(mid.tc.long.sum.inv$variable)
mid.tc.long.sum.inv$variable = substr(mid.tc.long.sum.inv$variable, start = 3, stop = str_length(mid.tc.long.sum.inv$variable))
mid.tc.long.sum.inv$hit = as.factor(mid.tc.long.sum.inv$hit)
mid.tc.long.sum.inv$hit = fct_recode(mid.tc.long.sum.inv$hit,
                               "miss" = "0", "hit" = "1")

## Plotting Functions ###

plotTC = function(task, area, val, outcome, invW=FALSE){
  if(task == 'sid'){
    if(invW == TRUE){
        if(outcome == 'both'){
            p <- plotBin(sid.tc.long.sum.bin.inv, area, val)
          } else{
            p <- plotInd(sid.tc.long.sum.inv, area, val, outcome)
          }
      } else{
        if(outcome == 'both'){
            p <- plotBin(sid.tc.long.sum.bin, area, val)
          } else{
            p <- plotInd(sid.tc.long.sum, area, val, outcome)
          }
      }
    } else{
      if(invW == TRUE){
          if(outcome == 'both'){
              p <- plotBin(mid.tc.long.sum.bin.inv, area, val)
            } else{
              p <- plotInd(mid.tc.long.sum.inv, area, val, outcome)
            }
        } else{
          if(outcome == 'both'){
              p <- plotBin(mid.tc.long.sum.bin, area, val)
            } else{
              p <- plotInd(mid.tc.long.sum, area, val, outcome)
            }
    }
    }
  return(p)
}

savePlot = function(p, name, path){
  ggsave(name, p,
       path = path,
       width = 11, height = 7, units = 'in', useDingbats=FALSE)
  return()
}

plotBin = function(d, area, val){
  d1 = d %>%
    filter(variable == area & vale == val)
  d1$trialtype = factor(d1$trialtype)
  tcplot = ggplot(
    d1, aes(x = TR, y = mean, group = trialtype, shape = trialtype)) + 
    geom_errorbar(aes(ymin = mean-se.mean, ymax = mean+se.mean), width = 0.25) +
    geom_line(aes(linetype = trialtype, colour = trialtype), size = 1) +
    geom_point(aes(shape = trialtype, colour = trialtype, fill = trialtype), size = 3.5, shape = 21) +
    scale_fill_manual(values = c("#91bfdb","#ff9326","#e41a1c","#bdbdbd")) +
    scale_color_manual(values = c("#91bfdb","#ff9326","#e41a1c","#bdbdbd")) +
    scale_x_continuous(breaks = seq(0,8, by = 1), labels = seq(0,16, by = 2)) +
    facet_grid(ethni_r ~ hemi) +
    theme(text = element_text(size = 16),
          axis.text=element_text(size = 16),
          legend.title = element_blank(),
          panel.grid.minor = element_blank(),
          panel.grid.major = element_blank(),
          panel.background = element_blank()) +
    xlab('Seconds') +
    ylab('Percent Signal Change')
  return(tcplot)
}

plotInd = function(d, area, val, outcome){
  d1 = d %>%
    filter(variable == area & hit == outcome & vale == val)
  tcplot = ggplot(
    d1, aes(x = TR, y = mean, group = trialtype, shape = trialtype)) + 
    geom_errorbar(aes(ymin = mean-se.mean, ymax = mean+se.mean), width = 0.25) +
    geom_line(aes(linetype = trialtype, colour = trialtype), size = 1) +
    geom_point(aes(shape = trialtype, colour = trialtype, fill = trialtype), size = 3.5, shape = 21) +
    scale_fill_manual(values = c("#91bfdb","#ff9326","#e41a1c","#bdbdbd")) +
    scale_color_manual(values = c("#91bfdb","#ff9326","#e41a1c","#bdbdbd")) +
    scale_x_continuous(breaks = seq(0,8, by = 1), labels = seq(0,16, by = 2)) +
    facet_grid(ethni_r ~ hemi) +
    theme(text = element_text(size = 16),
          axis.text=element_text(size = 16),
          legend.title = element_blank(),
          panel.grid.minor = element_blank(),
          panel.grid.major = element_blank(),
          panel.background = element_blank()) +
    xlab('Seconds') +
    ylab('Percent Signal Change')
  return(tcplot)
}

plotHVM = function(d, area, val){
  d1 <- d %>%
    filter(variable==area & vale==val)
  tcplot = 
    ggplot(d1, aes(x = TR, y = mean, shape = hit, color = trialtype)) +
    geom_errorbar(aes(ymin = mean-se.mean, ymax = mean+se.mean), width = 0.25) +
    geom_point(aes(group = interaction(trialtype, hit)), size = 3.5) +
    geom_line(aes(color = trialtype, linetype = hit), size = 1) +
    scale_linetype_manual(values=c("dashed", "solid")) +  
    scale_shape_manual(values = c(1, 16)) +
    scale_fill_manual(values = c("#91bfdb","#ff9326","#e41a1c","#bdbdbd")) +
    scale_color_manual(values = c("#91bfdb","#ff9326","#e41a1c","#bdbdbd")) +
    scale_x_continuous(breaks = seq(0,8, by = 1), labels = seq(0,16, by = 2)) +
    facet_grid(ethni_r ~ hemi) +
    theme(text = element_text(size = 16),
          axis.text=element_text(size = 16),
          legend.title = element_blank(),
          panel.grid.minor = element_blank(),
          panel.grid.major = element_blank(),
          panel.background = element_blank()) +
    xlab('Seconds') +
    ylab('Percent Signal Change')
  return(tcplot)
}

####### Plot Bar ########
#########################

plotBar = function(task, area, side, val, outcome, TR){
    if(task=="sid"){
        df = sid.tc.long.sum
    } else{
        if(task=="mid"){
            df = mid.tc.long.sum
        }
    }
    df = df %>%
        filter(variable == area & vale == val & TR == TR)
    # select area
    if(side=="both"){
        df = df %>% 
            group_by(ethni_r, trialtype_f, hit) %>%
            summarise(mean = mean(mean))
    } else{
        df = df %>%
            filter(hemi==side)
    }
    # select outcome
    if(outcome=="area"){
        df = df %>%
            group_by(ethni_r, trialtype_f) %>%
            summarise(mean = mean(mean))
    } else{
        df = df %>%
            filter(hit==outcome)
    }
    return(df)
}

####### Plot Data #######
#########################
# all areas have pos vs neg, bin vs hit vs miss vs (hit v miss) #
# areas: nacc8mm_raw.tc, ins_raw.tc, caudate_raw.tc, dlpfc_raw.tc, vlpfc_raw.tc, mpfc_raw.tc

# nacc.gain.tcplot
# nacc.gain.tcplot.hit
# nacc.gain.tcplot.hvm
# nacc.gain.tcplot
# nacc.loss.tcplot
#p1 <- plotBin(sid.tc.long.sum.bin, 'nacc8mm_raw.tc', 'pos')
#p2 <- plotInd(sid.tc.long.sum, 'nacc8mm_raw.tc', 'pos', 'hit')

# savePlot(p1, 'test.pdf', '../output/figures/')
