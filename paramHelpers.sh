#!/usr/bin/env bash

### Function Parameter Pass Helpers
##############################################################################
# -----------------------------------
# Function is used to extract expected parameters from the input param string. 
# Given a Expected param list and input paramter string the function will extract
# all the expected paramters value and will source those valriables in the current shell.
#
# Usage : getParameters <<paramstring>> <<expected param list>> <<caller function details>>
# Usage Example: getParameters "(a=10~b=20~c=30):delim='~';" "(a,b):delim=',';" <<caller function details>>
# This call will source variables a & b in the current shell
# -----------------------------------

function getParameters()
{

	# ltrim & rtrim the input command and assigning to local variable
	# e.g for input : "   (arg1=val1,arg2=val2,arg3=val3):delim=',';    "
	# return : "(arg1=val1,arg2=val2,arg3=val3):delim=',';" 
	local paramString=$( echo "${1}" | tail -1 | sed 's/^\s*//g' | sed 's/\s*$//g' );
	local expectedParamList=$( echo "${2}" | tail -1 | sed 's/^\s*//g' | sed 's/\s*$//g' );
	local baseFunction="${3}";
	local __this="${FUNCNAME[0]} ${1}"
	local __fnName="${FUNCNAME[0]}"
	
	debug "################## BEGIN FUNCTION: ${__fnName}  ##################"
	__INDENT="${__INDENT}\t|"

	# Remove the start & end paranthesis and delim specification from the param string
	# e.g for input : "(arg1=val1,arg2=val2,arg3=val3):delim=',';" OR "(arg1=val1,arg2=val2,arg3=val3)"
	# return : arg1=val1,arg2=val2,arg3=val3 	
	local modParamString=$( echo "${paramString}" | sed "s/:delim='..\?.\?';$//1" | sed -e 's/^(\s*//g' -e 's/\s*)$//g' );
	local modexpectedParamList=$( echo "${expectedParamList}" | sed "s/:delim='..\?.\?';$//1" | sed -e 's/^(\s*//g' -e 's/\s*)$//g' );
	
	
	debug "paramString : ${paramString}"
	debug "expectedParamList : ${expectedParamList}"
	debug "Caller Function : ${baseFunction}"
	debug "modParamString : ${modParamString}"
	debug "modexpectedParamList : ${modexpectedParamList}"	
	
	
	if [[ "${modParamString}" == "" ]] || [[ "${modexpectedParamList}" == "" ]]; then
		debug "Paramstring/ExpectedParamlist is empty. No processing required."
	else
		clearParameters "${expectedParamList}" "${baseFunction}"
		
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
		
		
		declare -A argValueList
		
		
		local paramValueList="$(echo "${modParamString}" | awk " BEGIN { RS=\"${paramStringDelimiter}\"; FS=\"=\"; OFS=\"=\" } \
		{ print \$1,substr(\$0,length(\$1)+2) } " | sed 's/=/ /1' | sed -e 's/^\s*//g' -e 's/\s*$//g')"
		
		local defValueList="$(echo "${modexpectedParamList}" | awk " BEGIN { RS=\"${expectedParamlistDelimiter}\"; FS=\"=\"; OFS=\"=\" } \
		{ print \$1,substr(\$0,length(\$1)+2) } " | sed 's/=/ /1' | sed -e 's/^\s*//g' -e 's/\s*$//g')"
		
		 debug "paramValueList : ${paramValueList}"
		 debug "defValueList : ${defValueList}"
		
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
	fi

	__INDENT="${__INDENT::-3}"
	debug "################### END FUNCTION: ${__fnName}  ###################\n\n"
	
	
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
	local __this="${FUNCNAME[0]} ${1}"
	local __fnName="${FUNCNAME[0]}"
	
	debug "################## BEGIN FUNCTION: ${__fnName}  ##################"
	__INDENT="${__INDENT}\t|"
	
	
	# Remove the start & end paranthesis and delim specification from the param string
	# e.g for input : "(arg1=val1,arg2=val2,arg3=val3):delim=',';" OR "(arg1=val1,arg2=val2,arg3=val3)"
	# return : arg1=val1,arg2=val2,arg3=val3 	
	local modclearParamList=$( echo "${clearParamList}" | sed "s/:delim='..\?.\?';$//1" | sed -e 's/^(\s*//g' -e 's/\s*)$//g' );
	
	
	debug "clearParamList : ${clearParamList}"
	debug "Caller Function : ${baseFunction}"
	debug "modclearParamList : ${modclearParamList}"
	
	
	if [[ "${modclearParamList}" == "" ]]; then
		debug "Clear ExpectedParamlist is empty. No processing required."
	else
		# Extract the argument delimiter from the parameter string
		# e.g for input : "(arg1=val1,arg2=val2,arg3=val3):delim=',';"
		# return :  , 
		local clearParamListDelimiter=$( echo "${clearParamList}" | sed  "s/^.*:delim='\(.*\)';$/\1/1" );
		
		
		# If no delimiter is specified (:delim'|'; not present) then set the default to , (commma)
		[[ "${clearParamListDelimiter}" = "${clearParamList}" ]] && clearParamListDelimiter=','
		
		debug "clearParamListDelimiter : ${clearParamListDelimiter}"
		

		local clearVarList="$(echo "${modclearParamList}" | awk " BEGIN { RS=\"${clearParamListDelimiter}\"; FS=\"=\"; OFS=\"=\" } \
		{ print \$1,substr(\$0,length(\$1)+2) } " | sed 's/=/ /1' | sed -e 's/^\s*//g' -e 's/\s*$//g')"
		
		# debug "clearVarList : ${clearVarList}"

		while
		read -r paramName paramValue
		do
			paramName=$(echo "${paramName}" | sed -e 's/^\s*//g' -e 's/\s*$//g')
			paramValue=$(echo "${paramValue}" | sed -e 's/^\s*//g' -e 's/\s*$//g')
			
			debug "Cleared Parameter : ${paramName};"
			
			unset -v "${paramName}"		
		
		done <<< "$(echo "${clearVarList}")"
	
	fi

	__INDENT="${__INDENT::-3}"
	debug "################### END FUNCTION: ${__fnName}  ###################\n\n"

}


