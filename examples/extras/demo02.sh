#!/bin/sh
#Created by Nick Leung z5015489

#simple if, while and for statements

var1=20

if test 10 -le 15
then
	echo 'Ten is less than 15'
elif [ $var1 -gt 10 ]
then
	var1=`expr $var1 - 10`
	echo $var1
fi
