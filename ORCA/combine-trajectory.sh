#!/usr/bin/env python3
from ase import io
from natsort import natsorted
import glob, os

files = natsorted(glob.glob('**/*_trj.xyz', recursive=True))

#if first entry is not in a subdir, it should be the last
if not '/' in files[0]:
   tmp = files[0]
   del files[0]
   files.append(tmp)

with open('traj.xyz', 'w') as out:
    for f in files:
        print("Adding {}: ".format(f), end='')
        frames = io.read(f, index=slice(0,None))
        print("{} frames...".format(len(frames)))
        io.write(out, frames, format='extxyz', append=True)
print('...Done!')
