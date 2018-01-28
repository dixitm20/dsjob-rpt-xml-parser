#!/usr/bin/env bash
#
#--------------- 
#  DESCRIPTION:
#---------------
#  - This is a utility script meant to be utilized by other parent scripts by sourcing this script.
#    If this script is attempted to be called directly(without source) then it should always !!FAIL!!
#
#    The purpose of this script is to add functions to the parent scripts shell (so it is necessary 
#    to source this script) which can then be utilized by the programmer in his script. 
#    This script does the following tasks:
#      * Adds function to log and print messages
#      * Sources all the files with .sh extension present in the same directory of utils.sh
#      * parses the command line parameters of the parent script as per the __usage defined in the 
#        parent script and places all those into predefined variables. 
#
#---------------
#  USAGE:
#---------------
#  - Usage:  source utils.sh
#
#---------------
#  VERSION: 1.0.1
#---------------
#
#---------------
#  HISTORY 
#---------------
#  - 2017-07-18 - v1.0.0 - First Creation
# 
#-----------------------------------------------------------------------------------------
# Reference has been taken from below listed bash script boiler plate projects on Github
#-----------------------------------------------------------------------------------------
#    * Based on a template by BASH3 Boilerplate v2.3.0
#      http://bash3boilerplate.sh/#authors
#      https://github.com/kvz/bash3boilerplate
#    
#                    AND
#    
#    * Based on the shell script template by NATHANIEL LANDAU
#      https://natelandau.com/boilerplate-shell-script-template/
#      https://github.com/natelandau/shell-scripts
#-----------------------------------------------------------------------------------------


# Define the environment variables (and their defaults) that this script depends on
__LOG_LEVEL="${__LOG_LEVEL:-6}" # 7 = debug -> 0 = emergency
__NO_COLOR="${__NO_COLOR:-}"    # true = disable color. otherwise autodetected
__INDENT="${__INDENT:-|}"
### Functions
##############################################################################

function __bshbp_log () {
  local log_level="${1}"
  shift
  # shellcheck disable=SC2034
  local color_debug="\x1b[35m"
  # shellcheck disable=SC2034
  local color_info="\x1b[32m"
  # shellcheck disable=SC2034
  local color_notice="\x1b[34m"
  # shellcheck disable=SC2034
  local color_warning="\x1b[33m"
  # shellcheck disable=SC2034
  local color_error="\x1b[31m"
  # shellcheck disable=SC2034
  local color_critical="\x1b[1;31m"
  # shellcheck disable=SC2034
  local color_alert="\x1b[1;33;41m"
  # shellcheck disable=SC2034
  local color_emergency="\x1b[1;4;5;33;41m"

  local colorvar="color_${log_level}"

  local color="${!colorvar:-${color_error}}"
  local color_reset="\x1b[0m"

  if [[ "${__NO_COLOR:-}" = "true" ]] || [[ "${TERM:-}" != "xterm"* ]] || [[ ! -t 2 ]]; then
    if [[ "${__NO_COLOR:-}" != "false" ]]; then
      # Don't use colors on pipes or non-recognized terminals
      color=""; color_reset=""
    fi
  fi

  # all remaining arguments are to be printed
  local log_line=""
  
  #
  

  while IFS=$'\n' read -r log_line; do
    echo -e "$(date -u +"%Y-%m-%d %H:%M:%S UTC") ${color}$(printf "[%9s]" "${log_level}")${color_reset} ${__INDENT}${log_line}" 1>&2
  done <<< "${@:-}"
}

function emergency () {                                __bshbp_log emergency "${@}"; exit 1; }
function alert ()     { [[ "${__LOG_LEVEL:-0}" -ge 1 ]] && __bshbp_log alert "${@}"; true; }
function critical ()  { [[ "${__LOG_LEVEL:-0}" -ge 2 ]] && __bshbp_log critical "${@}"; true; }
function error ()     { [[ "${__LOG_LEVEL:-0}" -ge 3 ]] && __bshbp_log error "${@}"; true; }
function warning ()   { [[ "${__LOG_LEVEL:-0}" -ge 4 ]] && __bshbp_log warning "${@}"; true; }
function notice ()    { [[ "${__LOG_LEVEL:-0}" -ge 5 ]] && __bshbp_log notice "${@}"; true; }
function info ()      { [[ "${__LOG_LEVEL:-0}" -ge 6 ]] && __bshbp_log info "${@}"; true; }
function debug ()     { [[ "${__LOG_LEVEL:-0}" -ge 7 ]] && __bshbp_log debug "${@}"; true; }

