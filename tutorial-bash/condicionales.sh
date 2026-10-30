#!/bin/bash


file='condicionales.sh'


if [[ $1 && $(( $1 % 2 )) == 0 ]]
then
	echo Par
else
	echo Impar
fi
