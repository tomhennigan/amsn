#! /usr/bin/env python
# Author: Gustavo Carneiro
# Modified by: Alvaro J. Iradier
# Use: missing.py langXX
# lists all missing translations keys in language

import string
import sys

msg_list = {}

if len(sys.argv) != 2:
	print "Usage: missing.py langXX"
	sys.exit(-1)

try:
	langen=open("langen")
except IOError:
	print "'langen' master keys file is missing"
	sys.exit(1)
	
try: 
    f=open(sys.argv[1])
except IOError:
    print "Couldn't open lang file '"+sys.argv[1]+"'"
    sys.exit(2)
	
print "Loading master file..."
#Skip version line
line=langen.next()
#Load all master keys
for line in langen:
    
    line=line.strip("\n")
    
    if len(line)<=0:
        print " WARNING: blank line in 'langen', you should remove it"
        continue
    
    i = string.find(line, ' ')
    
    if i < 0:
        print " WARNING: invalid key in 'langen', you should remove it"
        print " -->",line
        continue

    key = line[:i]
    val = line[i+1:]
    msg_list[key] = val


#Now find missing keys
print "Checking for missing keys in",sys.argv[1]+"..."
loaded_keys=[]
#Skin version line
line=f.next();
for line in f:
    tokens = string.split(line)
    
    if len(tokens)<=0:
        print " WARNING: blank line, you should remove it"
        continue

    if len(tokens)<2:
        print " WARNING: invalid key, you should remove it"
        print " -->",line
        continue

    key = tokens[0]
    if key in loaded_keys:
        print " WARNING: found duplicated key"
        print " -->'"+key+"'. Please remove one of the ocurrences"
        continue
    else:
        loaded_keys.append(key)
    try:
        del msg_list[key]
    except KeyError:
        print " WARNING: found possibly deprecated key"
	print " --> '"+key+"'. Please remove it if it's not used in latest AMSN stable version"
#    print string.rstrip(line)

num_missing=len(msg_list.items())
if num_missing>0:
	print
	print str(num_missing)+" missing keys in",sys.argv[1]+":"
	print "---------------------------"
else:
	print
	print "No missing keys in",sys.argv[1]

#Print sorted missing keys
keys=msg_list.keys()
keys.sort()
for key in keys:
    print key

