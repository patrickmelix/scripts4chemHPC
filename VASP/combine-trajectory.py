#!/usr/bin/env python3
from ase import io
from natsort import natsorted
import glob, os

files = natsorted(glob.glob('**/vasprun.xml', recursive=True))

with open('traj.xyz', 'w') as out:
    for f in files:
        print("Adding {}: ".format(f), end='')
        frames = io.read(f, index=slice(0,None))
        print("{} frames...".format(len(frames)))
        io.write(out, frames, format='extxyz', append=True)
print('...Done!')
