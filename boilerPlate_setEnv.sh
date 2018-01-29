#!/usr/bin/env bash



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
[[ "${@:-}" =~ ^-h|--help$  ]] && __setEnv_help "$@"

# If expected parameter count does not match passed argument count then show help & exit
[[ "${#:-x}" != "${__setEnv_expected_param_count:-y}" ]] && __setEnv_help "$@"

# set the argument to appName variable
appName="${1}"

# Check if the [APP_NAME] is a valid name
# If setEnv-[APP_NAME] file does not exists then alert user and fail the process. 
[[ -f "${__setEnv_parentdir}/env/setEnv-${appName}" ]] || error "Invalid Appname [APP_NAME] : \
## ${appName} ##. Please ensure env file for app exists in path : ## ${__setEnv_parentdir}/env/setEnv-${appName} ##."


#####################################################################
# Export variables common to all applications using file : ${__setEnv_parentdir}/env/setEnv-COMMON
#####################################################################

# If setEnv-COMMON file exists then source that file
	# setEnv-COMMON file is supposed to contain and export setting that will be common
	# for all applications. If this file exists then it will be sourced else
	# it will be ignored
[[ -f "${__setEnv_parentdir}/env/setEnv-COMMON" ]] && source "${__setEnv_parentdir}/env/setEnv-COMMON"

[[ -f "${__setEnv_parentdir}/env/setEnv-COMMON" ]] && info "Successful export of variables common \
to all applications using file : ${__setEnv_parentdir}/env/setEnv-COMMON."

								
# If setEnv-COMMON file does not exists then print message and continue without setEnv-COMMON
[[ -f "${__setEnv_parentdir}/env/setEnv-COMMON" ]] || warning "No Common App settings detected for [APP_NAME] : \
## ${appName} ## in path : ## ${__setEnv_parentdir}/env/setEnv-COMMON ##."
								
								
# Below setting will go in setEnv-COMMON
# [[ "${PATH:-}" =~ ^.*/opt/IBM/InformationServer/Server/DSEngine/bin.*$  ]] || PATH="${PATH}:/opt/IBM/InformationServer/Server/DSEngine/bin"
# [[ "${PATH:-}" =~ ^.*/opt/IBM/InformationServer/Clients/istools/cli.*$  ]] || PATH="${PATH}:/opt/IBM/InformationServer/Clients/istools/cli"
# export PATH



#####################################################################
# Export variables specific to application using file : ${__setEnv_parentdir}/env/setEnv-[APP_NAME]
#####################################################################
# If setEnv-[APP_NAME] file exists then source that file
	# setEnv-[APP_NAME] file is supposed to contain and export setting that will be specific
	# for the applications. If this file exists then it will be sourced else the process should fail
	# it will be ignored
[[ -f "${__setEnv_parentdir}/env/setEnv-${appName}" ]] && source "${__setEnv_parentdir}/env/setEnv-${appName}"

[[ -f "${__setEnv_parentdir}/env/setEnv-${appName}" ]] && info "Successful Export of variables specific \
to application using file : ${__setEnv_parentdir}/env/setEnv-${appName}"

#####################################################################
# Export Secure userid & passwords for the  specific application using file : ${__setEnv_parentdir}/env/.include-[APP_NAME]
#####################################################################

# If .include-[APP_NAME] file does not exists then print message and continue without .include-[APP_NAME] 
[[ -f "${__setEnv_parentdir}/env/.include-${appName}" ]] || warning "No userid & passwords file for [APP_NAME] : \
## ${appName} ## found in path : ## ${__setEnv_parentdir}/env/.include-${appName} ##."


# If .include-[APP_NAME] file exists then source that file as well
	# .include-[APP_NAME] file is used to store userid & passwords required for the given [APP_NAME].
	# If this file exists then it will be sourced else it will be ignored
[[ -f "${__setEnv_parentdir}/env/.include-${appName}" ]] && source "${__setEnv_parentdir}/env/.include-${appName}"

[[ -f "${__setEnv_parentdir}/env/.include-${appName}" ]] && info "Successful Export of secure userid & passwords for \
the  specific application using file : ${__setEnv_parentdir}/env/.include-${appName}"






