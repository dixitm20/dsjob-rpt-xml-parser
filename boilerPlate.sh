#!/usr/bin/env bash

# Add directory path so that the dsjob and istool commands are accessible
# Add to PATH only if it does not already contains the dsjob and istool directory path
[[ "${PATH:-}" =~ ^.*/opt/IBM/InformationServer/Server/DSEngine/bin.*$  ]] || PATH="${PATH}:/opt/IBM/InformationServer/Server/DSEngine/bin"
[[ "${PATH:-}" =~ ^.*/opt/IBM/InformationServer/Clients/istools/cli.*$  ]] || PATH="${PATH}:/opt/IBM/InformationServer/Clients/istools/cli"
export PATH

# Set magic variables for current file, directory, os, etc.
__setEnv_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
__setEnv_parentdir="$(dirname "${__setEnv_dir}")"
__setEnv_file="${__setEnv_dir}/$(basename "${BASH_SOURCE[0]}")"
__setEnv_base="$(basename "${__file}" .sh)"


# Used to verify if the required number of variables are passed to the script
__setEnv_expected_param_count=1

# Set Usage Information
[[ "${__usage+x}" ]] || read -r -d '' __usage <<-'EOF' || true # exits non-zero when EOF encountered
Usage:
  ${__setEnv_base} [APP_NAME]
  ${__setEnv_base} -h | --help

Options:
  -h --help  Show this screen.
EOF


# Set Helptext Information
[[ "${__helptext+x}" ]] || read -r -d '' __helptext <<-'EOF' || true # exits non-zero when EOF encountered
Script for setting the env for an given application.
EOF


function __setEnv_help () {
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
echo -e "$(date -u +"%Y-%m-%d %H:%M:%S UTC") : ! WARNING : $@" 1>&2
}

function info ()  {
echo -e "$(date -u +"%Y-%m-%d %H:%M:%S UTC") : INFO : $@" 1>&2
}

function error ()  {
echo -e "$(date -u +"%Y-%m-%d %H:%M:%S UTC") : !! ERROR !! : $@" 1>&2
exit 1
}

# If help option is invoked then show help and exit
[[ "${@:-}" =~ ^-h|--help$  ]] && __setEnv_help "$@"

# If expected parameter count does not match passed argument count then show help & exit
[[ "${#:-x}" != "${__setEnv_expected_param_count:-y}" ]] && __setEnv_help "$@"

# set the argument to appName variable
appName="${1}"


#####################################################################
# Application specific variables to be included below
#####################################################################
case "${appName}" in
DUMMY_APP1)
  TEST_VAR_1=TEST_VAL_1; export TEST_VAR_1
  ;;
DUMMY_APP2)
  TEST_VAR_2=TEST_VAL_1; EXPORT TEST_VAR_2
  ;;
*)
  error "Invalid [APP_NAME] : ${appName}. Please ensure that you pass a valid [APP_NAME]."
  ;;
esac


#####################################################################
# Secure userid and passwords stored in .include file to be included here
#####################################################################

# If .include file exists then source that file as well
	# .include file is used to store passwords required for the given [APP_NAME].
	# for a given [APP_NAME] the include file should be named .include-[APP_NAME]
	#             & it must exist in the same path where setEnv is placed
[[ -f "${__setEnv_dir}/.include-${appName}" ]] && source "${__setEnv_dir}/.include-${appName}"


# If .include file does not exists then print message and continue without .include
[[ -f "${__setEnv_dir}/.include-${appName}" ]] || warning "Expected .include file for [APP_NAME] : \
## ${appName} ## not found in path - ## ${__setEnv_dir}/.include-${appName} ##. Continue without .include file."

#####################################################################
# Variables common for all applications should be included here
#####################################################################
# Add directory path so that the dsjob and istool commands are accessible
# Add to PATH only if it does not already contains the dsjob and istool directory path

[[ "${PATH:-}" =~ ^.*/opt/IBM/InformationServer/Server/DSEngine/bin.*$  ]] || PATH="${PATH}:/opt/IBM/InformationServer/Server/DSEngine/bin"
[[ "${PATH:-}" =~ ^.*/opt/IBM/InformationServer/Clients/istools/cli.*$  ]] || PATH="${PATH}:/opt/IBM/InformationServer/Clients/istools/cli"
export PATH






