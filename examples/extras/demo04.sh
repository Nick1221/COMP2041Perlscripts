#!/bin/sh
#created by Nick Leung z5015489
#Nested things + other minor things

i=0
j=0
k=1
m=10

while [ $i -lt $m ] 
do
    while [ $j -lt $m ]
    do
		k=`expr $k '*' 10`
		j=$(($j + 1))
	done
	k=`expr $k '/' 2`
	i=$(($i + 1))
done
echo $k
