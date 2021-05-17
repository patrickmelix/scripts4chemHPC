#!/bin/bash
cat $(find . -name "*_trj.xyz" | sort -V) > traj.xyz
