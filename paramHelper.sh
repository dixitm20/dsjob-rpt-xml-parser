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
# 	getParameters "${1}" "${__expectedParam}" "${__this}"
# 	
# 	# Function Logic Below
# 	
# 	# Clear argument variables from the environment
# 	clearParameters "${1}" "${__expectedParam}" "${__this}"
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
	
	
	clearParameters ${paramString} ${expectedParamList} ${baseFunction}
	
	debug "################## BEGIN FUNCTION: getParameters  ##################"
	debug "paramString : ${paramString}"
	debug "expectedParamList : ${expectedParamList}"
	debug "Caller Function : ${baseFunction} ${paramString}"
	# Store name of the caller function in variable
	
	
	# Extract the argument delimiter from the parameter string
	# e.g for input : "(arg1=val1,arg2=val2,arg3=val3):delim=',';"
	# return :  , 
	local paramStringDelimiter=$( echo "${paramString}" | sed  "s/^.*:delim='\(.*\)';/\1/1" );
	local expectedParamlistDelimiter=$( echo "${expectedParamList}" | sed  "s/^.*:delim='\(.*\)';/\1/1" );
	
	# If no delimiter is specified (:delim'|'; not present) then set the default to , (commma)
	[[ ${paramStringDelimiter} = ${paramString} ]] && paramStringDelimiter=','
	[[ ${expectedParamlistDelimiter} = ${expectedParamList} ]] && expectedParamlistDelimiter=','
	
	# Remove the start & end paranthesis and delim specification from the param string
	# e.g for input : "(arg1=val1,arg2=val2,arg3=val3):delim=',';" OR "(arg1=val1,arg2=val2,arg3=val3)"
	# return : arg1=val1,arg2=val2,arg3=val3 	
	local modParamString=$( echo "${paramString}" | sed 's/^(\s*//g' | sed "s/\s*):delim=.*;$//g" | sed "s/\s*)$//g" );
	local modexpectedParamList=$( echo "${expectedParamList}" | sed 's/^(\s*//g' | sed "s/\s*):delim=.*;$//g" | sed "s/\s*)$//g" );
	
	local currentExpectedParam="";
	local expectedParamName=""
	local defaultParamValue=""	
	
	local currentInputParam="";
	local inputParamName=""
	local inputParamValue=""
	local isNotFoundExpectedParam=true

	for currentExpectedParam in ${modexpectedParamList//$(echo ${expectedParamlistDelimiter})/$'\n'}; do
		expectedParamName=${currentExpectedParam%%=*}
		defaultParamValue=${currentExpectedParam#*=}
		
		# ltrim & rtrim the values
		expectedParamName=$( echo "${expectedParamName}" | tail -1 | sed 's/^\s*//g' | sed 's/\s*$//g' );
		defaultParamValue=$( echo "${defaultParamValue}" | tail -1 | sed 's/^\s*//g' | sed 's/\s*$//g' );
		
		
		[[ ${expectedParamName} = ${defaultParamValue} ]] && defaultParamValue=""
		
		debug "expectedParamName = ${expectedParamName};"
		debug "defaultParamValue = ${defaultParamValue};"
		
		isNotFoundExpectedParam=true		
		for currentInputParam in ${modParamString//$(echo ${paramStringDelimiter})/$'\n'}; do
			inputParamName=${currentInputParam%%=*}
			inputParamValue=${currentInputParam#*=}
			
			# ltrim & rtrim the values
			inputParamName=$( echo "${inputParamName}" | tail -1 | sed 's/^\s*//g' | sed 's/\s*$//g' );
			inputParamValue=$( echo "${inputParamValue}" | tail -1 | sed 's/^\s*//g' | sed 's/\s*$//g' );
			
			[[ ${inputParamName} = ${inputParamValue} ]] && inputParamValue=""
			
			
			if [[ ${expectedParamName} = ${inputParamName} &&  ${inputParamValue} != "" ]]; then

				debug "inputParamName = ${inputParamName};"
				debug "inputParamValue = ${inputParamValue};"

				eval ${expectedParamName}=${inputParamValue};
				isNotFoundExpectedParam=false;
				debug "${expectedParamName} = ${!expectedParamName};"
				break;
			fi
		done
		
		
		if [[ ${isNotFoundExpectedParam} = true && ${defaultParamValue} != "" ]]; then
			eval ${expectedParamName}=${defaultParamValue};
			isNotFoundExpectedParam=false;
			debug "isNotFoundExpectedParam (Using Default) = ${isNotFoundExpectedParam};"
		fi
		
		
		
		if [[ ${isNotFoundExpectedParam} = true ]]; then
			debug "isNotFoundExpectedParam = ${isNotFoundExpectedParam};"
			emergency "Expected Parameter: ## ${expectedParamName} ## Missing In Call For Function: ## ${baseFunction} ${paramString} ##. Exiting."
		fi
	
	done	
	
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
	local paramString=$( echo "${1}" | tail -1 | sed 's/^\s*//g' | sed 's/\s*$//g' );
	local expectedParamList=$( echo "${2}" | tail -1 | sed 's/^\s*//g' | sed 's/\s*$//g' );
	local baseFunction="${3}";
	
	debug "################## BEGIN FUNCTION: clearParameters  ##################"
	debug "expectedParamList : ${expectedParamList}"
	debug "Caller Function : ${baseFunction} ${paramString}"
	
	# Extract the argument delimiter from the parameter string
	# e.g for input : "(arg1=val1,arg2=val2,arg3=val3):delim=',';"
	# return :  , 
	local expectedParamlistDelimiter=$( echo "${expectedParamList}" | sed  "s/^.*:delim='\(.*\)';/\1/1" );
	
	# If no delimiter is specified (:delim'|'; not present) then set the default to , (commma)
	[[ ${expectedParamlistDelimiter} = ${expectedParamList} ]] && expectedParamlistDelimiter=','
	
	# Remove the start & end paranthesis and delim specification from the param string
	# e.g for input : "(arg1=val1,arg2=val2,arg3=val3):delim=',';" OR "(arg1=val1,arg2=val2,arg3=val3)"
	# return : arg1=val1,arg2=val2,arg3=val3 	
	local modexpectedParamList=$( echo "${expectedParamList}" | sed 's/^(\s*//g' | sed "s/\s*):delim=.*;$//g" | sed "s/\s*)$//g" );
	
	local currentExpectedParam="";
	local expectedParamName=""

	for currentExpectedParam in ${modexpectedParamList//$(echo ${expectedParamlistDelimiter})/$'\n'}; do
		expectedParamName=${currentExpectedParam%%=*}
		
		# ltrim & rtrim the values
		expectedParamName=$( echo "${expectedParamName}" | tail -1 | sed 's/^\s*//g' | sed 's/\s*$//g' );
		
		debug "expectedParamName = ${expectedParamName};"
		
		unset -v "${expectedParamName}"
		
		debug "Cleared Variable : ${expectedParamName};"
	done	
	
	debug "################### END FUNCTION: clearParameters  ###################"
	
}