function help () {
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

### Exit
##############################################################################
# ------------------------------------------------------
# Being a utility script it is meant be sourced in other scripts and it must fail 
# if an attempt is made to call the script directly or value for required variables
# __usage & __helptext has not been set
# ------------------------------------------------------
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
  __is_utils_sourced="1" # true
else
  __is_utils_sourced="0" # false
fi

[[ "${__is_utils_sourced}" = "0" ]] && emergency "Cannot continue as the utils.sh "\
"is used directly (without being sourced). Usage:  source utils.sh"

# Unset the variable as it is no longer needed
unset -v __is_utils_sourced

# Exit if either __usage or __helptext are not defined by the parent script
[[ "${__helptext:-}" ]] || emergency "Cannot continue without __helptext definition. "
[[ "${__usage:-}" ]] || emergency "Cannot continue without __usage definition. "



### Source additional /lib files
##############################################################################
# ------------------------------------------------------
# First we locate this script and populate the ${__bshbp_tmp_utils_src_path} variable
# Doing so allows us to source additional files from this utils file.
# ------------------------------------------------------

__bshbp_tmp_utils_src="${BASH_SOURCE[0]}"

while [ -h "${__bshbp_tmp_utils_src}" ]; do # resolve ${__bshbp_tmp_utils_src} until the file is no longer a symlink
  __bshbp_tmp_utils_src_dir="$( cd -P "$( dirname "${__bshbp_tmp_utils_src}" )" && pwd )"
  __bshbp_tmp_utils_src="$(readlink "${__bshbp_tmp_utils_src}")"
  # if ${__bshbp_tmp_utils_src} was a relative symlink, we need to resolve it relative to the path where the symlink file was located
  [[ ${__bshbp_tmp_utils_src} != /* ]] && __bshbp_tmp_utils_src="${__bshbp_tmp_utils_src_dir}/${__bshbp_tmp_utils_src}" 

done
__bshbp_tmp_utils_src_path="$( cd -P "$( dirname "${__bshbp_tmp_utils_src}" )" && pwd )"

if [ ! -d "${__bshbp_tmp_utils_src_path}" ]
then
  emergency "Failed to find library files expected in: ${__bshbp_tmp_utils_src_path}"
fi

for __bshbp_tmp_utility_file in "${__bshbp_tmp_utils_src_path}"/*.sh
do
  if [ -e "${__bshbp_tmp_utility_file}" ]; then
    # Don't source self
    if [[ "${__bshbp_tmp_utility_file}" == *"utils.sh"* ]]; then
      continue
    fi
    source "$__bshbp_tmp_utility_file"
  fi
done







# Print information before exit
function __thats_all_folks () {
  ### Before exit print the legend information
  ##############################################################################
  # All of these go to STDERR, so you can use STDOUT for piping machine readable information to other software
  #info "$(echo -e "multiple lines example - line #1\nmultiple lines example - line #2\nimagine logging the output of 'ls -al /path/'")"
  echo -e "\n\n### Syslog Severity levels Logging : Legend Information" 1>&2
  echo "##############################################################################" 1>&2
  echo "# -----------------------------------" 1>&2
  debug "# Info useful to developers for debugging the application, not useful during operations." 1>&2
  
  info "# Normal operational messages - may be harvested for reporting, measuring throughput\
        , etc. - no action required." 1>&2
		
  notice "# Events that are unusual but not error conditions - might be summarized in an email \
  to developers or admins to spot potential problems - no immediate action required." 1>&2
  
  warning "# Warning messages, not an error, but indication that an error will occur if action \
  is not taken, e.g. file system 85% full - each item must be resolved within a given time. This is a debug message" 1>&2
  
  error "# Non-urgent failures, these should be relayed to developers or admins; \
  each item must be resolved within a given time." 1>&2
  
  critical "# Should be corrected immediately, but indicates failure in a primary system, \
  an example is a loss of a backup ISP connection." 1>&2
  
  alert "# Should be corrected immediately, therefore notify staff who can fix the problem. \
  An example would be the loss of a primary ISP connection." 1>&2
  
  emergency "# A \"panic\" condition usually affecting multiple apps/servers/sites. \
  At this level it would usually notify all tech staff on call." 1>&2
}


### Cleanup Temp Environment variables
##############################################################################
# ------------------------------------------------------
# This must always be the last section in the utils.sh file
# ------------------------------------------------------

#cleanup all the tmpenv variables from the environment
for __tmp_varname in ${!__bshbp_tmp_*}; do
  debug "Variable : ${__tmp_varname} cleared from the env"
  unset -v "${__tmp_varname}"
done

unset -v __tmp_varname
