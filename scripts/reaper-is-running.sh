#!/bin/sh

pgrep_command=$1

"$pgrep_command" -x reaper >/dev/null \
  || "$pgrep_command" -x REAPER >/dev/null \
  || "$pgrep_command" -x '[.]reaper-wrapped' >/dev/null