function mapParameters()
{


	# ltrim & rtrim the input command and assigning to local variable
	# e.g for input : "   (arg1=val1,arg2=val2,arg3=val3):delim=',';    "
	# return : "(arg1=val1,arg2=val2,arg3=val3):delim=',';" 
	local valueString=$( echo "${1}" | tail -1 | sed 's/^\s*//g' | sed 's/\s*$//g' );
	local expectedParamList=$( echo "${2}" | tail -1 | sed 's/^\s*//g' | sed 's/\s*$//g' );
	local baseFunction="${3}";
	local __this="${FUNCNAME[0]} ${1}"
	local __fnName="${FUNCNAME[0]}"
	
	debug "################## BEGIN FUNCTION: ${__fnName}  ##################"
	__INDENT="${__INDENT}\t|"

	# Remove the start & end paranthesis and delim specification from the param string
	# e.g for input : "(arg1=val1,arg2=val2,arg3=val3):delim=',';" OR "(arg1=val1,arg2=val2,arg3=val3)"
	# return : arg1=val1,arg2=val2,arg3=val3 	
	local modvalueString=$( echo "${valueString}" | sed "s/:delim='..\?.\?';$//1" | sed -e 's/^(\s*//g' -e 's/\s*)$//g' );
	local modexpectedParamList=$( echo "${expectedParamList}" | sed "s/:delim='..\?.\?';$//1" | sed -e 's/^(\s*//g' -e 's/\s*)$//g' );	
	
	
	debug "valueString : ${valueString}"
	debug "expectedParamList : ${expectedParamList}"
	debug "Caller Function : ${baseFunction}"
	debug "modvalueString : ${modvalueString}"
	debug "modexpectedParamList : ${modexpectedParamList}"
	
	if [[ "${modvalueString}" == "" ]] || [[ "${modexpectedParamList}" == "" ]]; then
		debug "ValueString/ExpectedParamlist is empty. No processing required."
	else
		clearParameters "${expectedParamList}" "${baseFunction}"
			
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
		
		declare -a argValueList
		typeset -i loopCtr=0
		
		local valueList="$(echo "${modvalueString}" | awk " BEGIN { RS=\"${valueStringDelimiter}\"; } \
		{ print \$0 } " | sed -e 's/^\s*//g' -e 's/\s*$//g')"
		
		local defValueList="$(echo "${modexpectedParamList}" | awk " BEGIN { RS=\"${expectedParamlistDelimiter}\"; FS=\"=\"; OFS=\"=\" } \
		{ print \$1,substr(\$0,length(\$1)+2) } " | sed 's/=/ /1' | sed -e 's/^\s*//g' -e 's/\s*$//g')"
		
		# debug "valueList : ${valueList}"
		# debug "defValueList : ${defValueList}"

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
	fi
	
	__INDENT="${__INDENT::-3}"
	debug "################### END FUNCTION: ${__fnName}  ###################\n\n"
	
}



