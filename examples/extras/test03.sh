#!/bin/bash
#Created by Nicholas Leung z5015489
#expr in if, might not have implemented in mine

j=0
if [ `expr $j % 2` -eq 0 ]
then 
    echo -n "* "
else
    echo -n "# "
fi
