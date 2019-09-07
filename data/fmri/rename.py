import os
import glob
import shutil


def return_sessions(path):
    sessions = glob.glob(path+"/*")
    return sessions


def process_subject_dir(path):
    sub = path.split("/")[-1]
    if sub in ["ce090918", "jk082819"]:
        print("{} has no T1 data".format(sub))
        return
    print("Processing {}".format(sub))
    extract_scans(path)
    rename_scans(path)
    return


def extract_scans(path):
    """hard-coded multiple sessions subject"""
    sub = path.split("/")[-1]
    if sub == "jl053119":
        source = path+"/20543"
    else:
        source = glob.glob(path+"/*")
        assert len(source) == 1
        source = source[0]
    destination = path
    for filename in os.listdir(source):
        shutil.move(os.path.join(source, filename), os.path.join(destination, filename))
    os.rmdir(source)
    return


def rename_scans(path):
    folders = glob.glob(path+"/*")
    old_system = "_" in folders[0].split("/")[-1]

    # rename T1
    t1_folder = [x for x in folders if "T1" in x][0]
    dest = path+"/T1"    
    os.rename(t1_folder, dest)

    # rename functionals
    epi_folders= [x for x in folders if "EPI" in x]
    epi_folders.sort()

    # rename SID
    dest = path+"/EPI0"
    os.rename(epi_folders[0], dest)

    # rename MID
    dest = path+"/EPI1"
    os.rename(epi_folders[1], dest)
    
    return


if __name__ == "__main__":

    cwd = os.getcwd()

    sub_folders = [path for path in glob.glob(cwd+"/*") if os.path.isdir(path)]

    print("Processin {} subjects".format(len(sub_folders)))
    print("Subjects that have more than 1 session")
    for sub_folder in sub_folders:
        sessions = glob.glob(sub_folder+"/*")
        if len(sessions) != 1:
            print(sessions)

    for sub_folder in sub_folders:
        process_subject_dir(sub_folder)
