fw download "knutson/cultsid" -i nifti -i bvec -i bval
tar -tvf cultsid.tar
rm cultsid.tar
mv scitran/knutson/cultsid/* .
rm -rf scitran
csh rename.sh