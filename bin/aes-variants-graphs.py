#!/usr/bin/python3

import os
import sys
import argparse
import matplotlib

def build_arg_parser():
    parser = argparse.ArgumentParser()

    parser.add_argument("file",type=str)

    parser.add_argument("--title",type=str)

    return parser

def main():
    parser = build_arg_parser()

    args = parser.parse_args()

    fh  = open(args.file,"r")
    contents = fh.readlines()

    for line in contents:
        cols     = line.rstrip("\n").split(",")
        
        variant  = cols[0]
        measures = cols[1:]
        measures = [str(int(m,base=16)) for m in measures]
        
        print(",".join([variant]+measures))


if(__name__ == "__main__"):
    main()
