#!/usr/bin/env bash

[[ ${__LIB_DEBUG_SOURCED:-} == "sourced" ]] && return 0
export __LIB_DEBUG_SOURCED="sourced"

# single argument with , : or space separators
# Using , as the default when concatenating values

debug::enable() {
  local OLD_IFS="${IFS}"
  local OLD_GLOB_STATE
  OLD_GLOB_STATE=$(shopt -po noglob) || true 
  IFS=',: '
  set -o noglob
  set -- ${__DEBUG_VALUES:+ $__DEBUG_VALUES} "${@:- $@}"
  local sep=${IFS::1}
  export __DEBUG_VALUES="$*"${sep}
  [[ $(shopt -po noglob) != "${OLD_GLOB_STATE}" ]] && set +o noglob
  IFS=${OLD_IFS};
}

debug::is_enabled() {
  [[ -n ${__DEBUG_VALUES+is_set} ]] && {
    local OLD_GLOB_STATE
    OLD_GLOB_STATE=$(shopt -po noglob) || true
    set -o noglob
    for word in ${1/,/ }; do
      # the trailing , is added by the enable function to allow concatenation to work
      [[ ",${__DEBUG_VALUES}" == *,${word},* ]] && {
        [[ $(shopt -po noglob) != "${OLD_GLOB_STATE}" ]] && set +o noglob
        return 0
      }
    done
    [[ $(shopt -po noglob) != "${OLD_GLOB_STATE}" ]] && set +o noglob
    return 1
  }
}

# The shell function ${FUNCNAME[$i]} is defined in the file ${BASH_SOURCE[$i]} and called from ${BASH_SOURCE[$i+1]}
debug::called_by() {
echo -e "${FUNCNAME[1]} - ${BASH_SOURCE[2]:-main}(${FUNCNAME[2]}) ${BASH_LINENO[1]}"
}
export -f debug::called_by
