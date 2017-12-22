### Function Parameter Pass Helpers
##############################################################################
# -----------------------------------
# Below function takes as input passed arguments to the parent function and generates
# shell variables with appropriate names, assigns them values, which can then be used inside
# the parent function. The user must ensure that delimiter used in either the input parameter string 
# Or in the expected parameter list is not part of any parameter name or value. The default delimiter
# is comma.
#
# Usage: getParameters {Input parameters to the function} {Expected Param List} {Parent Function Name}
#
# {Input parameters to the function} : The input argument passed to the function in the form of
#                                      "(arg1=val1,arg2=val2,arg3=$(pwd)):delim=',';". The user 
#                                      must ensure that the delimiter is not present in any value.
#                                      Unix commands can be passed as : $(Unix Command).
# {Expected Param List} : The list consists of the expected parameters by the function and only these set of 
#                         variables are added to the shell (rest all other argument in tthe Input param string are ignored).
#                         If the user wants to make a argument optional then he can do that by assigning a default
#                         for that argument in the expected argument list. e.g "(arg1,arg2=val2,arg3):delim=',';" , Here
#                         arg2 is optional.
#
# {Parent Function Name} : Name of the caller function
#
# Usage examples: getParameters "(arg1=val1,arg3=$(pwd)):delim=',';"  "(arg1,arg3):delim=',';" "CallerFunction"
# function CallerFunction()
# {
# 	
# 	local __expectedParam="(arg1,arg2=44,arg3=123)"
# 	local __this=${FUNCNAME[0]}
# 	
# 	# Extract param values from input arguments
# 	getParameters ${1} ${__expectedParam} ${__this}
# 	
# 	# Function Logic Below
# 	
# 	# Clear argument variables from the environment
# 	clearParameters ${1} ${__expectedParam} ${__this}
# 
# }
# -----------------------------------

function getParameters()
{

	# ltrim & rtrim the input command and assigning to local variable
	# e.g for input : "   (arg1=val1,arg2=val2,arg3=val3):delim=',';    "
	# return : "(arg1=val1,arg2=val2,arg3=val3):delim=',';" 
	local paramString=$( echo "${1}" | tail -1 | sed 's/^\s*//g' | sed 's/\s*$//g' );
	local expectedParamList=$( echo "${2}" | tail -1 | sed 's/^\s*//g' | sed 's/\s*$//g' );
	local baseFunction="${3}";
	
	
	clearParameters "${expectedParamList}" "${baseFunction}"
	
	debug "################## BEGIN FUNCTION: getParameters  ##################"
	debug "paramString : ${paramString}"
	debug "expectedParamList : ${expectedParamList}"
	debug "Caller Function : ${baseFunction}"
	# Store name of the caller function in variable
	
	
	# Extract the argument delimiter from the parameter string
	# e.g for input : "(arg1=val1,arg2=val2,arg3=val3):delim=',';"
	# return :  , 
	local paramStringDelimiter=$( echo "${paramString}" | sed  "s/^.*:delim='\(.*\)';$/\1/1" );
	local expectedParamlistDelimiter=$( echo "${expectedParamList}" | sed  "s/^.*:delim='\(.*\)';$/\1/1" );
	
	
	# If no delimiter is specified (:delim'|'; not present) then set the default to , (commma)
	[[ "${paramStringDelimiter}" == "${paramString}" ]] && paramStringDelimiter=','
	[[ "${expectedParamlistDelimiter}" = "${expectedParamList}" ]] && expectedParamlistDelimiter=','
	
	debug "paramStringDelimiter : ${paramStringDelimiter}"
	debug "expectedParamlistDelimiter : ${expectedParamlistDelimiter}"
	
	
	# Remove the start & end paranthesis and delim specification from the param string
	# e.g for input : "(arg1=val1,arg2=val2,arg3=val3):delim=',';" OR "(arg1=val1,arg2=val2,arg3=val3)"
	# return : arg1=val1,arg2=val2,arg3=val3 	
	local modParamString=$( echo "${paramString}" | sed 's/:delim.*;$//1' | sed -e 's/^(//g' -e 's/)$//g' );
	local modexpectedParamList=$( echo "${expectedParamList}" | sed 's/:delim.*;$//1' | sed -e 's/^(//g' -e 's/)$//g' );
	
	debug "modParamString : ${modParamString}"
	debug "modexpectedParamList : ${modexpectedParamList}"	
	
	declare -A argValueList
	
	
	local paramValueList="$(echo "${modParamString}" | awk " BEGIN { RS=\"[${paramStringDelimiter}]\"; FS=\"=\"; OFS=\" \" } { print \$1,substr(\$0,length(\$1)+2) } " | sed -e 's/^\s*//g' -e 's/\s*$//g')"
	
	local defValueList="$(echo "${modexpectedParamList}" | awk " BEGIN { RS=\"[${expectedParamlistDelimiter}]\"; FS=\"=\"; OFS=\" \" } { print \$1,substr(\$0,length(\$1)+2) } " | sed -e 's/^\s*//g' -e 's/\s*$//g')"
	
	# debug "paramValueList : ${paramValueList}"
	# debug "defValueList : ${defValueList}"
	
	while
	read -r paramName paramValue
	do
		paramName=$(echo "${paramName}" | sed -e 's/^\s*//g' -e 's/\s*$//g')
		paramValue=$(echo "${paramValue}" | sed -e 's/^\s*//g' -e 's/\s*$//g')
		
		argValueList["${paramName}"]="${paramValue}";
		
		
	done <<< "$(echo "${paramValueList}")"
	
	
	while
	read -r paramName paramValue
	do
		paramName=$(echo "${paramName}" | sed -e 's/^\s*//g' -e 's/\s*$//g')
		paramValue=$(echo "${paramValue}" | sed -e 's/^\s*//g' -e 's/\s*$//g')
		
		[[ "${argValueList["${paramName}"]:-}" != "" ]] && paramValue="${argValueList[${paramName}]:-}";
		
		[[ "${paramValue:-}" == "" ]] && emergency "Expected Value For Parameter: ## ${paramName} ## Missing In Call For Function: ## ${baseFunction} ##. Exiting."
				
		eval ${paramName}='${paramValue}';
		
		[[ "${paramName}" =~ .*PWD$ ]] && paramValue="XXXXXX";
		
		debug "${paramName}=${paramValue};"
	done <<< "$(echo "${defValueList}")"
	
	
	unset -v argValueList;	
	
	debug "################### END FUNCTION: getParameters  ###################"
}

