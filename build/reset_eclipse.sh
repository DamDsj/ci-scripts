#!/bin/bash
source $(dirname $0)/../utils/defines.sh
setupEclipse $1

echo "***START*** $0 $(date -R)"

rm -fr $ECLIPSE_BUILD
mkdir  $ECLIPSE_BUILD

echo "Copying $ECLIPSE_FRESH/* into $ECLIPSE_BUILD"
cp -r $ECLIPSE_FRESH/* $ECLIPSE_BUILD

echo "***END*** $0 $(date -R)"
