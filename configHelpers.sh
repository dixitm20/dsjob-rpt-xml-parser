#!/usr/bin/env bash


# ReadConfig=$(genConfigParamString "( configName=TEST3~configfile=${arg_c}~outdelim=, ):delim='~';" )
function genConfigParamString()
{

	local __expectedParam='(configfile,envfile,runtimeconfigfile=NULL,logdir,unqid,outdelim)'
	local __this="${FUNCNAME[0]} ${1}"
	local __fnName="${FUNCNAME[0]}"
	local __outValue=""
	
	debug "################## BEGIN FUNCTION: ${__fnName}  ##################"
	__INDENT="${__INDENT}\t|"
	
	
	# Extract param values from input arguments
	getParameters "${1}" "${__expectedParam}" "${__this}"
	
	local envdir="$(echo "$(dirname "${envfile}")")"
	
	# Files which are combined to form the configuration parameter string
	local includeFile="${envdir}/.include"
	[[ -f "${includeFile}" ]] || emergency "Expected .include file does not exists in path ${includeFile}! Exiting."
	debug "includeFile = ${includeFile};"
	
	local appEnvFile="${envfile}"
	[[ -f "${envfile}" ]] || emergency "App env file does not exists in path ${envfile}! Exiting."
	debug "appEnvFile = ${appEnvFile};"
	

	[[ -f "${configfile}" ]] || emergency "Config file does not exists in path ${configfile}! Exiting."
	debug "configfile = ${configfile};"
	
	local runtimeenvfile=$(getRuntimeEnvFile "(logdir=${logdir},unqid=${unqid})")
	
	declare -A varValueList
	local paramString="( "
	local configVarValueList=""
	
	if [[ "${runtimeconfigfile}" != "NULL" ]]; then
		[[ -f "${runtimeconfigfile}" ]] || emergency "Required Runtime Config file does not exists in path ${runtimeconfigfile}! Exiting."
		
		debug "runtimeconfigfile = ${runtimeconfigfile};"
		
		# If runtime config file is supplied then use the below expression
		configVarValueList="$(sed -e '$s/$/\n/' -s "${includeFile}" "${appEnvFile}" "${configfile}" "${runtimeenvfile}" "${runtimeconfigfile}"  | sed  -e '/^\s*$/d' -e '/^\s*#/d' | \
	                         awk " BEGIN { RS=\"\n\"; FS=\"=\"; OFS=\" \" } { print \$1,substr(\$0,length(\$1)+2) } " | sed -e 's/^\s*//g' -e 's/\s*$//g')"
	else
		runtimeconfigfile=""
		debug "runtimeconfigfile = ${runtimeconfigfile};"
		
		# If runtime config file is not supplied then use the below expression
		configVarValueList="$(sed -e '$s/$/\n/' -s "${includeFile}" "${appEnvFile}" "${configfile}" "${runtimeenvfile}" | sed  -e '/^\s*$/d' -e '/^\s*#/d' | \
	                         awk " BEGIN { RS=\"\n\"; FS=\"=\"; OFS=\" \" } { print \$1,substr(\$0,length(\$1)+2) } " | sed -e 's/^\s*//g' -e 's/\s*$//g')"
	fi 
		

	# debug "configVarValueList : ${configVarValueList}"
	
	
	while
	read -r paramName paramValue
	do
		paramName=$(echo "${paramName}" | sed -e 's/^\s*//g' -e 's/\s*$//g')
		paramValue=$(echo "${paramValue}" | sed -e 's/^\s*//g' -e 's/\s*$//g')
		
		varValueList["${paramName}"]="${paramValue}"
	
	done <<< "$(echo "${configVarValueList}")"
	

	
	for paramName in "${!varValueList[@]}"
	do
		local paramValue="${varValueList[${paramName}]}"
		
		paramString="${paramString} ${paramName}=${paramValue} ${outdelim}"
		
		[[ "${paramName}" =~ .*PWD$ ]] && paramValue="XXXXXX";
		debug "${paramName} = ${paramValue};"
	
	done
	
	
	# Remove last extra delimiter and add the last delim part (:delim'<<x>>';)) to the end
	paramString="$(echo "${paramString}" | sed "s/${outdelim}$/):delim='${outdelim}';/1" )"
	__outValue="${paramString}"
	
	paramString="$( echo "${paramString}" | sed "s/PWD=[^${outdelim}]*/PWD=XXXXXX /g" )"
	debug "${paramString}" 
	
	clearParameters "${__expectedParam}" "${__this}"
	
	echo "${__outValue}"
	
	__INDENT="${__INDENT::-3}"
	debug "################### END FUNCTION: ${__fnName}  ###################\n\n"
	
	
}


