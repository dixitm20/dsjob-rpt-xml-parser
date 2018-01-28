#!/usr/bin/env bash

# Variable naming convention
# 1) All variables which begin with __ (double underscores) are special variables but these are not added to runtime env
#           Those which are in small case after the __ are spcial varibles used by the framework.
#           Those which are in UPPERCASE after the underscore are varibles specific to the current script.   
# 2) All vairables which are in UPPERCASE will be added to the runtime env file and can be utilized in the config files.



# Exit on error. Append "|| true" if you expect an error.
set -o errexit
# Exit on error inside any functions or subshells.
set -o errtrace
# Do not allow use of undefined vars. Use ${VAR:-} to use an undefined VAR
set -o nounset
# Catch the error in case mysqldump fails (but gzip succeeds) in `mysqldump |gzip`
set -o pipefail
# Turn on traces, useful while debugging but commented out by default
# set -o xtrace


if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
  __i_am_main_script="0" # false
else
  __i_am_main_script="1" # true
fi


# Set magic variables for current file, directory, os, etc.
__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
__parentdir="$(dirname "${__dir}")"
__file="${__dir}/$(basename "${BASH_SOURCE[0]}")"
__base="$(basename "${__file}" .sh)"
__utilsLocation="${__parentdir}/lib/utils.sh" # Update this path to find the utilities.

### Below variables will be added to the runtime env file
##############################################################################
	UNQID="UNQID_$(date '+%Y%m%d%H%M%S').$$.$RANDOM"
	
	PROCESS_START_TIME="$(date -u +"%Y-%m-%d %H:%M:%S")"
	
	# PROCESS_END_TIME will be updated in the env file by the trap function
	PROCESS_END_TIME=""
	
	PROCESS_ID="$$"
	
	# This variable will be set after the log dir derivation is completed
	RUNTIME_ENV_FILE=""
	
	# LAST_KNOWN_PROCESS_STATUS can be updated as checkpoints in the below script.
	# As this variable will be reported to runtime env file and can be used to
	# know the last known status in case the process fails in between
	LAST_KNOWN_PROCESS_STATUS="BEGIN PROCESS"
	
	# IS_PROCESS_COMPLETED_SUCCESSFULLY should be set to true in the last line of the current script only
	IS_PROCESS_COMPLETED_SUCCESSFULLY="FALSE"
##############################################################################


# Script Driver Parameters
__ENABLE_DEBUG_MODE="FALSE"
__INPUT_PARAM_LIST=""
# The parameters for which a value is set are optional parameters. If the value
# of the optional parameters is not passed then a default value is used for those
# paramters. All the expected paramters will be added to the runtime env file
# and can be used in config files directly.
__EXPECTED_PARAM_LIST="(APP_NAME,TBL_UNIQ_IDNTFR,TMP_DIR=NULL,LOG_DIR=NULL,ENV_FILE=NULL,\
                      APP_METADATA_CONFIG_FILE=NULL,ENABLE_DEBUG_MODE=${ENABLE_DEBUG_MODE:-FALSE},\
					  LOG_RETENTION_DAY_COUNT=90)"


					  
# Define the environment variables (and their defaults) that this script depends on
__LOG_LEVEL="${__LOG_LEVEL:-6}" # 7 = debug -> 0 = emergency
__NO_COLOR="${NO_COLOR:-}"    # true = disable color. otherwise autodetected
__INDENT="|"


# Set Usage Information
[[ "${__usage+x}" ]] || read -r -d '' __usage <<-'EOF' || true # exits non-zero when EOF encountered
-------------------
## USAGE: ##
-------------------

  ${__base} -p "( p1=v1,p2=v2...)"    : Run In Regular Mode
  ${__base} -d -p "( p1=v1,p2=v2...)" : Run In Debug Mode
  ${__base} -h | --help               : Show Usage Help

