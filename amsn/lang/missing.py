#! /usr/bin/env python
# Author: Gustavo Carneiro
# Modified by: Alvaro J. Iradier
# Use: missing.py langXX
# lists all missing translations keys in language

import string
import fileinput

msg_list = {}


for line in fileinput.input("langen"):
    i = string.find(line, ' ')
    if i < 0: continue
    key = line[:i]
    val = line[i+1:]
    msg_list[key] = val



for line in fileinput.input():
    tokens = string.split(line)
    key = tokens[0]
    try:
	del msg_list[key]
    except KeyError: pass
#    print string.rstrip(line)

#print "Needed keys:"
for key, val in msg_list.items():
    print string.rstrip(key)

