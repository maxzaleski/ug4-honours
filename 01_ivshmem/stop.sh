#!/usr/bin/env bash

source config.sh

for i in $(seq 1 $GUEST_COUNT); do
  screen -S $SCREEN_SESSION_ID$i -X quit
  echo "--- [vm$i] stopped"
done