##############################################################################
# -----------------------------------
# Below function takes as input passed arguments,expected arguments and parent function name
# and clears them from the shell environment after they have been used by the parent function.
#
# Usage: clearParameters {Input parameters to the function} {Expected Param List} {Parent Function Name}
#
# -----------------------------------

function clearParameters()
{

	# ltrim & rtrim the input command and assigning to local variable
	# e.g for input : "   (arg1=val1,arg2=val2,arg3=val3):delim=',';    "
	# return : "(arg1=val1,arg2=val2,arg3=val3):delim=',';" 
	local clearParamList=$( echo "${1}" | tail -1 | sed 's/^\s*//g' | sed 's/\s*$//g' );
	local baseFunction="${2}";
	

	
	debug "################## BEGIN FUNCTION: clearParameters  ##################"
	debug "clearParamList : ${clearParamList}"
	debug "Caller Function : ${baseFunction}"
	# Store name of the caller function in variable
	
	
	# Extract the argument delimiter from the parameter string
	# e.g for input : "(arg1=val1,arg2=val2,arg3=val3):delim=',';"
	# return :  , 
	local clearParamListDelimiter=$( echo "${clearParamList}" | sed  "s/^.*:delim='\(.*\)';$/\1/1" );
	
	
	# If no delimiter is specified (:delim'|'; not present) then set the default to , (commma)
	[[ "${clearParamListDelimiter}" = "${clearParamList}" ]] && clearParamListDelimiter=','
	
	debug "clearParamListDelimiter : ${clearParamListDelimiter}"
	
	
	# Remove the start & end paranthesis and delim specification from the param string
	# e.g for input : "(arg1=val1,arg2=val2,arg3=val3):delim=',';" OR "(arg1=val1,arg2=val2,arg3=val3)"
	# return : arg1=val1,arg2=val2,arg3=val3 	
	local modclearParamList=$( echo "${clearParamList}" | sed 's/:delim.*;$//1' | sed -e 's/^(//g' -e 's/)$//g' );
	
	debug "modclearParamList : ${modclearParamList}"	
	
		
	local clearVarList="$(echo "${modclearParamList}" | awk " BEGIN { RS=\"[${clearParamListDelimiter}]\"; FS=\"=\"; OFS=\" \" } { print \$1,substr(\$0,length(\$1)+2) } " | sed -e 's/^\s*//g' -e 's/\s*$//g')"
	
	#debug "clearVarList : ${clearVarList}"
	
	
	while
	read -r paramName paramValue
	do
		paramName=$(echo "${paramName}" | sed -e 's/^\s*//g' -e 's/\s*$//g')
		paramValue=$(echo "${paramValue}" | sed -e 's/^\s*//g' -e 's/\s*$//g')
		
		debug "Cleared Parameter : ${paramName};"
		
		unset -v "${paramName}"		
	
	done <<< "$(echo "${clearVarList}")"
	
	
	debug "################### END FUNCTION: clearParameters  ###################"
}


