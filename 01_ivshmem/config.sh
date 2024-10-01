#!/usr/bin/env bash
# This file contains variables shared between setup.sh, start.sh, and stop.sh

REALPATH=$(dirname $(realpath $0))
HOST_DIR=/home/vms-x64_86

KERNEL_VERSION=6.10.11 # Stable as of 2024-09-27

GUEST_COUNT=2
GUEST_PW=debian
GUEST_PROG_DIR=root/prog

SCREEN_SESSION_ID=qvm