# Convert the input string : "TEST PASSWORD ENCRYPTION : [PWD:#passwordmcmcm#:] FOR GIVEN PASSWORD"
# To: "TEST PASSWORD ENCRPTION : XXXXXX FOR GIVEN PASSWORD"
function encryptPWDtags()
{
	local __expectedParam='(inputString)'
	local __this="${FUNCNAME[0]} ${1}"
	local __fnName="${FUNCNAME[0]}"
	local __outValue=""
	
	debug "################## BEGIN FUNCTION: ${__fnName}  ##################"
	__INDENT="${__INDENT}\t|"
	
	# Extract expected param values from input arguments
	getParameters "${1}" "${__expectedParam}" "${__this}"
	
	# Convert the input string : "TEST PASSWORD ENCRYPTION : [PWD:#passwordmcmcm#:] FOR GIVEN PASSWORD"
	# To: "TEST PASSWORD ENCRPTION : XXXXXX FOR GIVEN PASSWORD"
	
	__outValue=$( echo "${inputString}" | awk 'BEGIN { RS="\\[PWD:#"} {print $0}' | \
	sed 's/^.*#:]/XXXXXX/1' | sed '/^$/d' | awk 'BEGIN {ORS=""} {print $0} ')
	
	
	__INDENT="${__INDENT::-3}"
	debug "################### END FUNCTION: ${__fnName}  ###################\n\n"	
	
	echo "${__outValue}"
}


# Convert the input string : "TEST PASSWORD ENCRYPTION : [PWD:#passwordmcmcm#:] FOR GIVEN PASSWORD"
# To: "TEST PASSWORD ENCRPTION : passwordmcmcm FOR GIVEN PASSWORD"
function removePWDtags()
{
	local __expectedParam='(inputString)'
	local __this="${FUNCNAME[0]} ${1}"
	local __fnName="${FUNCNAME[0]}"
	local __outValue=""
	
	debug "################## BEGIN FUNCTION: ${__fnName}  ##################"
	__INDENT="${__INDENT}\t|"
	
	# Extract expected param values from input arguments
	getParameters "${1}" "${__expectedParam}" "${__this}"

	# Convert the input string : "TEST PASSWORD ENCRYPTION : [PWD:#passwordmcmcm#:] FOR GIVEN PASSWORD"
	# To: "TEST PASSWORD ENCRPTION : passwordmcmcm FOR GIVEN PASSWORD"
	__outValue=$( echo "${inputString}"  | awk 'BEGIN { RS="\\[PWD:#"} {print $0}' | \
	sed 's/^\(.*\)#:]/\1/1' | sed '/^$/d' | awk 'BEGIN {ORS=""} {print $0}' )	
	
	
	__INDENT="${__INDENT::-3}"
	debug "################### END FUNCTION: ${__fnName}  ###################\n\n"	
	
	echo "${__outValue}"
	
}


function configAttribResolver()
{
	local __expectedParam='(attribName,configfile,envfile,runtimeconfigfile=NULL,tmpdir,logdir,unqid)'
	local __this="${FUNCNAME[0]} ${1}"
	local __fnName="${FUNCNAME[0]}"
	local __outValue=""
	
	debug "################## BEGIN FUNCTION: ${__fnName}  ##################"
	
	__INDENT="${__INDENT}\t|"
	
	# Extract expected param values from input arguments
	getParameters "${1}" "${__expectedParam}" "${__this}"
	
	local configExpectedParam="(${attribName})"
	local configParamString=$(genConfigParamString "( configfile=${configfile},envfile=${envfile},runtimeconfigfile=${runtimeconfigfile}, logdir=${logdir},unqid=${unqid},outdelim=#@# ):delim=',';" )
	
	# Get the value of the sqoop scalar commmand
	getParameters "${configParamString}" "${configExpectedParam}" "${__this}"
	
	
	# get the list of variables used in the sqoop command and read thier values from config as well.
	# example: SQOOP_EXEC_SCALAR_COMMAND="select ${a} from ${b}" will return : ( a,b )
	local configRequiredParam=$( echo $(echo ${!attribName} | \
	awk 'BEGIN{ RS="[\\$}]"} {print $0}' | grep '^{' | sed 's/^{//1') | \
	awk 'BEGIN { print "("; } {gsub(/ /,",");print;} END { print ")"; }' | tr '\n' ' ');
	
	getParameters "${configParamString}" "${configRequiredParam}" "${__this}"
	
	local resolvedAttribVal=$(eval "echo "${!attribName}"")
	
	debug "resolvedAttribVal=${resolvedAttribVal}"
	
	clearParameters "${configRequiredParam}" "${__this}"
	clearParameters "${configExpectedParam}" "${__this}"
	clearParameters "${__expectedParam}" "${__this}"
	
	__outValue="${resolvedAttribVal}"
	
	__INDENT="${__INDENT::-3}"
	debug "################### END FUNCTION: ${__fnName}  ###################\n\n"	
	
	echo "${__outValue}"
}


