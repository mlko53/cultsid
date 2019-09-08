import glob
import os
import shutil


if __name__ == "__main__":

    cwd = os.getcwd()
    folders = [x for x in os.listdir(cwd) if os.path.isdir(x)]
    for folder in folders:
        pngs = glob.glob(os.path.join(cwd, folder)+"/*.png")
        for png in pngs:
            dest = png.replace("/3dmotion","")
            dest = dest.replace("_fig","")
            shutil.copyfile(png, dest)
