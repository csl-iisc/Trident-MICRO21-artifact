#!/bin/bash

# disable THP

NUMACTL="../numactl/numactl"

NODESTR=$(numactl --hardware | grep available)
NODE_MAX=$(echo ${NODESTR##*: } | cut -d " " -f 1)
NODE_MAX=`expr $NODE_MAX - 1`

for NPAGES in 1 256 2048; do
  for THP in never always; do
      echo $THP | sudo tee /sys/kernel/mm/transparent_hugepage/enabled > /dev/null
      sudo mount -o remount,huge=$THP /dev/shm
      for MITOSIS in ON OFF; do

          OPTMIT=""
          ARGMIT=""
          if [ "$MITOSIS" == "ON" ]; then
              OPTMIT="--pgtablerepl=0-$NODE_MAX"
              ARGMIT="-m"
          fi

          ARGTHP=""
          if [ "$THP" == "always" ]; then
              ARGTHP="-l"
          fi

          $NUMACTL $OPTMIT -N 0 -m 0 -- ./mmapbench $ARGMIT -s $NPAGES $ARGTHP
      done
  done
done


echo "===================================================="

for NPAGES in 1 256 2048; do
  for THP in never always; do
      echo $THP | sudo tee /sys/kernel/mm/transparent_hugepage/enabled > /dev/null
      sudo mount -o remount,huge=$THP /dev/shm
      for MITOSIS in ON OFF; do

          OPTMIT=""
          ARGMIT=""
          if [ "$MITOSIS" == "ON" ]; then
              OPTMIT="--pgtablerepl=0-$NODE_MAX"
              ARGMIT="-m"
          fi

          ARGTHP=""
          if [ "$THP" == "always" ]; then
              ARGTHP="-l"
          fi
          echo "NPAGES=$NPAGES, THP=$THP, MITOSIS=$MITOSIS"
          time $NUMACTL $OPTMIT -N 0 -m 0 -- ./mmapbench $ARGMIT -s $NPAGES $ARGTHP
      done
  done
done
