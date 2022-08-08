#!/usr/bin/env bash

[[ ${__LIB_CURL_SOURCED:-} == "sourced" ]] && return 0
export __LIB_CURL_SOURCED="sourced"

# shellcheck source-path=SCRIPTDIR
source debug.sh
# shellcheck source-path=SCRIPTDIR
source cli.sh

declare _temp_dir_prefix="results"

query_get_error()
{
    declare dataset="${1:?Missing dataset file   $(debug::called_by)}"
     
    exec 3< "${dataset}"
    read -r line <&3
    if [[ "${line}" == '{' ]]
    then
        jq -c -r '"cf query failure: " + .description' "${dataset}"
    elif [[ "${line}" == "FAILED" ]]
    then
        read -r line <&3
        [[ "${line}" == *: ]] && read -r line <&3
        cli::echo "cf query failure: ${line}"
    else
        cli::echo "cf query failure: ${line}"
    fi
    exec 3<&-
}

query_get_error_codes()
{
    declare dataset="${1:?Missing dataset file   $(debug::called_by)}"
     
    jq -c -r '"(" + .error_code + " " + .code + ")"' "${dataset}"
}

query_has_error()
{
    declare dataset="${1:?Missing dataset path   $(debug::called_by)}"
    jq '([type=="object" and length==3 and has("error_code","code","description")]|all)
       or (type=="object" and has("errors"))' "${dataset}"
}

has_multi_result_packet()
{
    declare dataset="${1:?Missing dataset path   $(debug::called_by)}"
    jq '[type=="object",has("pagination")]|all' "${dataset}"
    # jq '[type=="object",has("next_url","prev_url","total_results","total_pages")]|all' "${dataset}"
}

query::cf_api()
{
    declare next_url="${1:?Missing cf api url   $(debug::called_by)}"
    declare result_type="${2:?Missing result filename   $(debug::called_by)}"
    declare temp_dir="${_temp_dir_prefix}/${result_type}"
    [[ ${next_url} == "x" ]] && { next_url=""; }
    declare -i i=0
    declare dataset
    declare -a datasets
    mkdir -p "${temp_dir}/parts.$$"
    dataset="${temp_dir}/parts.$$/dataset.${i}"
    while [[ "${next_url}" != "null" ]]; do
        cf curl "${next_url}" &> "${dataset}"
        if ! cf curl "${next_url}" &> "${dataset}"
        then
            if debug::is_enabled "curl"; then
                cli::debug curl "cf curl return a non-zero return status.   $(debug::called_by)"
            fi
            return 2  # cf detected an error
        elif [[ $(query_has_error "${dataset}") == "true" ]]
        then
            if debug::is_enabled "curl"; then
              cli::debug curl "cf curl was successfull but returned an error   $(debug::called_by)"
            fi
            return 1  # cf detected an error
        elif [[ $(has_multi_result_packet "${dataset}") != "true" ]]
        then
            if debug::is_enabled "curl"; then
                cli::debug curl "cf curl was successfull but output data format was unexpected   $(debug::called_by)"
            fi
            return 2 # unexpected output for this fuction
        fi
        datasets[i]="${dataset}"
        next_url=$(jq -r -c '.pagination.next.href//"null"|match("null|.*?//.*?(/.*)")|.captures[0].string' "${dataset}")
        if debug::is_enabled "curl"; then
          cli::debug query "next_url: ${next_url}"
        fi
        # [[ "${next_url}" != "null" ]] && next_url="/$(echo "$next_url" | cut -d '/' -f '4-')"
        # if debug::is_enabled "curl"; then
          # cli::debug query "next_url ${next_url}"
        # fi

        ((i += 1))
        dataset="${temp_dir}/parts.$$/dataset.${i}"
    done

    # TODO error handling if no files created

    if debug::is_enabled "curl"; then
        cli::debug curl "${result_type} created ${#datasets[@]} datasets   $(debug::called_by)"
        for dataset in "${datasets[@]}"
        do
            cli::debug curl "${dataset}   $(debug::called_by)"
        done
    fi

    return 0
}

return 0
