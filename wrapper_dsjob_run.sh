#!/usr/bin/env bash



# Set magic variables for current file, directory, os, etc.
__wrprdsrun_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
__wrprdsrun_parentdir="$(dirname "${__wrprdsrun_dir}")"
__wrprdsrun_file="${__wrprdsrun_dir}/$(basename "${BASH_SOURCE[0]}")"
__wrprdsrun_base="$(basename "${__file}" .sh)"


# Used to verify if the required number of variables are passed to the script
__wrprdsrun_expected_param_count=2

# Set Usage Information
[[ "${__usage+x}" ]] || read -r -d '' __usage <<-'EOF' || true # exits non-zero when EOF encountered
Usage:
  ${__wrprdsrun_base} [APP_NAME] [JOB_NAME]
  ${__wrprdsrun_base} -h | --help

Options:
  -h --help  Show this screen.
EOF


# Set Helptext Information
[[ "${__helptext+x}" ]] || read -r -d '' __helptext <<-'EOF' || true # exits non-zero when EOF encountered
Script for running datastage job : [JOB_NAME] using environment setting of given [APP_NAME]. 
e.g sh wrapper_dsjob_run.sh TESTAPP PARALLEL_JOB_1
EOF


function __wrprdsrun_help () {
  echo "" 1>&2
  echo " ${*}" 1>&2
  echo "" 1>&2
  echo "  ${__usage:-No usage available}" 1>&2
  echo "" 1>&2

  if [[ "${__helptext:-}" ]]; then
    echo " ${__helptext}" 1>&2
    echo "" 1>&2
  fi
  exit 1
}


function warning ()  {
echo -e "$(date -u +"%Y-%m-%d %H:%M:%S UTC") :   ! WARNING : $@" 1>&2
}

function info ()  {
echo -e "$(date -u +"%Y-%m-%d %H:%M:%S UTC") :        INFO : $@" 1>&2
}

function error ()  {
echo -e "$(date -u +"%Y-%m-%d %H:%M:%S UTC") : !! ERROR !! : $@" 1>&2
exit 1
}

# If help option is invoked then show help and exit
[[ "${@:-}" =~ ^-h|--help$  ]] && __wrprdsrun_help "$@"

# If expected parameter count does not match passed argument count then show help & exit
[[ "${#:-x}" != "${__wrprdsrun_expected_param_count:-y}" ]] && __wrprdsrun_help "$@"

# set the argument to appName variable
appName="${1}"
jobName="${2}"

# Export setting for the input APP_NAME
source ${__wrprdsrun_dir}/setEnv.sh "${appName}"

info "$DS_USER"