-------------------
## DESCRIPTION: ##
-------------------

  -h   Show Usage Help.
       
  -d   Run Script In Debug Mode.
       
  -p   Pass Parameters In The Format "( p1=v1,p2=v2...)"
       
       ----------------
       Required Params: "(APP_NAME=<<APP_NAME>>,TBL_UNIQ_IDNTFR=<<TBL_UNIQ_IDNTFR>>)"
       ----------------
       
           Without the value of the below required parameters the script will fail.
               1) APP_NAME :    Required Parameter
                                DESCRIPTION: Name of the application
                                
               2) TBL_UNIQ_IDNTFR : Required Parameter
                                DESCRIPTION: Name of the TBL_UNIQ_IDNTFR which will be processed.
                                
           EXAMPLE: ${__base} -p "(APP_NAME=TEST,TBL_UNIQ_IDNTFR=TEST)"
       
       ---------------- 
       Optional Params: "( TMP_DIR=<<TMP_DIR>> , LOG_DIR=<<LOG_DIR>> , 
                           CONFIG_DIR=<<CONFIG_DIR>> , ENV_FILE=<<ENV_FILE>>,
                           APP_METADATA_CONFIG_FILE=<<APP_METADATA_CONFIG_FILE>>, 
                           ENABLE_DEBUG_MODE=<<ENABLE_DEBUG_MODE>>,
                           LOG_RETENTION_DAY_COUNT=<<LOG_RETENTION_DAY_COUNT>> )"     
       ----------------
       
           Optional parameters May or May not be passed to the script. 
           If the Optional paramters are not passed to the script then
           they use the Default values as shown below:
       
               1) TMP_DIR : 
                  Default= " ## ${__parentdir}/tmp/${__base}.<<APP_NAME>>.
                             <<TBL_UNIQ_IDNTFR>>.\$RANDOM.\$RANDOM.\$RANDOM.\$\$ ## "
                  Description : "Directory in which temp files will be created"
               
               2) LOG_DIR :
                  Default= " ## ${__parentdir}/log/<<APP_NAME>>/<<TBL_UNIQ_IDNTFR>> ## " 
                  Description : "Directory in which all the log files will be generated"
                            
                               
               3) ENV_FILE : 
                  Default= " ## ${__parentdir}/config/<<APP_NAME>>/APP_ENV ## "
                  Description : "Path of the environment file containing APP level constants.
                  The directory in this path is also supposed to have a .include file for storing
                  credentials information."
                             
               4) APP_METADATA_CONFIG_FILE : 
                  Default= " ## ${__parentdir}/config/<<APP_NAME>>/APP_METADATA_CONFIG ## "
                  Description : "Path of the config file containing config details to connect 
                                 to the Metadata tables"
               
               5) ENABLE_DEBUG_MODE : 
                  Default= " ## FALSE ## "
                  Description : "This flag will decide if the the script will run in debug 
                                 mode or not.  Only accepts TRUE/FALSE value"
               
               6) LOG_RETENTION_DAY_COUNT : 
                  Default= " ## 90  ## "
                  Description : "Number of days the logs will be retained. All log files older 
                                 than this value will be purged"
EOF
	

# Set Helptext Information
[[ "${__helptext+x}" ]] || read -r -d '' __helptext <<-'EOF' || true # exits non-zero when EOF encountered
Script for archiving the data from given table to Hive table and then purge that data from that Table.
EOF



### Source Scripting Utilities
##############################################################################
# These shared utilities provide many functions which are needed to provide
# the functionality in this boilerplate. This script will fail if they can
# not be found.
# -----------------------------------
	if [ -f "${__utilsLocation}" ]; then
	  source "${__utilsLocation}"
	else
	  echo "Please find the file util.sh and add a reference to it in this script. Exiting."
	  exit 1
	fi
##############################################################################

# Exit if the script has not been called directly and an attempt has been made to source this script
[[ "${__i_am_main_script}" = "0" ]] && emergency "Cannot continue as the script is not used directly "\
"(it is being sourced). The script should always be executed independently it its own subshell. Usage: sh my_script"

# Unset the variable as it is no longer needed
unset -v __i_am_main_script

	
### Parse input arguments
##############################################################################	
	while getopts :p:hd opt
	do
			case $opt in
			  p) __INPUT_PARAM_LIST=$OPTARG;;
			  d) __ENABLE_DEBUG_MODE=TRUE;;
			  h) help "Help Using ${__base} : ";;
			  *) help "Incorrect Usage Of The Script!! Exiting.";;
			esac
	done

	# Check if required -p paramter is passed
	if [[ -z ${__INPUT_PARAM_LIST:-} ]];
	then
		help "Cannot Continue Without Parameter List"; 
	fi

	shift $(($OPTIND -1))

	# Verify that there are no unnecessary parameters passed to the script
	if [[ ! -z ${1:-} ]];
	then
		help "Incorrect Usage Of The Script!! Exiting."
	fi

