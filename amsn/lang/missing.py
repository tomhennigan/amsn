#! /usr/bin/env python
# Author: Gustavo Carneiro
# Modified by: Alvaro J. Iradier
# Use: missing.py langXX
# lists all missing translations keys in language

import string
import sys
import getopt

#COLORS
NONE=0
BOLD=1
RED=31
GREEN=32
YELLOW=33
BLUE=34
MAGENTA=35
CYAN=36
WHITE=37

def esc(text,color,bold=False):
    if nocolors: return text
    seq="\33["+str(color)
    if bold: seq=seq+";1"
    seq=seq+"m"
    return seq+text+"\33[0m"

def usage():
    print "Usage: missing.py [--nocolor] [--hidetrans] langXX"

#By default, colors are shown
nocolors=False
hidetrans=False
    
msg_list = {}

#Get options
try:
    opts,args=getopt.getopt(sys.argv[1:],"n",["nocolor","hidetrans"])
except getopt.GetoptError:
    usage()
    sys.exit(-1)
    
#Process options
for opt,arg in opts:
    if opt in ("--nocolor"): nocolors=True
    elif opt in ("--hidetrans"): hidetrans=True
    
#After parsing options, we should just have the language file
if len(args) != 1:
    usage()
    sys.exit(-1)

#Try to open the master file
try:
    langen=open("langen")
except IOError:
    print "'langen' master keys file is missing"
    sys.exit(1)
#Try to open the language file to check 
try: 
    f=open(args[0])
except IOError:
    print "Couldn't open lang file '"+args[0]+"'"
    sys.exit(2)
    
###################################
#Processing of the master keys
print
print esc("Loading master file...",CYAN)
#Skip version line
header=langen.next().strip()
#Load all master keys
for num,line in enumerate(langen):
    
    line=line.strip()
    
    if len(line)<=0:
        print esc(" ERROR:",RED)+esc(" blank line in 'langen', you should remove it",BOLD)
        print " -->",esc("Line "+str(num+2),YELLOW,True)
        continue
    
    i = string.find(line, ' ')
    tabs = string.find(line,'\t')
    
    if tabs>0:
        print esc(" ERROR:",RED)+esc(" found TAB \\t character in 'langen'",BOLD)
        print " -->",esc("Line "+str(num+2),YELLOW,True)
        continue
    
    if i < 0:
        print esc(" ERROR:",RED)+esc(" invalid key in 'langen', you should remove it",BOLD)
        print " -->",esc(line,YELLOW,True)
        continue

    key = line[:i]
    val = line[i+1:]
    msg_list[key] = val

print
    
###################################
#Now find missing keys
print esc("Checking for missing keys in "+args[0]+"...",CYAN)
loaded_keys=[]
#Skin version line
line=f.next().strip()
if not line==header:
    print esc(" ERROR:",RED)+esc(" Header in file should be "+header,BOLD)
    print " --> ",esc(line,YELLOW,True)
for num,line in enumerate(f):
    
    line=line.strip()
    
    i = string.find(line, ' ')
    tabs = string.find(line,'\t')

    if len(line)<=0:
        print esc(" ERROR:",RED)+esc(" blank line, you should remove it",BOLD)
        print " -->",esc("Line "+str(num+2),YELLOW,True)
        continue

    if tabs>0:
        print esc(" ERROR:",RED)+esc(" found TAB \\t character",BOLD)
        print " -->",esc("Line "+str(num+2),YELLOW,True)
        continue    
    
    if i < 0:
        print esc(" ERROR:",RED)+esc(" invalid key, you should remove it",BOLD)
        print " Line "+str(num+2)+" -->",esc(line.strip(),YELLOW,True)
        continue

    key = line[:i]
    if key in loaded_keys:
        print esc(" ERROR:",RED)+esc(" found duplicated key",BOLD)
        print " Line "+str(num+2)+" -->'"+esc(key,YELLOW,True)+"'. Please remove one of the ocurrences"
        continue
    else:
        loaded_keys.append(key)
    try:
        del msg_list[key]
    except KeyError:
        print esc(" warning:",YELLOW)+esc(" found possibly deprecated key",BOLD)
        print " Line "+str(num+2)+" --> '"+esc(key,YELLOW,True)+"'. Please remove it if it's not used in latest AMSN stable version"

###################################
#Print results
num_missing=len(msg_list.items())
if num_missing>0:
    errormsg=str(num_missing)+" missing keys in "+args[0]+":"
    print
    print esc(errormsg,YELLOW,True)
    print "-"*len(errormsg)
else:
    print
    print esc("** No missing keys in "+args[0]+" **",GREEN)

#Print sorted missing keys
keys=msg_list.keys()
keys.sort()
for key in keys:
    if hidetrans: print esc(key,CYAN,True)
    else:
        print esc(key,CYAN,True)+": "+msg_list[key]

print
