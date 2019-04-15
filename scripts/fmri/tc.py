import glob
import os
import subprocess
import shutil
import numpy as np

all_subjects = ['dj051418', 'dy051818', 'gl052818', 'he042718', 'hw111117', 
                'is060118', 'jd051818', 'mh071418', 'qh111717', 'rt022718', 
                'sw050818', 'tl111017', 'wh071918', 'xl042618', 'xz071218', 
                'yd081018', 'yg042518', 'yl070418', 'yl070518', 'yl080118', 
                'yp070418', 'yq052218', 'yw070618', 'yw081018', 'yx072518']


vector_file = ['sid_runs.1D', 'mid_runs.1D']
masks = ['nacc8mm','mpfc','acing','caudate','ins','dlpfc','vlpfc','nacc_desai_mpm','antins_desai_mpm']

dataset_name = ['sid_mbnf+orig', 'mid_mbnf+orig']
anat_name = 'anat+tlrc'
tmp_tc_dir = ['sid_tcs/', 'mid_tcs']

"""
# for ever subject
## make_vectors
## maskdump
### fractionize
### mask_average
## average_activation
### create timecourse csvs
#### generate_raw_avg_csv
# (generate_trial_avg never used)

maskdump output - 
- area+orig.BRIK
- sid_tcs
"""

def make_vectors(subjdir, scriptsdir, vector_file, subject):
    # make the absolute path of the vector file:
    vector_path = os.path.join(scriptsdir, vector_file)
    makeVec = os.path.join(scriptsdir, 'makeVec.py')
    
    # call makeVec on one subject
    os.chdir(subjdir)
    subprocess.call([makeVec, vector_path, subject])
    print 'Completed make_vectors'



def fractionize_mask(mask, dataset_name, anat_name, maskdir):
    # function assumes to be located within subject directory
    
    # PRINT OUT:
    print 'fractionizing', mask
    
    # define scriptsdir mask location
    scripts_mask = os.path.join(maskdir, mask+'+tlrc.')
    
    # attempt to remove old fractionized mask files:
    try:
        os.remove(mask+'r+orig.HEAD')
        os.remove(mask+'r+orig.BRIK')
    except:
        pass
    
    # fractionize the mask to the functional dataset
    cmd = ['3dfractionize', '-template', dataset_name, '-input', scripts_mask,
           '-warp', anat_name, '-clip', '0.1', '-preserve', '-prefix',
           mask+'r+orig']
    subprocess.call(cmd)
 

def mask_average(subject, mask, dataset_name, tmp_tc_dir):
    # function assumes within subject folder
    
    # PRINT OUT:
    print 'maskave', subject, mask
    
    # define left, right, both:
    areas = ['l','r','b']
    area_codes = [[1,1],[2,2],[1,2]]
    
    '''
    tcfiles = glob.glob(os.path.join(tmp_tc_dir, '*.tc'))
    removed_count = 0
    for tcf in tcfiles:
        try:
            os.remove(tcf)
            removed_count += 1
        except:
            print 'could not remove:', tcf
            
    print 'tcfiles removed:', removed_count
    '''
    
    # iterate areas, complete mask ave:
    for area, codes in zip(areas, area_codes):
        # define the name of the raw tc file:
        raw_tc = '_'.join([subject, area, mask, 'raw.tc'])
        
        # attempt to remove the file if it already exists here or in the
        # temporary directory:
        try:
            os.remove(raw_tc)
        except:
            pass
        try:
            os.remove(os.path.join(tmp_tc_dir, raw_tc))
        except:
            pass
        
        cmd = ['3dmaskave', '-mask', mask+'r+orig', '-quiet', '-mrange',
               str(codes[0]), str(codes[1]), dataset_name]#, '>', raw_tc]
        #subprocess.call(cmd)
        
        fcontent = subprocess.Popen(cmd, stdout=subprocess.PIPE)
        fcontent.wait()
        fcontent = fcontent.communicate()[0]
        
        fid = open(raw_tc,'w')
        fid.write(fcontent)
        fid.close()
        
        
        # move the raw tc file to the tmp tc directory:
        shutil.move(raw_tc, tmp_tc_dir)
        
        
def maskdump(topdir, subjdir, subject, dataset_name, anat_name, masks,
             scriptsdir, tmp_tc_dir, maskdir):
    
    # PRINT OUT:
    print 'mask dump ', subject
    
    # maskdump for only 1 subject
    os.chdir(subjdir)

    # create the directory for raw tc files, if necessary:
    if not os.path.exists(tmp_tc_dir):
        os.mkdir(tmp_tc_dir)
		
    tcs = glob.glob(os.path.join(tmp_tc_dir,'*.tc'))
    for tcf in tcs:
        try:
            os.remove(tcf)
        except:
            pass
	
    
    # iterate over masks:
    for mask in masks:
        # fractionize the masks
        fractionize_mask(mask, dataset_name, anat_name, maskdir)
        
        # create the raw timecourses:
        mask_average(subject, mask, dataset_name, tmp_tc_dir)
    
    # return to the topdir (just in case):
    os.chdir(topdir)

def find_subject_dirs(topdir, subject):
    # returns folder of 1 subject

    dir = glob.glob(os.path.join(topdir,subject)+'*')[0]
    if dir:
        subjdir = dir
    return subjdir



if __name__ == '__main__':

    for i, epi in enumerate(['sid_tcs', 'mid_tcs']):
        
        for subject in all_subjects:

                scriptsdir = os.getcwd()
                topdir = os.path.split(os.getcwd())[0] 
                maskdir = topdir + '/masks'
                topdir += '/data/fmri'

                subjectdir = find_subject_dirs(topdir, subject)
                print "Looking into:    " + subjectdir
            
                if vector_file[i]:
                    make_vectors(subjectdir, scriptsdir, vector_file[i], subject)
            
                os.chdir(scriptsdir)
            
                maskdump(topdir, subjectdir, subject, dataset_name[i], anat_name, masks,
                     scriptsdir, tmp_tc_dir[i], maskdir)
            
                os.chdir(scriptsdir)