##############################################################################


### Command-line argument switches (like -d for debugmode)
##############################################################################

	# debug mode
	if [[ "${__ENABLE_DEBUG_MODE}" == "TRUE" ]]; then
	  set -o xtrace
	  __LOG_LEVEL=7
	  # Enable error backtracing
	  trap '__bshbp_err_report "${FUNCNAME:-.}" ${LINENO}' ERR
	fi

##############################################################################


debug "################## BEGIN SCRIPT: ${__base}  ##################"
__INDENT="${__INDENT}\t|"
	  
__this="${__file} ${__INPUT_PARAM_LIST}"

getParameters "${__INPUT_PARAM_LIST}" "${__EXPECTED_PARAM_LIST}" "${__this}"


### Set default values and validate the param values
##############################################################################
	[[ "${TMP_DIR}" == "NULL" ]] && TMP_DIR="${__parentdir}/tmp/${__base}.${APP_NAME}.${TBL_UNIQ_IDNTFR}.$RANDOM.$RANDOM.$RANDOM.$$"
	(umask 077 && mkdir "${TMP_DIR}") || help "Could not create temporary directory! Exiting."


	[[ "${LOG_DIR}" == "NULL" ]] && LOG_DIR="${__parentdir}/log/${APP_NAME}/${TBL_UNIQ_IDNTFR}"
	[[ ! -d "${LOG_DIR}" ]] &&  mkdir -p "${LOG_DIR}"
	[[ ! -d "${LOG_DIR}" ]] &&  help "Could not create log directory! Exiting."

	# Commented below part as config will be read from config table
	# [[ "${CONFIG_DIR}" == "NULL" ]] && CONFIG_DIR="${__parentdir}/config/${APP_NAME}"
	# CONFIG_FILE="${CONFIG_DIR}/${TBL_UNIQ_IDNTFR}.config"
	# [[ -f "${CONFIG_FILE}" ]]	 || help "Config file does not exists in path ## ${CONFIG_FILE} ##! Exiting."


	[[ "${ENV_FILE}" == "NULL" ]] && ENV_FILE="${__parentdir}/config/${APP_NAME}/APP_ENV"
	[[ -f "${ENV_FILE}" ]]	|| help "Env file does not exists in path ## ${ENV_FILE} ##! Exiting."
	ENV_DIR="$(echo "$(dirname "${ENV_FILE}")")"
	INCLUDE_FILE="${ENV_DIR}/.include"
	[[ -f "${INCLUDE_FILE}" ]]	 || help "Expected .include file does not exists in path ## ${INCLUDE_FILE} ##! Exiting."


	[[ "${APP_METADATA_CONFIG_FILE}" == "NULL" ]] && APP_METADATA_CONFIG_FILE="${__parentdir}/config/${APP_NAME}/APP_METADATA_CONFIG"
	[[ -f "${APP_METADATA_CONFIG_FILE}" ]]	 || help "App Metadata Config file does not exists in path ## ${APP_METADATA_CONFIG_FILE} ##! Exiting."


	[[ "${__LOG_LEVEL:-}" ]] || emergency "Cannot continue without __LOG_LEVEL."

	

##############################################################################


### Add variables to the runtime env file 
##############################################################################
RUNTIME_ENV_FILE=$(getRuntimeEnvFile "(logdir=${LOG_DIR},unqid=${UNQID})")

# All __EXPECTED_PARAM_LIST & CONFIG_FILE , INCLUDE_FILE , UNQID , PROCESS_START_TIME , PROCESS_ID , RUNTIME_ENV_FILE wil be added to runtie env file
# __EXPECTED_PARAM_LIST= APP_NAME  ,  TBL_UNIQ_IDNTFR  ,  TMP_DIR  ,  LOG_DIR  ,  CONFIG_DIR  ,  ENV_FILE  ,  APP_METADATA_CONFIG_FILE  ,  ENABLE_DEBUG_MODE  ,  LOG_RETENTION_DAY_COUNT