function mapParameters()
{

	# ltrim & rtrim the input command and assigning to local variable
	# e.g for input : "   (arg1=val1,arg2=val2,arg3=val3):delim=',';    "
	# return : "(arg1=val1,arg2=val2,arg3=val3):delim=',';" 
	local valueString=$( echo "${1}" | tail -1 | sed 's/^\s*//g' | sed 's/\s*$//g' );
	local expectedParamList=$( echo "${2}" | tail -1 | sed 's/^\s*//g' | sed 's/\s*$//g' );
	local baseFunction="${3}";
	
	
	
	clearParameters "${expectedParamList}" "${baseFunction}"
	
	debug "################## BEGIN FUNCTION: mapParameters  ##################"
	debug "valueString : ${valueString}"
	debug "expectedParamList : ${expectedParamList}"
	debug "Caller Function : ${baseFunction}"
	# Store name of the caller function in variable
	
	
	# Extract the argument delimiter from the parameter string
	# e.g for input : "(arg1=val1,arg2=val2,arg3=val3):delim=',';"
	# return :  , 
	local valueStringDelimiter=$( echo "${valueString}" | sed  "s/^.*:delim='\(.*\)';$/\1/1" );
	local expectedParamlistDelimiter=$( echo "${expectedParamList}" | sed  "s/^.*:delim='\(.*\)';$/\1/1" );
	
	
	# If no delimiter is specified (:delim'|'; not present) then set the default to , (commma)
	[[ "${valueStringDelimiter}" == "${valueString}" ]] && valueStringDelimiter=','
	[[ "${expectedParamlistDelimiter}" = "${expectedParamList}" ]] && expectedParamlistDelimiter=','
	
	debug "valueStringDelimiter : ${valueStringDelimiter}"
	debug "expectedParamlistDelimiter : ${expectedParamlistDelimiter}"
	
	
	# Remove the start & end paranthesis and delim specification from the param string
	# e.g for input : "(arg1=val1,arg2=val2,arg3=val3):delim=',';" OR "(arg1=val1,arg2=val2,arg3=val3)"
	# return : arg1=val1,arg2=val2,arg3=val3 	
	local modvalueString=$( echo "${valueString}" | sed 's/:delim.*;$//1' | sed -e 's/^(//g' -e 's/)$//g' );
	local modexpectedParamList=$( echo "${expectedParamList}" | sed 's/:delim.*;$//1' | sed -e 's/^(//g' -e 's/)$//g' );
	
	debug "modvalueString : ${modvalueString}"
	debug "modexpectedParamList : ${modexpectedParamList}"	
	
	declare -a argValueList
	typeset -i loopCtr=0
	
	local valueList="$(echo "${modvalueString}" | awk " BEGIN { RS=\"[${valueStringDelimiter}]\"; FS=\"=\"; OFS=\" \" } { print \$1,substr(\$0,length(\$1)+2) } " | sed -e 's/^\s*//g' -e 's/\s*$//g')"
	
	local defValueList="$(echo "${modexpectedParamList}" | awk " BEGIN { RS=\"[${expectedParamlistDelimiter}]\"; FS=\"=\"; OFS=\" \" } { print \$1,substr(\$0,length(\$1)+2) } " | sed -e 's/^\s*//g' -e 's/\s*$//g')"
	
	#debug "valueList : ${valueList}"
	#debug "defValueList : ${defValueList}"
	
	
	
	while
	read -r paramValue
	do
		paramValue=$(echo "${paramValue}" | sed -e 's/^\s*//g' -e 's/\s*$//g')
		
		argValueList[${loopCtr}]="${paramValue}";
	
		((loopCtr=${loopCtr}+1));

	done <<< "$(echo "${valueList}")"
	
	
	
	loopCtr=0;
	while
	read -r paramName paramValue
	do
		paramName=$(echo "${paramName}" | sed -e 's/^\s*//g' -e 's/\s*$//g')
		paramValue=$(echo "${paramValue}" | sed -e 's/^\s*//g' -e 's/\s*$//g')
		
		[[ "${argValueList[${loopCtr}]:-}" != "" ]] && paramValue="${argValueList[${loopCtr}]:-}";
		
		[[ "${paramValue:-}" == "" ]] && emergency "Expected Value For Parameter: ## ${paramName} ## Missing In Call For Function: ## ${baseFunction} ##. Exiting."
				
		eval ${paramName}='${paramValue}';
	
		debug "${paramName}=${paramValue};"
		
		((loopCtr=${loopCtr}+1));
	done <<< "$(echo "${defValueList}")"
	
	
	
	unset -v argValueList;	
	
	debug "################### END FUNCTION: mapParameters  ###################"
}



