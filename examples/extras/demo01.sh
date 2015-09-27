#!/bin/bash
#Check || and a simple while test, plus other minor things
#Created by Nicholas Leung z5015489
g=5
c=10

if [ $g -eq 5 ] || [ $c -eq 10 ]
then  
    echo "$g is 5 and $c is 10"
fi

while test $g -lt $c
do
	g=`expr $g + 1`;
	echo "$g"
done
