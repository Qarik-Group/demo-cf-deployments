#!/usr/bin/env bash

[[ ${__LIB_TRACE_SOURCED:-} == "sourced" ]] && return 0
export __LIB_TRACE_SOURCED="sourced"

# single argument with , : or space separators
# Using , as the default when concatenating values

trace::enable() {
  local OLD_IFS="${IFS}"
  local OLD_GLOB_STATE
  OLD_GLOB_STATE=$(shopt -po noglob) || true
  IFS=',: ';

  set -o noglob
  set -- ${__TRACE_VALUES:+ $__TRACE_VALUES} "${@:- $@}"
  local sep=${IFS::1}
  export __TRACE_VALUES="$*"${sep}
  [[ $(shopt -po noglob) != "${OLD_GLOB_STATE}" ]] && set +o noglob
  IFS=${OLD_IFS};
}

trace::is_enabled() {
  [[ -n ${__TRACE_VALUES+is_set} ]] && {
    local OLD_GLOB_STATE
    OLD_GLOB_STATE=$(shopt -po noglob) || true
    set -o noglob
    for word in ${1/,/ }; do
      # the trailing , is added by the enable function to allow concatenation to work
      [[ ",${__TRACE_VALUES}" == *,${word},* ]] && {
        [[ $(shopt -po noglob) != "${OLD_GLOB_STATE}" ]] && set +o noglob
        return 0
      }
    done
    [[ $(shopt -po noglob) != "${OLD_GLOB_STATE}" ]] && set +o noglob
    return 1
  }
}
