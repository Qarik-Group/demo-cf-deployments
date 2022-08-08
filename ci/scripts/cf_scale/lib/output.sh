#!/usr/bin/env bash

[[ ${__LIB_OUTPUT_SOURCED:-} == "sourced" ]] && return 0
export __LIB_OUTPUT_SOURCED="sourced"

source debug.sh
source trace.sh

# This file contains the output commands for logging
# See documentation at the bottom of the file

# Define colors for output.
         BLACK="\e[0;30m"
           RED="\e[0;31m"
         GREEN="\e[0;32m"
        YELLOW="\e[0;33m"
          BLUE="\e[0;34m"
        PURPLE="\e[0;35m"
          CYAN="\e[0;36m"
         WHITE="\e[0;37m"
         RESET="\e[0m"
  UNDERLINE_ON="\e[4m"
 UNDERLINE_OFF="\e[24m"
  CROSS_OUT_ON="\e[9m"
 CROSS_OUT_OFF="\e[29m"
    BKGD_BLACK="\e[40m"
      BKGD_RED="\e[41m"
    BKGD_GREEN="\e[42m"
   BKGD_YELLOW="\e[43m"
     BKGD_BLUE="\e[44m"
   BKGD_PURPLE="\e[45m"
     BKGD_CYAN="\e[46m"
    BKGD_WHITE="\e[47m"
   SAVE_CURSOR="\e[s"
RESTORE_CURSOR="\e[u"

# Format the results of test messages.

# When a test passes

log_info() {
  declare message="$@"
  declare status="INFO"
  printf "${PURPLE}%-7s${RESET} %-.70s\n" "${status}" "${message}"
  return 0
}

export -f log_info

log_result() {
  declare message="$@"
  declare status="RESULT"
  printf "${CYAN}%-7s${RESET} %-.70s\n" "${status}" "${message}"
  return 0
}

export -f log_result

log_warn() {
  declare message="$@"
  declare status="WARN"
  printf "${YELLOW}%-7s${RESET} %-.70s\n" " ${status}" "${message}"
}

export -f log_warn

log_ok() {
  declare message="$@"
  declare status="PASSED"
  printf "${GREEN}%-7s${RESET} %-.70s\n" "${status}"
  return 0
}

export -f log_ok

# when a test fails
# TODO: how can a test be red and yellow, just because it has a message?

log_not_ok() {
  declare message="$@"
  declare status="FAILED"
  printf "${RED}%-7s${RESET}\n" "${status}"
  [[ -n "${message}" ]] && {
    printf "${YELLOW}REASON ${RESET} %-.70s\n" "${message}"
  }
  return 0
}

export -f log_not_ok

log_active() {
  declare message="$@"
  declare status="ACTIVE"
  printf "${YELLOW}%-7s${RESET} %-.70s\r" "${status}" "${message}"
  return 0
}

export -f log_active

# single argument with , : or space separators
# Using , as the default when concatenating values

enable_debug() {
  local OLD_IFS="${IFS}"
  IFS=',: ';
  set -- ${LH_DEBUG} "$@"
  local sep=${IFS::1}
  export LH_DEBUG="$@"${sep}
  IFS=${OLD_IFS};
}

export -f enable_debug

enable_trace() {
  local OLD_IFS="${IFS}"
  IFS=',: ';
  set -- ${LH_TRACE} "$@"
  local sep=${IFS::1}
  export LH_TRACE="$@"${sep}
  IFS=${OLD_IFS};
  export LH_TRACE="$@"
}

export -f enable_trace

debug() {
  declare debug_type=${1?debug() - no debug keyword given   $(debug::called_by)}
  if debug::is_enabled ${debug_type}
  then
    shift
    echo -e "DEBUG: $*" >&2
  fi
}

export -f debug

trace() {
  declare trace_type=${1?debug() - no trace keyword given   $(debug::called_by)}
  if trace::is_enabled ${trace_type}
  then
    shift
    echo -e "TRACE: $*" >&2
  fi
}

export -f trace

return 0

# These commands are meant to work in terminal windows and in pipelines..
# The convention for test output lines is
#   <7-character-color-coded-word> <message>
