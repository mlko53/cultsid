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
exclude = c('dj051418', 'dy051818', 'sh101518', 'wh071918', 'hc101818')
borderline_exclude = c('jk102518','tl111017', 'hw111117')

sid.tc = read.csv('../output/sid_tcs/sid_timecourse.csv', head=T)

# exclude participants for motion
sid.tc = sid.tc %>%
  filter(!(subject %in% exclude))

sid.tc$subject = droplevels(sid.tc$subject)

# reoder columns and drop unnecessary variables
sid.tc <- sid.tc[c('trial','TR','trialtype','subject','ethni_r','hit',
                       'l_nacc8mm_raw.tc','r_nacc8mm_raw.tc', 'b_nacc8mm_raw.tc',
                       'l_nacc_desai_mpm_raw.tc','r_nacc_desai_mpm_raw.tc', 'b_nacc_desai_mpm_raw.tc',
                       'l_ins_raw.tc','r_ins_raw.tc', 'b_ins_raw.tc',
                       'l_antins_desai_mpm_raw.tc','r_antins_desai_mpm_raw.tc', 'b_antins_desai_mpm_raw.tc',
                       'l_mpfc_raw.tc','r_mpfc_raw.tc', 'b_mpfc_raw.tc',
                       'l_dlpfc_raw.tc','r_dlpfc_raw.tc', 'b_dlpfc_raw.tc',
                       'l_acing_raw.tc','r_acing_raw.tc', 'b_acing_raw.tc',
                       'l_vlpfc_raw.tc','r_vlpfc_raw.tc', 'b_vlpfc_raw.tc',
                       'l_caudate_raw.tc','r_caudate_raw.tc', 'b_caudate_raw.tc')]

# format data columns
sid.tc.long = sid.tc %>%
  # convert ethnicity to factor and recode 
  mutate(ethni_r = factor(ethni_r, levels = c("0","1"))) %>%
  mutate(ethni_r = fct_recode(ethni_r, "EA"= "0", "CH" = "1")) %>%
  # convert trialtype to factor and recode
  mutate(trialtype = factor(trialtype, levels = c("1","2","3","4","5","6","7","8"))) %>%
  mutate(trialtype = fct_recode(trialtype,
                                  "lan"= "1", "man" = "2", "han" = "3",
                                  "lap"= "4", "map" = "5", "hap" = "6",
                                  "neun" = "7", "neup" = "8")) %>%
  gather(variable, value, l_nacc8mm_raw.tc:b_caudate_raw.tc) %>%
  # add column for valence
  mutate(vale = case_when(grepl("n$", trialtype) ~ 'neg',
                          grepl("p$", trialtype) ~ 'pos')) %>%
  # add column for hemisphere
  mutate(hemi = case_when(grepl("l_", variable) ~ 'left',
                          grepl("r_", variable) ~ 'right',
  						  grepl("b_", variable) ~ 'both'))

# convert to factors
sid.tc.long$hit = as.factor(sid.tc.long$hit)
sid.tc.long$hit = fct_recode(sid.tc.long$hit, "miss" = "0", "hit" = "1")
sid.tc.long$vale = as.factor(sid.tc.long$vale)
sid.tc.long$variable = as.factor(sid.tc.long$variable)
sid.tc.long$variable = substr(sid.tc.long$variable, start = 3, stop = 999)

####### Tidy Data #######
#########################

# convert to long form
sid.tc.long.sum.bin = sid.tc.long %>%
  group_by(TR, trialtype, vale, variable, hemi, ethni_r, subject) %>%
  summarise(mean.subject = mean(value),
            se.subject = sd(value)/sqrt(length(value)),
            var.subject = var(value)) %>%
  summarise(mean = mean(mean.subject),
            se.mean = sd(mean.subject)/sqrt(length(unique(sid.tc$subject))),
            se.inv.mean = sqrt(wtd.var(mean.subject, 1/var.subject))/sqrt(length(unique(sid.tc$subject))))

sid.tc.long.sum = sid.tc.long %>%
  group_by(TR, trialtype, vale, variable, hemi, hit, ethni_r, subject) %>%
  summarise(mean.subject = mean(value),
            se.subject = sd(value)/sqrt(length(value)),
            var.subject = var(value)) %>%
  summarise(mean = mean(mean.subject),
            se.mean = sd(mean.subject)/sqrt(length(unique(sid.tc$subject))),
            se.inv.mean = sqrt(wtd.var(mean.subject, 1/var.subject))/sqrt(length(unique(sid.tc$subject))))

## Read and Precompute MID csv

mid.tc = read.csv('../output/mid_tcs/mid_timecourse.csv', head=T)

# exclude participants for motion
mid.tc = mid.tc %>%
  filter(!(subject %in% exclude))

mid.tc$subject = droplevels(mid.tc$subject)

# reoder columns and drop unnecessary variables
mid.tc <- mid.tc[c('trial','TR','trialtype','subject','ethni_r','hit',
                       'l_nacc8mm_raw.tc','r_nacc8mm_raw.tc', 'b_nacc8mm_raw.tc',
                       'l_nacc_desai_mpm_raw.tc','r_nacc_desai_mpm_raw.tc', 'b_nacc_desai_mpm_raw.tc',
                       'l_ins_raw.tc','r_ins_raw.tc', 'b_ins_raw.tc',
                       'l_antins_desai_mpm_raw.tc','r_antins_desai_mpm_raw.tc', 'b_antins_desai_mpm_raw.tc',
                       'l_mpfc_raw.tc','r_mpfc_raw.tc', 'b_mpfc_raw.tc',
                       'l_dlpfc_raw.tc','r_dlpfc_raw.tc', 'b_dlpfc_raw.tc',
                       'l_acing_raw.tc','r_acing_raw.tc', 'b_acing_raw.tc',
                       'l_vlpfc_raw.tc','r_vlpfc_raw.tc', 'b_vlpfc_raw.tc',
                       'l_caudate_raw.tc','r_caudate_raw.tc', 'b_caudate_raw.tc')]

