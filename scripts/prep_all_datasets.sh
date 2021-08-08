#!/bin/bash

SCRIPTS=$(dirname `readlink -f "$0"`)
ROOT="$(dirname "$SCRIPTS")"

echo "Generating canneal and svm datasets..."
bash $ROOT/datasets/prep_canneal_dataset.sh > /dev/null 2>&1 &
PID1=$!
bash $ROOT/datasets/prep_svm_dataset.sh >/dev/null 2>&1 &
PID2=$!
wait $PID1
echo "Generating fragmentation datasets..."
$ROOT/datasets/prep_fragmentation_dataset.py
wait $PID2
sync
echo "Done..."
