#!/usr/bin/env python3
from ase import io
from natsort import natsorted
import glob, os

files = natsorted(glob.glob('*/vasprun.xml', recursive=True))
if os.path.isfile('./vasprun.xml'):
    files.append('./vasprun.xml')

with open('traj.xyz', 'w') as out:
    for f in files:
        folder = os.path.dirname(os.path.abspath(f))
        if (not os.path.basename(folder).isdigit()) and (not os.path.realpath(folder) == os.path.realpath(os.getcwd())):
            print("Not using {}".format(folder))
            continue
        print("Adding {}: ".format(f), end='')
        frames = io.read(f, index=slice(0,None))
        print("{} frames...".format(len(frames)))
        io.write(out, frames, format='extxyz', append=True)
print('...Done!')
