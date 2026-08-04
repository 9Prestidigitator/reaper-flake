#!/bin/sh

# REAPER can appear under several process names depending on the platform and
# whether Nix's makeWrapper has replaced the executable.
pgrep_command=$1

"$pgrep_command" -x reaper >/dev/null \
  || "$pgrep_command" -x REAPER >/dev/null \
  || "$pgrep_command" -x '[.]reaper-wrapped' >/dev/null
