#!/usr/bin/env python

import string
import os
import glob, re
import sys

#only MK added cuz Windows
import matplotlib
matplotlib.use('Agg')

import matplotlib.pyplot as plt
import numpy

import argparse


##############################################################################
###                                                                        ###
### 3dmotion graphing and analysis:                                        ###
###                                                                        ###
##############################################################################

################# 3dmotion graph/log specific variables ######################
##
# This is the output name of the 3dmotion file. If not set, it will be
# determined by the values used in the process script generator
MotionOutputFilename = ''

# This is the lag for how many TRs to span for movement checking. The
# default value is 3 (thats what Stephanie used)
Lag = 3

# These are currently unused variables. They regard future functionality of
# the 3dmotion grapher to use regressors and high pass filters
Regressor = []
HPFon = 0

# This determines if the graphs will be drawn. If you set it to zero, a graph
# will not be generated for the subjects
Show = 1

# The labels you want to assign as the movement axes
Labels = ['roll [1]', 'pitch [2]', 'yaw [3]', 'z [4]', 'x [5]', 'y [6]']


########     Calculate the maximum absolute value item in a list       #######
##
## Just a basic little function that iterates through a list, takes the
## absolute value of each item, and calculates the maximum item in the
## list.
##
def PositionAbsMax(sequence):
    max = 0
    ind = 0
    for i in range(len(sequence)):
        if abs(sequence[i]) > max:
            max = abs(sequence[i])
            ind = i
    return [max,ind]


################          Load and parse a 1D file        ####################
##
## Takes a 1D file and the number of columns to pick out of it, then parses
## the 1D file and returns the relevant columns as a list. Used by
## CreateMotionGraph()
##
def Load1D(filename, cols):
    ## Modeled after load1D.m by Stephanie Greer, 6/13/07
    ## if cols != 1, assume delimiter is a space (intended use) (can change below)
    delimiter = ' '
    output = []
    if not filename.endswith('.1D'):
        print('\n\nError: non- .1D file passed into function Load1D\n\n')
    else:
        file = open(filename, 'r')
        lines = file.readlines()
        for line in lines:
            line = line.strip('\t\n')
            #print line
            if cols == 1:
                output.append(float(line))
            else:
                line = line.split(delimiter)
                parsedline = []
                for item in line:
                    if item:
                        parsedline.append(item)
                #print parsedline
                subout = []
                for i in range(cols):
                    subout.append(float(parsedline[i]))
                output.append(subout)
        file.close()
    return output

#############        Generate motion graph for subject         ###############
##
## This is a stripped down version of Stephanie's inspectMotion graph
## generator that ran in matlab. It allows the graphs to be created directly
## from python using the matplotlib module.
##