function printVarValues()
{

	# ltrim & rtrim the input command and assigning to local variable
	# e.g for input : "   (arg1=val1,arg2=val2,arg3=val3):delim=',';    "
	# return : "(arg1=val1,arg2=val2,arg3=val3):delim=',';" 
	
	local printVarList=$( echo "${1}" | tail -1 | sed 's/^\s*//g' | sed 's/\s*$//g' );
	local baseFunction="${2}";
	
	
	
	debug "################## BEGIN FUNCTION: printVarValues  ##################"
	debug "printVarList : ${printVarList}"
	debug "Caller Function : ${baseFunction}"
	

	
	local printVarListDelimiter=$( echo "${printVarList}" | sed  "s/^.*:delim='\(.*\)';$/\1/1" );
	
	
	# If no delimiter is specified (:delim'|'; not present) then set the default to , (commma)
	[[ "${printVarListDelimiter}" = "${printVarList}" ]] && printVarListDelimiter=','
	
	debug "printVarListDelimiter : ${printVarListDelimiter}"
	
	
	# Remove the start & end paranthesis and delim specification from the param string
	# e.g for input : "(arg1=val1,arg2=val2,arg3=val3):delim=',';" OR "(arg1=val1,arg2=val2,arg3=val3)"
	# return : arg1=val1,arg2=val2,arg3=val3 	
	local modprintVarList=$( echo "${printVarList}" | sed 's/:delim.*;$//1' | sed -e 's/^(//g' -e 's/)$//g' );
	
	debug "modprintVarList : ${modprintVarList}"	
	
	declare -A argValueList
	
	
	
	local variableList="$(echo "${modprintVarList}" | awk " BEGIN { RS=\"[${printVarListDelimiter}]\"; FS=\"=\"; OFS=\" \" } { print \$1,substr(\$0,length(\$1)+2) } " | sed -e 's/^\s*//g' -e 's/\s*$//g')"
	
	
	#debug "variableList : ${variableList}"
	
	
	
	
	while
	read -r varName varValue
	do
		varName=$(echo "${varName}" | sed -e 's/^\s*//g' -e 's/\s*$//g')
		
		
		varValue=${!varName:=}
		[[ "${varName}" =~ .*PWD$ ]] && varValue="XXXXXX";

		
		info "${varName}=${varValue};"
	done <<< "$(echo "${variableList}")"
	
	
	debug "################### END FUNCTION: printVarValues  ###################"
}


# Extract param values from input arguments
	getParameters "${1}" "${__expectedParam}" "${__this}"
	
	local configdir="$(echo "$(dirname "${configfile}")")"
	
	# Files which are combined to form the configuration parameter string
	local commmonPwdFile="${configdir}/.include"
	[[ -f "${commmonPwdFile}" ]] || commmonPwdFile=""
	debug "commmonPwdFile = ${commmonPwdFile};"
	
	local commmonAppconfigFile="${configfile}"
	[[ -f "${configfile}" ]] || emergency "App config file does not exists in path ${configfile}! Exiting."
	debug "commmonAppconfigFile = ${commmonAppconfigFile};"
	
	local currentConfigFile="${configdir}/${configName}.config"
	[[ -f "${currentConfigFile}" ]] || emergency "Config file does not exists in path ${currentConfigFile}! Exiting."
	debug "currentConfigFile = ${currentConfigFile};"
	
	
		declare -A varValueList
	local paramString="( "
	
	local configVarValueList="$(cat "${commmonPwdFile}" "${commmonAppconfigFile}" "${currentConfigFile}" | sed  '/^\s*$/d' | \
	                         awk " BEGIN { RS=\"\n\"; FS=\"=\"; OFS=\" \" } { print \$1,substr(\$0,length(\$1)+2) } " | sed -e 's/^\s*//g' -e 's/\s*$//g')"
	

	debug "configVarValueList : ${configVarValueList}"
	
	
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
