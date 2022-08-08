#!/usr/bin/env bash

[[ ${__LIB_CLI_SOURCED:-} == "sourced" ]] && return 0
export __LIB_CLI_SOURCED="sourced"

# shellcheck source-path=SCRIPTDIR
source debug.sh
# shellcheck source-path=SCRIPTDIR
source trace.sh

cli::debug() {
  declare debug_type=${1?debug() - no debug keyword given   $(debug::called_by)}
  if debug::is_enabled "${debug_type}"; then
    shift
    echo -e "DEBUG: $*" >&2
  fi
}

cli::trace() {
  declare trace_type=${1?debug() - no trace keyword given   $(debug::called_by)}
  if trace::is_enabled "${trace_type}"; then
    shift
    echo -e "TRACE: $*" >&2
  fi
}

cli::fatal() {
  echo -e "FATAL: $*"
  exit 1
}

cli::step() {
  cat <<EOF

==\\\\
====>  $@
==//

EOF
}

cli::echo() {
  echo -e "$@"
}

cli::warn() {
  echo -e "WARN: $*"
}

cli::error() {
  echo -e "ERROR: $*"
}

cli::info() {
  echo -e "\nINFO: $*\n"
}