def CreateMotionGraph(subject,motionout):
    # initialize some variables
    subjectLogStrs = []
    output = [subject]
    afR = []
    afP = []
    reg = []
    length = 0

    # parse the 3dmotionfile
    print (motionout)
    parse = Load1D(motionout, 9)

    # reparse the motion file
    reparse = []
    for line in parse:
        line.pop(0)
        reparse.append(line)
    if Regressor:
        if isinstance(Regressor, str):
            reg = Load1D(Regressor)
            end = len(reg)-1
            reg.pop(end)
        else:
            reg = Regressor
        for i in range(len(reg)):
            reg[i] = reg[i] / max(reg)
        length = min([len(reg), len(reparse)])
    else:
        length = len(reparse)

    # currently unused variable
    titleS = ''

    # Set up the figure, adjust subplot parameters, add title
    if Show:
        fig = plt.figure(1, figsize=(14,12),facecolor='0.95')
        fig.subplots_adjust(wspace=0.4,hspace=0.4)
        fig.suptitle('3dmotion Graph for Subject: '+subject,fontsize=16)

    # iterate through each subplot and draw
    for i in range(6):
        # this is used, generate list of values to graph
        specific = []
        for line in reparse[0:length]:
            specific.append(line[i])
        if Show:
            plt.subplot(3,2,i+1)

        # mostly unused HPF and regression stuff:
        if reg:
            maxCur = 0
            if HPFon:
                #NO support yet for High Pass Filter mode
                #Do not set HPFon to 1 or True
                print('No support (yet) for high pass filter mode.')
            else:
                #specific = []
                #for line in reparse[0:length]:
                #    specific.append(line[i])
                [afR[i],afP[i]] = numpy.correlate(reg[0:length],specific)
                if Show:
                    plt.plot(specific,Colors[1])
                maxCur = max(abs(specific))
            regCur = []
            for x in range(len(reg)):
                regCur[x] = maxCur*reg[x]
            if Show:
                plt.plot(regCur[0:length],Colors[1])
                #Haven't added title support in here yet...
                titleS = ' None yet'
        else:
            # this is what gets used to plot each subplot
            plt.plot(specific,color='b',linewidth=0.7)

        # find the biggest jumps
        cur = []
        maxJumpV = []
        maxJumpI = []
        for line in reparse:
            cur.append(line[i])
        for j in range(1,Lag+1):
            jumps = []
            for k in range(len(cur)):
                if k < len(cur)-j: begin = cur[k]
                if k+j < len(cur): end = cur[k+j]
                if begin and end:
                    jumps.append(begin-end)
            maxVI = PositionAbsMax(jumps)
            maxJumpV.append(maxVI[0])
            maxJumpI.append(maxVI[1])

            # This part is pretty hacked together:
            # Something is up with index plotting in matplotlib, so the index
            # values are "hacked" up to get the right plotting image.
            # Don't worry though, the value reported for max movement is correct.
            index = maxJumpI[j-1] +1
            if index+j < len(cur):
                plotx = [index]
                ploty = [cur[index]]
                for iter in range(j+1):
                    plotx.append(index+iter+1)
                    ploty.append(cur[index+iter+1])
                if Show: plt.plot(plotx, ploty, color=[0,1,0],linewidth=2.5)
            else:
                plotx = [index,len(cur)]
                ploty = [cur[index],cur[len(cur)]]
                if Show: plt.plot(plotx, ploty, color=[0,1,0],linewidth=2.5)

            bigJumpsI = []
            bigJumpsV = []
            for m in range(len(jumps)):
                if abs(jumps[m]) > 0.5:
                    bigJumpsI.append(m)
                    bigJumpsV.append(jumps[m])
            if bigJumpsI:
                for b in range(len(bigJumpsI)):
                    bInd = bigJumpsI[b]
                    if abs(bigJumpsV[b]) > 1:
                        col = [1,0,0]
                    else:
                        col = [1,0.5,0]
                    if bInd+1 < len(cur):
                        if Show: plt.plot(range(bInd,bInd+1), cur[bInd:bInd+1], color=col)
                    else:
                        if Show: plt.plot(range(bInd,len(cur)), cur[bInd:len(cur)], color=col)

        # draw the stuff onto the figure, and pass out subject information
        # to be used when the .csv master log is created
        if Show:
            [maxAll, indMax] = PositionAbsMax(maxJumpV)
            if maxAll < 0.5:
                plt.text(maxJumpI[indMax]+10, cur[maxJumpI[indMax]],'{0:.2f} mm'.format(maxAll),fontsize=12,backgroundcolor=[1,1,1])
                subjectLogStrs.append(Labels[i]+': ns ({0:.2f})\n'.format(maxAll))
                output.append([i,maxAll,0])
            elif maxAll < 1.0:
                plt.text(maxJumpI[indMax]+10, cur[maxJumpI[indMax]]+0.2,'{0:.2f} mm'.format(maxAll),fontsize=12,backgroundcolor=[1,0.5,0])
                subjectLogStrs.append(Labels[i]+': Jump above 0.5mm but not 1mm ({0:.2f})\n'.format(maxAll))
                output.append([i,maxAll,1])
            else:
                plt.text(maxJumpI[indMax]+10, cur[maxJumpI[indMax]]+0.7,'{0:.2f} mm'.format(maxAll),fontsize=12,backgroundcolor=[1,0,0])
                subjectLogStrs.append(Labels[i]+': Jump above 1mm ({0:.2f})\n'.format(maxAll))
                output.append([i,maxAll,2])

            plt.title(Labels[i]+' '+titleS)
            plt.ylabel('mm')
            plt.xlabel('TR')

    # save the figure, then clear it to be safe (because I don't know how
    # matplotlib handles batch graphing)
    plt.savefig('3dmotion_sid_fig.png',format='png',dpi=300)
    fig.clear()
    LogSubject(subject,subjectLogStrs)
    return output

#############      Generate individual 3dmotion log      #####################
##
## For each subject, this will create a nice little log with all the 3dmotion
## info printed out for each motion axis. It's like a non-graphical version
## of the motion graph.
##
def LogSubject(subj,strs):
    log = open(subj+'_motion_sid_log.txt','w')
    log.write('3dmotion Log for Subject: '+subj+'\n\n')
    for str in strs:
        log.write(str)
    log.close()
    

def dirs(topdir=os.getcwd(), prefixes=[], exclude=[], regexp=None, initial_glob='*'):
    
    files = [f for f in glob.glob(os.path.join(topdir,initial_glob)) if os.path.isdir(f)]
    if regexp:
        files = [f for f in files if re.search(regexp, os.path.split(f)[1])]
    files = [f for f in files if not any([os.path.split(f)[1].startswith(ex) for ex in exclude])]
    if prefixes:
        files = [f for f in files if any([os.path.split(f)[1].startswith(pr) for pr in prefixes])]
        
    return sorted(files)


def subject_dirs(topdir=os.getcwd(), prefixes=[], exclude=[]):
    return dirs(topdir=topdir, prefixes=prefixes, exclude=exclude,
                regexp=r'[a-zA-Z]\d\d\d\d\d\d')
    
    
    
if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument("--subject", type=str)
    args = parser.parse_args()
    subjects = [args.subject]

    motionfiles = ['3dmotionsid.1D', '3dmotionmid.1D']
    os.chdir('../data/fmri')
    datadir = os.getcwd()
    #subjdirs = subject_dirs(topdir=topdir)
    
    subjdirs = [os.path.join(datadir,x) for x in subjects]
    for subject in subjdirs:
        subname = os.path.split(subject)[1]
        print(subject)
        os.chdir(subject)
        for motionfile in motionfiles:
        	CreateMotionGraph(subname,motionfile)
        os.chdir('..')

    print("Completed motion graph")