# format data columns
mid.tc.long = mid.tc %>%
  # convert ethnicity to factor and recode 
  mutate(ethni_r = factor(ethni_r, levels = c("0","1"))) %>%
  mutate(ethni_r = fct_recode(ethni_r, "EA"= "0", "CH" = "1")) %>%
  # convert trialtype to factor and recode
  mutate(trialtype = factor(trialtype, levels = c("1","2","3","4","5","6","7","8"))) %>%
  mutate(trialtype = fct_recode(trialtype,
                                  "lan"= "1", "man" = "2", "han" = "3",
                                  "lap"= "4", "map" = "5", "hap" = "6",
                                  "neun" = "7", "neup" = "8")) %>%
  gather(variable, value, l_nacc8mm_raw.tc:b_caudate_raw.tc) %>%
  # add column for valence
  mutate(vale = case_when(grepl("n$", trialtype) ~ 'neg',
                          grepl("p$", trialtype) ~ 'pos')) %>%
  # add column for hemisphere
  mutate(hemi = case_when(grepl("l_", variable) ~ 'left',
                          grepl("r_", variable) ~ 'right',
  						  grepl("b_", variable) ~ 'both'))

# convert to factors
mid.tc.long$hit = as.factor(mid.tc.long$hit)
mid.tc.long$hit = fct_recode(mid.tc.long$hit, "miss" = "0", "hit" = "1")
mid.tc.long$vale = as.factor(mid.tc.long$vale)
mid.tc.long$variable = as.factor(mid.tc.long$variable)
mid.tc.long$variable = substr(mid.tc.long$variable, start = 3, stop = 999)

####### Tidy Data #######
#########################

# convert to long form
mid.tc.long.sum.bin = mid.tc.long %>%
  group_by(TR, trialtype, vale, variable, hemi, ethni_r, subject) %>%
  summarise(mean.subject = mean(value),
            se.subject = sd(value)/sqrt(length(value)),
            var.subject = var(value)) %>%
  summarise(mean = mean(mean.subject),
            se.mean = sd(mean.subject)/sqrt(length(unique(mid.tc$subject))),
            se.inv.mean = sqrt(wtd.var(mean.subject, 1/var.subject))/sqrt(length(unique(mid.tc$subject))))

mid.tc.long.sum = mid.tc.long %>%
  group_by(TR, trialtype, vale, variable, hemi, hit, ethni_r, subject) %>%
  summarise(mean.subject = mean(value),
            se.subject = sd(value)/sqrt(length(value)),
            var.subject = var(value)) %>%
  summarise(mean = mean(mean.subject),
            se.mean = sd(mean.subject)/sqrt(length(unique(mid.tc$subject))),
            se.inv.mean = sqrt(wtd.var(mean.subject, 1/var.subject))/sqrt(length(unique(mid.tc$subject))))

## Plotting Functions ###

plotTC = function(task, area, val, outcome, invW=FALSE){
  if(task == 'sid'){
      if(outcome == 'both'){
          p <- plotBin(sid.tc.long.sum.bin, area, val, invW)
        } else{
          p <- plotInd(sid.tc.long.sum, area, val, outcome, invW)
      }
  } else{
        if(outcome == 'both'){
            p <- plotBin(mid.tc.long.sum.bin, area, val, invW)
          } else{
            p <- plotInd(mid.tc.long.sum, area, val, outcome, invW)
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

plotBin = function(d, area, val, invW){
  d1 = d %>%
    filter(variable == area & vale == val)
  if(invW == TRUE){
    d1 = d1 %>% mutate(se = se.inv.mean)
  } else{
    d1 = d1 %>% mutate(se = se.mean)
  }
  tcplot = ggplot(
    d1, aes(x = TR, y = mean, group = trialtype, shape = trialtype)) + 
    geom_errorbar(aes(ymin = mean-se, ymax = mean+se), width = 0.25) +
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

plotInd = function(d, area, val, outcome, invW){
  d1 = d %>%
    filter(variable == area & hit == outcome & vale == val)
  if(invW == TRUE){
    d1 = d1 %>% mutate(se = se.inv.mean)
  } else{
    d1 = d1 %>% mutate(se = se.mean)
  }
  tcplot = ggplot(
    d1, aes(x = TR, y = mean, group = trialtype, shape = trialtype)) + 
    geom_errorbar(aes(ymin = mean-se, ymax = mean+se), width = 0.25) +
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

plotBar = function(task, area, val, outcome, TR){
    if(task=="sid"){
        df = sid.tc.long
    } else{
        if(task=="mid"){
            df = mid.tc.long
        }
    }
    df = df %>%
        filter(variable == area & vale == val & TR == TR)
    if(outcome!="both"){
    	df = df %>%
    		filter(hit==outcome)
    }
    df = df %>% 
    	group_by(ethni_r, trialtype, hemi) %>% 
    	summarise(se.value=se(value), value=mean(value))
    p = ggplot(df, aes(trialtype, value, fill=ethni_r)) + 
    	geom_bar(stat='identity', position='dodge') + 
    	geom_errorbar(aes(ymin=value-se.value, ymax=value+se.value), position=position_dodge(.9), width=.2) +
    	facet_grid(.~hemi)

    return(p)
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
