#!/bin/bash
#ECHON with few features removed
#Created by Nicholas Leung z5015489

i=0
re='^[0-9]+$' #Checking variables
if [ $1 -lt 0 ]
then
    echo "./echon.sh: argument 1 must be a non-negative integer"
else
	while test $i -lt $1
    do
        echo "$1"
		$i=`expr $i + 1`
    done
	while test $i -gt 0
	do
		$i=`expr $i - 1`
		echo "$1"
	done
fi
