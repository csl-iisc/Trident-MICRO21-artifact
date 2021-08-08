#!/bin/bash

SCRIPTS=$(dirname `readlink -f "$0"`)
ROOT="$(dirname "$SCRIPTS")"

echo "Removing canneal dataset..."
rm -rf $ROOT/datasets/canneal_small
echo "Removing svm dataset..."
rm -rf $ROOT/datasets/*kdd*
echo "Removing fragmentation related dataset..."
rm -rf $ROOT/datasets/fragmentation
sync
echo "Done..."