runtimeEnvVarlist=$(echo "${__EXPECTED_PARAM_LIST}" | sed -e 's/)$/, INCLUDE_FILE  ,  UNQID  ,  PROCESS_START_TIME  ,  PROCESS_ID  ,  RUNTIME_ENV_FILE)/1')

printEnvParameters "${runtimeEnvVarlist}" "${__this}" "${LOG_DIR}" "${UNQID}" "TRUE"

##############################################################################





### Signal trapping and back tracing
##############################################################################

function __bshbp_cleanup_before_exit () {
  
	echo -e "\n\n" 2>&1
	__INDENT="${__INDENT}\t|"
	notice "################### BEGIN CLEANUP : ${__base}  ###################"
	
	[[ -d "${TMP_DIR}" ]] &&  rm -r "${TMP_DIR}"
	warning "Tmp Directory: ## ${TMP_DIR} ## Cleaning up. Done"
	
	find "${LOG_DIR}" -mindepth 1 -type f -mtime +"${LOG_RETENTION_DAY_COUNT}" -exec rm {} \;
	warning "Purged log older than ## ${LOG_RETENTION_DAY_COUNT} ## days from log dir: ## ${LOG_DIR} ##"
	
	### Add variables to the runtime env file 
	##############################################################################
		PROCESS_END_TIME="$(date -u +"%Y-%m-%d %H:%M:%S")"
			
		runtimeEnvVarlist='(LAST_KNOWN_PROCESS_STATUS,IS_PROCESS_COMPLETED_SUCCESSFULLY,PROCESS_END_TIME)'
		
		printEnvParameters "${runtimeEnvVarlist}" "${__this}" "${LOG_DIR}" "${UNQID}" "TRUE"
	##############################################################################
	
	__INDENT="${__INDENT::-3}"
	notice "################### END CLEANUP : ${__base}  ###################"
}

trap __bshbp_cleanup_before_exit EXIT

# requires `set -o errtrace`
__bshbp_err_report() {
    local error_code
    error_code=${?}
    error "Error in ${__file} in function ${1} on line ${2}"
    exit ${error_code}
}
# Uncomment the following line for always providing an error backtrace
# trap '__bshbp_err_report "${FUNCNAME:-.}" ${LINENO}' ERR

##############################################################################



#### Main
###############################################################################
## -----------------------------------
## Write your script logic here
## -----------------------------------
#

tets=$(loadConfigToRuntimeEnv "(configfile=${APP_METADATA_CONFIG_FILE},envfile=${ENV_FILE},tmpdir=${TMP_DIR},logdir=${LOG_DIR},unqid=${UNQID})")



__INDENT="${__INDENT::-3}"
LAST_KNOWN_PROCESS_STATUS="PROCESS_COMPLETED_SUCCESSFULLY"
IS_PROCESS_COMPLETED_SUCCESSFULLY="TRUE"
debug "################### END SCRIPT: ${__base}  ###################\n\n"
__thats_all_folks

###############################################################################





