#!/usr/bin/env bash
# Disk Usage Indicator for TMUX
df -h / \
  | tail -n1 \
  | awk '{print "Disk Size="$2", Used="$3", Available="$4", "$5" of disk used"}' \
