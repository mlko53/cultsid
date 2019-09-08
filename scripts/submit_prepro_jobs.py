import subprocess

SUBJECTS = ['ac081918','ac082219','al052019','ao082819','az072519'
            'ch102218','dj051418','dv111518','dy051818','fd111018'
            'gl052518','hc101818','he042718','hw111117','is060118'
            'jd051818','jd072919','jk102518','jl053119','js082219'
            'js101518','kl112918','kt082818','lh102418','lp102118'
            'mc111218','mh071418','mp083018','mp110618','nb102318'
            'pw073019','qh111717','rt022718','sh101518','sm110518'
            'sw050818','sw110818','tl111017','wh071918','wx060119'
            'xl042618','xz071218','yd072319','yd081018','yg042518'
            'yl070418','yl070518','yl073119','yl080118','yp070418'
            'yq052218','yw070618','yw081018','yx072518','yy072919']

SUBJECTS = ['test']

if __name__ == "__main__":

    for sub in SUBJECTS:
        with open("template.sh", "r") as f:
            lines = f.readlines()
        with open("sbatch_preprocess.sh", "w") as f:
            lines = [line.replace("template", sub) for line in lines]
            f.writelines(lines)
        subprocess.check_call(["sbatch", "sbatch_preprocess.sh"])
