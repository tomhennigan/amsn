#!/bin/bash
# Removes unnecesary spaces and tabs after the key,
# checks for duplicated keys 
# checks for missing keys
# strips unneccesarry lines
# by Peter Aron Horvath from Hungary, Miskolc
# petesm@freemail.hu
clear
echo -e "Lang File Checking for \33[32;01maMSN\33[0m v0.1b by Peter Aron Horvath"
echo "http://www.iit.uni-miskolc.hu/~horvath16/"
echo 
if [ -z $1 ]; then
    echo "USAGE: langchk <english lang file> <costum lang file>"
    exit
fi
if [ -z $2 ]; then
    echo "USAGE: langchk <english lang file> <costum lang file>"
    exit
fi

# checking for missing keys
echo -e "Using file \33[32;1m'$1'\33[0m as directory to process \33[32;1m'$2'\33[0m"
echo "Checking for duplicated keys/missing keys and stripping:"
rows=`cat $1|wc -l|awk '{print $1}'`
echo -n "key: $rows /  "
n=0
echo>lang.post
for i in `cat $1 |awk '{print $1}'`
do
    n=`expr $n + 1`
    echo -ne "\33[6;13H"
    echo "$n"
    res=`cat $2 |grep "^$i "`
    if [ -z "$res" ]; then
	#key not found
	err=`echo "$err\n\33[31;01mMissing key:\33[0m $i"`
    else
	row=`echo "$res" | uniq`
	if [[ "$res" != "$row" ]]; then
	    #duplicated key
	    err=`echo "$err\n\33[31;1mDuplicated key:\33[0m $i"`
	else
	    orig=`cat $1|grep "^$i "`
	    trans=`cat $2|grep "^$i "`
	    if [[ "$orig" == "$trans" ]]; then
		#key not translated
		if [[ ! "$i" == "amsn_lang_version" ]]; then
		    err=`echo "$err\n\33[33;1mNot translated key:\33[0m $i"`
		fi
	    else
		#all ok write key out
		# remove unnecesary spaces
		echo $res |awk '{print $1 " " substr($0,index($0,$2),length($0))}'>>lang.post
	    fi
	fi
    fi
done
if [ -n "$err" ]; then
    echo -e $err
    echo -e $err >langchk.log
    echo "Lines in yellow are just notices."
    echo "'lang.fix' does not contain the lines with errors!"
else
    echo "Lang file OK and fully translated!"
fi
echo "amsn_lang_version 2" >lang.fix
cat lang.post |grep -v "amsn_lang_version 2"|grep -v "^$"|sort -d >>lang.fix
rm lang.post
echo
echo "Owerwrite file '$2' with the final output? [y/N]"
read a
if [[ "$a" == "y" || "$a" == "Y" ]];  then
    cat lang.fix >$2
    echo "Now please send '$2' to:"
    echo "amsn-translations@lists.sourceforge.net"
    echo "remember partialy translated files are usefull too!"
else
    echo "'lang.fix' is the output."
    echo "Now please reaname it to the correct name and send it to:"
    echo "amsn-translations@lists.sourceforge.net"
    echo "remember partialy translated files are usefull too!"
    echo "$1 and $2 files are untouched!"
fi
exit