function printEnvParameters()
{

	# ltrim & rtrim the input command and assigning to local variable
	# e.g for input : "   (arg1=val1,arg2=val2,arg3=val3):delim=',';    "
	# return : "(arg1=val1,arg2=val2,arg3=val3):delim=',';" 
	
	local printVarList=$( echo "${1}" | tail -1 | sed 's/^\s*//g' | sed 's/\s*$//g' );
	local baseFunction="${2}";
	local logdir="${3}"
	local unqid="${4}"
	local isRuntimeEnvParamList=${5:-FALSE}
	local runtimeEnvParamPrefix="Runtime.env <= "
	local __this="${FUNCNAME[0]} ${1}"
	local __fnName="${FUNCNAME[0]}"
	
	debug "################## BEGIN FUNCTION: ${__fnName}  ##################"
	__INDENT="${__INDENT}\t|"
	
	# Remove the start & end paranthesis and delim specification from the param string
	# e.g for input : "(arg1=val1,arg2=val2,arg3=val3):delim=',';" OR "(arg1=val1,arg2=val2,arg3=val3)"
	# return : arg1=val1,arg2=val2,arg3=val3 	
	local modprintVarList=$( echo "${printVarList}" | sed "s/:delim='..\?.\?';$//1" | sed -e 's/^(\s*//g' -e 's/\s*)$//g' );

	debug "printVarList : ${printVarList}"
	debug "Caller Function : ${baseFunction}"
	debug "modprintVarList : ${modprintVarList}"
	
	if [[ "${modprintVarList}" == "" ]]; then
		debug "Printvarlist is empty. No processing required."
	else
		local printVarListDelimiter=$( echo "${printVarList}" | sed  "s/^.*:delim='\(.*\)';$/\1/1" );
		
		
		# If no delimiter is specified (:delim'|'; not present) then set the default to , (commma)
		[[ "${printVarListDelimiter}" = "${printVarList}" ]] && printVarListDelimiter=','
		
		debug "printVarListDelimiter : ${printVarListDelimiter}"
		
		declare -A argValueList	
		
		local variableList="$(echo "${modprintVarList}" | awk " BEGIN { RS=\"[${printVarListDelimiter}]\"; FS=\"=\"; OFS=\"=\" } \
		{ print \$1,substr(\$0,length(\$1)+2) } " | sed 's/=/ /1' | sed -e 's/^\s*//g' -e 's/\s*$//g')"
		
		# debug "variableList : ${variableList}"
		
			
		[[ "${isRuntimeEnvParamList}" != "TRUE" ]] && runtimeEnvParamPrefix=""
		while
		read -r varName varValue
		do
			varName=$(echo "${varName}" | sed -e 's/^\s*//g' -e 's/\s*$//g')
			
			
			varValue=${!varName:=}
			[[ "${varName}" =~ .*PWD$ ]] && varValue="XXXXXX";

			
			info "${runtimeEnvParamPrefix}${varName}=${varValue};"
			
			# remove this after testing
			#[[ "${isRuntimeEnvParamList}" == "TRUE" ]] && $(appendToRuntimeEnvFile "(attribName=${varName}#@#attribValue=${varValue}#@#logdir=${logdir}#@#unqid=${unqid}):delim='#@#';" > /dev/null )
			
			if [[ "${isRuntimeEnvParamList}" == "TRUE" ]]; then
				runtimeenvfile=$(getRuntimeEnvFile "(logdir=${logdir},unqid=${unqid})")
				debug "VALUE_OF_${varName}=${varValue}"
				echo "VALUE_OF_${varName}=${varValue}" >> ${runtimeenvfile}
			fi
			
		done <<< "$(echo "${variableList}")"
	fi
	
	__INDENT="${__INDENT::-3}"
	debug "################### END FUNCTION: ${__fnName}  ###################\n\n"
	
}
