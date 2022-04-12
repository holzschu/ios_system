#!/bin/sh
# $Id: run_test.sh,v 1.15 2012/01/03 10:18:14 tom Exp $
# Test-script for DIFFSTAT

# change this for ad hoc testing of compression
#TYPE=.pat.Z
#TYPE=.pat.gz
#TYPE=.pat.bz2
TYPE=.pat

if [ $# = 0 ]
then
	eval '"$0" *${TYPE}'
	exit
fi
PATH=`cd ..;pwd`:$PATH; export PATH
# Sanity check, remembering that not every system has `which'.
(which diffstat) >/dev/null 2>/dev/null && echo "Checking `which diffstat`"

for item in $*
do
	echo "testing `basename $item $TYPE`"
	for OPTS in "" "-p1" "-p9" "-f0" "-u" "-k" "-r1" "-r2" "-b" "-R" "-Rp0"
	do
		NAME=`echo $item | sed -e 's/'$TYPE'$//'`
		DATA=${NAME}${TYPE}
		if [ ".$OPTS" != "." ] ; then
			NAME=$NAME`echo ./$OPTS|sed -e 's@./-@@'`
		fi
		TEST=`basename $NAME`
		diffstat -e $TEST.err -o $TEST.out $OPTS $DATA
		if [ -f $NAME.ref ]
		then
			diff -b $NAME.ref $TEST.out >check.out
			if test -s check.out
			then
				echo "?? fail: $TEST"
				ls -l check.out
				cat check.out
			else
				echo "** ok: $TEST"
				rm -f $TEST.out
				rm -f $TEST.err
			fi
		else
			echo "** save: $TEST"
			mv $TEST.out $NAME.ref
			rm -f $TEST.err
		fi
	done
done
