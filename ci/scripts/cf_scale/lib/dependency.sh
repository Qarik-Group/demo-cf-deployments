#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

[[ ${__LIB_DEPENDENCY_SOURCED:-} == "sourced" ]] && return 0
export __LIB_DEPENDENCY_SOURCED="sourced"

# Needed for BASH 5.x extended globbing
shopt -s extglob

# shellcheck source-path=SCRIPTDIR
source cli.sh
# shellcheck source-path=SCRIPTDIR
source debug.sh

declare -A tools_version_check

dependency::add_tool_check() {
  declare key="${1:?dependency::add_tool_check() - missing tool key   $(debug::called_by)}"
  declare ver="${2:?dependency::add_tool_check() - missing minimum tool version    $(debug::called_by)}"
  declare cmd="${3:?dependency::add_tool_check() - missing tool command tool for version    $(debug::called_by)}"
  declare typ="${4:-"command"}"
  tools_version_check[$key]="${ver}"
  tools_version_check[$key,${typ}]="${cmd}"
  tools_version_check[$key,type]="${typ}"
  if debug::is_enabled "checks"; then
      cli::debug checks "$(declare -p tools_version_check)"
  fi
}

export -f dependency::add_tool_check

need_command() {
  declare cmd=${1:?need_command() - no command name given   $(debug::called_by)}

  # shellcheck disable=SC2086
  if [[ ! -x "$(command -v ${cmd})" ]]; then
    cli::error "The ${cmd} is not found in your PATH.  Please install and update"
    cli::error "your PATH before proceeding."
    return 1
  fi
  return 0
}

extract_version() {
  declare line=${1:?"extract_version() Missing search string $(debug::called_by)"}
  [[ "${line}" =~ ([[:digit:]]+(\.[[:digit:]]+){1,2}) ]]
}

is_version_ok() {
  declare minimum=${1:?"is_version_ok() Missing minimum version $(debug::called_by)"}
  declare version=${2:?"is_version_ok() Missing compare version $(debug::called_by)"}
  IFS=. read -r -a minver <<< "${minimum}"
  IFS=. read -r -a cmpver <<< "${version}"
  (( ${minver[0]:-0} < ${cmpver[0]:-0} )) && return 0
  (( ${minver[0]:-0} > ${cmpver[0]:-0} )) && return 1
  (( ${minver[1]:-0} < ${cmpver[1]:-0} )) && return 0
  (( ${minver[1]:-0} > ${cmpver[1]:-0} )) && return 1
  (( ${minver[2]:-0} < ${cmpver[2]:-0} )) && return 0
  (( ${minver[2]:-0} > ${cmpver[2]:-0} )) && return 1
  return 0
}

has_minimum_program_version() {
  declare program="${1:?has_minimum_program_version() Missing program name $(debug::called_by)}"
  declare minimum="${2:?compare_version() Missing minimum version $(debug::called_by)}"
  declare version="${3:?compare_version() Missing compare version $(debug::called_by)}"

  if extract_version "${version}"
  then
    declare progver="${BASH_REMATCH[1]}"
    if ! is_version_ok "${minimum}" "${progver}"
    then
      cli::error "You need to upgrade ${program} from version ${progver} to at least version ${minimum}" 
      return 1
    fi
  else
    cli::error "Unable to extract version for ${program}" 
    return 1
  fi
  return 0
}

dependency::checks() {
  local tool_check_list=${*:?-"Missing tools to check list   $(debug::called_by)"}
  local -i ret_code=0

  for cmd in ${tool_check_list}
  do
    need_command "${cmd}" || {
        ret_code=$?
        continue
    }
    [[ -n "${tools_version_check[${cmd}]:+check_version}" ]] && {
      local version="${tools_version_check[${cmd}]}" 
      local cmd="${tools_version_check[${cmd},command]}" 
      has_minimum_program_version "${cmd}" "${version}" "$(${cmd} 2>&1)" || ret_code=$?
  }
  done

  return $ret_code
}

export -f dependency::checks
