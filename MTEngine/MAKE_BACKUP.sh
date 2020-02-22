#!/bin/sh
#
# (C)2009 Marcin Skoczylas
#
PROJ_NAME=MTEngine
export PROJ_NAME
COPYFILE_DISABLE=true
COPY_EXTENDED_ATTRIBUTES_DISABLE=true
export COPYFILE_DISABLE
export COPY_EXTENDED_ATTRIBUTES_DISABLE
cd ..
OUTPUT=./$PROJ_NAME-`date +%Y%m%d`-`date +%H%M`.tar
tar --exclude ".git" -vcf $OUTPUT ./$PROJ_NAME 
echo "gzip $OUTPUT"
gzip $OUTPUT
#echo $HOSTNAME
cd $PROJ_NAME