# TEMP REF BELOW
#
## Validations
## -----------------------------------
##[[ "${arg_f:-}" ]]     || help      "Setting a filename with -f or --file is required"
#
#[[ "${__LOG_LEVEL:-}" ]] || emergency "Cannot continue without __LOG_LEVEL."
#
#
#currentConfigfiePath="${arg_d}/${arg_c}.config"
#
#envdir="$(echo "$(dirname "${arg_e}")")"
#includeFile="${envdir}/.include"
## Check if the paramfile exists
#
#[[ -f "${arg_e}" ]]     || emergency "Env file does not exists in path ## ${arg_e} ##! Exiting."
#[[ -f "${includeFile}" ]]     || emergency "Expected .include file does not exists in path ## ${includeFile} ##! Exiting."
#[[ -f "${arg_p}" ]]     || emergency "App Metadata Config file does not exists in path ## ${arg_p} ##! Exiting."
#[[ -f "${currentConfigfiePath}" ]]     || emergency "Config file does not exists in path ## ${currentConfigfiePath} ##! Exiting."
#
## Create log directories if they do not exist
#[[ ! -d "${arg_l}" ]] &&  mkdir -p "${arg_l}"
#[[ ! -d "${arg_j}" ]] &&  mkdir -p "${arg_j}"
#
#
## Create temp directory
#(umask 077 && mkdir "${arg_t}") || emergency "Could not create temporary directory! Exiting."
## -----------------------------------
#
#
## Save current IFS
#SAVEIFS=${IFS} 
#
#
## Change IFS to new line. 
#IFS=$'\n'
#
#
##read xml file in an array
#declare -a input_src_file
#
#
#
##input_src_file=( $(cat ${arg_f} | sed '
#                    #Ignore comments from input xml file
#                    #/\s*<!--.*-->/d
#                    #Ignore empty lines from input xml file
#                    #/^\s*$/d
#                    #Rtrim each line - Replace whitespace from each line end
#                    #s/\s*$//1
#                    #Replace all indentation tabs with 3 spaces
#                    #:loop;s/\t\(.*<\)/   \1/1;tloop') );
#
#                    
## Restore IFS
#IFS=${SAVEIFS}
#
##echo "${input_src_file[7]}"
#
#runtimeenvfile=$(appendToRuntimeEnvFile "(attribName=UNQID  ,  attribValue=${__uid},logdir=${arg_l},uid=${uid})")
#
#
#
## EXEC_SCALAR=$( sqoopExecScalar "(query=SELECT CAST(MAX(LOG_DT) AS FORMAT 'YYYY-MM-DD') \
##               AS MAX_LOG_DT FROM PURGE_QUE_TBL  ,  configName=APP_METADATA_CONFIG  ,   \
##               envfile=${arg_c},tmpdir=${arg_t},logdir=${arg_l},uid=${__uid})" )
#
## EXEC_QUERY=$( sqoopExecQuery "(query=SELECT * FROM PURGE_QUE_TBL  ,  configName=APP_METADATA_CONFIG  ,  envfile=${arg_c},tmpdir=${arg_t},logdir=${arg_l},uid=${__uid})" )
#
##EXEC_RESOLVE_ATTRIB=$( configAttribResolver "(attribName=WHERE_CLAUSE_DERIVATION_QUERY  ,  configName=APP_METADATA_CONFIG  ,  envfile=${arg_c},runtimeconfigfile=/home/dixitm/PROJECT/PURGE/config/TEST/temp.conf  ,  tmpdir=${arg_t},logdir=${arg_l},uid=${__uid})" )
#
##EXEC_NONQUERY=$( sqoopExecNonQuery "(query=UPDATE PURGE_QUE_TBL SET DB_NM='TM901',configName=APP_METADATA_CONFIG  ,  envfile=${arg_c},tmpdir=${arg_t},logdir=${arg_l},uid=${__uid})" )
#
##CYCLE_ID=$( beginCycleForApp "(appname=${arg_a},configfile=${arg_c},tmpdir=${arg_t},logdir=${arg_l},uid=${__uid})" )
#
##notice "${CYCLE_ID} row(s) affected"
#
##ReadConfig=$(genParamStringFromConfig "( configName=TEST3~configfile=${arg_c}~outdelim=, ):delim='~';" )
#
##outfile=$( tdSqoopExecQuery "(query=SELECT Q.* FROM PURGE_QUE_TBL Q   ,  PURGE_RUL_TBL R WHERE Q.LOG_DT=TO_DATE('${MAX_LOG_DT}') AND Q.TBL_NM = R.TBL_NM AND R.ACTV_ROW_IND = 1 AND R.HDP_ACTV_ROW_IND = 1|configName=PUR_HDP_PURGE_QUE_TBL|configfile=${arg_c}|tmpdir=${arg_t}|logdir=${arg_l}|uid=${__uid}):delim='|';" );
#
#
#
##cat $outfile
#
##notice "${EXEC_NONQUERY}"
#
#runtimeEnvfile=$(appendToRuntimeEnvFile "(attribName=cycle_id  ,  attribValue=10  ,  logdir=${arg_l},uid=${__uid})")
#
#
#EXEC_QUERY=$( sqoopExecScalar4ConfigAttrib "(attribName=WHERE_CLAUSE_DERIVATION_QUERY  ,  configName=APP_METADATA_CONFIG  ,  envfile=${arg_c},tmpdir=${arg_t},logdir=${arg_l},uid=${__uid})" )
#
#
#
#notice "${runtimeEnvfile}"
#
#
### Before exit print info
# -----------------------------------


