#!/usr/bin/env python3
from ase import io
import glob, os

files = glob.glob('**/vasprun.xml', recursive=True)
files.sort()

with open('traj.xyz', 'w') as out:
    for f in files:
        print("Adding {}: ".format(f), end='')
        frames = io.read(f, index=slice(0,None))
        print("{} frames...".format(len(frames)))
        io.write(out, frames, format='extxyz', append=True)
print('...Done!')