function getRuntimeEnvFile()
{
	local __expectedParam='(logdir,unqid,filePostfix=NULL,fileExtsn=env)'
	local __this="${FUNCNAME[0]} ${1}"
	local __fnName="${FUNCNAME[0]}"
	local __outValue=""
	
	debug "################## BEGIN FUNCTION: ${__fnName}  ##################"
	__INDENT="${__INDENT}\t|"
	
	# Extract expected param values from input arguments
	getParameters "${1}" "${__expectedParam}" "${__this}"
	
	local runtimeenvfilename=""

	if [[ "${filePostfix}" == "NULL" ]]; then
		runtimeenvfilename="${logdir}/${unqid}.${fileExtsn}"
	else
		runtimeenvfilename="${logdir}/${unqid}-${filePostfix}.${fileExtsn}"
	fi

	debug "runtimeenvfilename=${runtimeenvfilename}"
	
	touch "${runtimeenvfilename}"

	clearParameters "${__expectedParam}" "${__this}",
	
	__outValue="${runtimeenvfilename}"
	
	__INDENT="${__INDENT::-3}"
	debug "################### END FUNCTION: ${__fnName}  ###################\n\n"	
	
	echo "${__outValue}"
}


function getLogFile()
{
	local __expectedParam="(logdir,unqid,filePostfix=NULL,fileExtsn=log)"
	local __this="${FUNCNAME[0]} ${1}"
	local __fnName="${FUNCNAME[0]}"
	local __outValue=""
	
	debug "################## BEGIN FUNCTION: ${__fnName}  ##################"
	__INDENT="${__INDENT}\t|"
	
	# Extract expected param values from input arguments
	getParameters "${1}" "${__expectedParam}" "${__this}"
	
	local logfilename=""
	
	if [[ "${filePostfix}" == "NULL" ]]; then
		logfilename="${logdir}/${unqid}.${fileExtsn}"
	else
		logfilename="${logdir}/${unqid}-${filePostfix}.${fileExtsn}"
	fi

	debug "logfilename=${logfilename}"
	touch "${logfilename}"
	
	clearParameters "${__expectedParam}" "${__this}",
	
	__outValue="${logfilename}"
	
	__INDENT="${__INDENT::-3}"
	debug "################### END FUNCTION: ${__fnName}  ###################\n\n"	
	
	echo "${__outValue}"
}


function genNewTmpFile()
{
	local __expectedParam="(tmpdir,unqid,filePostfix=NULL,fileExtsn=tmp)"
	local __this="${FUNCNAME[0]} ${1}"
	local __fnName="${FUNCNAME[0]}"
	local __outValue=""
	
	debug "################## BEGIN FUNCTION: ${__fnName}  ##################"
	__INDENT="${__INDENT}\t|"
	
	# Extract expected param values from input arguments
	getParameters "${1}" "${__expectedParam}" "${__this}"
	
	local tmpfilename=""
	
	if [[ "${filePostfix}" == "NULL" ]]; then
		tmpfilename="${tmpdir}/${unqid}-$(date '+%Y%m%d%H%M%S').$RANDOM.$RANDOM.${fileExtsn}"
	else
		tmpfilename="${tmpdir}/${unqid}-${filePostfix}-$(date '+%Y%m%d%H%M%S').$RANDOM.$RANDOM.${fileExtsn}"
	fi

	debug "tmpfilename=${tmpfilename}"
	touch "${tmpfilename}"
	
	clearParameters "${__expectedParam}" "${__this}",
	
	__outValue="${tmpfilename}"
	
	__INDENT="${__INDENT::-3}"
	debug "################### END FUNCTION: ${__fnName}  ###################\n\n"	
	
	echo "${__outValue}"
}


# Run this function in subshell to avoid runtime errors related to unbound variables
function appendToRuntimeEnvFile()
{
	local __expectedParam='(attribName,attribValue,logdir,unqid)'
	local __this="${FUNCNAME[0]} ${1}"
	local __fnName="${FUNCNAME[0]}"
	local __outValue=""
	
	debug "################## BEGIN FUNCTION: ${__fnName}  ##################"
	__INDENT="${__INDENT}\t|"
	
	# Extract expected param values from input arguments
	getParameters "${1}" "${__expectedParam}" "${__this}"
	
	local runtimeenvfile=$(getRuntimeEnvFile "(logdir=${logdir},unqid=${unqid})")
	
	debug "VALUE_OF_${attribName}=${attribValue}"
	echo "VALUE_OF_${attribName}=${attribValue}" >> ${runtimeenvfile}
	
	clearParameters "${__expectedParam}" "${__this}"
	
	__outValue="${runtimeenvfile}"
	
	__INDENT="${__INDENT::-3}"
	debug "################### END FUNCTION: ${__fnName}  ###################\n\n"	
	
	echo "${__outValue}"


}
