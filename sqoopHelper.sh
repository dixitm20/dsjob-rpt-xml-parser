# Sample Usage Call From Main Script :
# MAX_LOG_DT=$( sqoopExecScalar "(query=SELECT MAX(COLA) AS MAX_COLA FROM TABLE,configName=<<CONFIG_NAME>>,configfile=${arg_c},tmpdir=${arg_t},logdir=${arg_l},uid=${__uid})" )

function sqoopExecScalar()
{
	local __expectedParam='(query,configName,configfile,tmpdir,logdir,uid)'
	local __this="${FUNCNAME[0]} ${1}"
	local __fnName="${FUNCNAME[0]}"
	local __outValue=""
	
	# Extract param values from input arguments
	getParameters "${1}" "${__expectedParam}" "${__this}"
	

	local configExpectedParam='(SQOOP_EXEC_SCALAR_COMMAND)'
	local configParamString=$(sh "${configfile}" "${configName}")
	
	local tmpfile="${tmpdir}/${uid}-${__fnName}_${configName}_$(date '+%Y%m%d%H%M%S').$RANDOM.tmp"
	local logfile="${logdir}/${uid}-${__fnName}_${configName}_$(date '+%Y%m%d%H%M%S').log"
	

	getParameters "${configParamString}" "${configExpectedParam}" "${__this}"

	# get the list of variables used in the sqoop command and read thier values from config as well.
	# example: SQOOP_EXEC_SCALAR_COMMAND="select ${a} from ${b}" will return : ( a,b )
	local configRequiredParam=$( echo $(echo ${SQOOP_EXEC_SCALAR_COMMAND} | awk 'BEGIN{ RS="[\$}]"} !/^{query*/{print $0}' | grep '^{' | sed 's/^{//1') | awk 'BEGIN { print "("; } {gsub(/ /,",");print;} END { print ")"; }' | tr '\n' ' ');
	
	
	getParameters "${configParamString}" "${configRequiredParam}" "${__this}"
	
	local configRequiredParamList="$( echo "${configRequiredParam}" | sed 's/[()]//g' | sed '/^\s*$/d' | sed 's/,/\n/g' )"
	
	info $(echo "Executing Sqoop Execute Scalar Command : ## ${SQOOP_EXEC_SCALAR_COMMAND} ## Using Below Params: ")
	
	printVarValues "${configRequiredParam}" "${__this}"
	info "query=${query};"
	
	echo "$(echo "Executing Sqoop Execute Scalar Command : ## ${SQOOP_EXEC_SCALAR_COMMAND} ## Using Below Params: ")" >> ${logfile}
	
	while
	read -r param
	do
		param=$(echo "${param}" | sed -e 's/^\s*//g' -e 's/\s*$//g')
		paramValue="${!param:=}"
		[[ "${param}" =~ .*PWD$ ]] && paramValue="XXXXXX";
		echo "           ${param}=${paramValue};" >> ${logfile}
	done <<< "$(echo "${configRequiredParamList}")"
	echo "           query=${query};" >> ${logfile}
	
	echo -e "\n\n###############################################" >> ${logfile}
	echo "Begin Sqoop Command Processing..." >> ${logfile}
	echo "|||||||||||||||||||||||||||||||||||||||||||||" >> ${logfile}
	echo -e "vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv\n\n" >> ${logfile}
	
	eval "time ${SQOOP_EXEC_SCALAR_COMMAND}" 2>> ${logfile} 1>${tmpfile} \
		|| emergency "Sqoop Execute Scalar Failed For Function Call : ## ${__this} ##. Exiting.";
	
	echo "Sqoop Execute Scalar Runstats As Shown Above." >> ${logfile}
	echo "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^" >> ${logfile}
	echo "|||||||||||||||||||||||||||||||||||||||||||||" >> ${logfile}
	echo "End Sqoop Command Processing." >> ${logfile}
	echo -e "###############################################\n\n" >> ${logfile}
	
	
	echo -e "Sqoop Execute Scalar Successful For Function Call : ## ${__this} ##.\n" >> ${logfile}
	
	local dataHeader=$( sed -n '/^|/p' "${tmpfile}" | sed -n  '1p'  | sed -e 's/^|/(/1' -e 's/ | $/)/1' -e 's/ | /,/g'  )
	# Set First Column Name As Scalar Name
	local scalarName=$(echo "${dataHeader}" | awk -F'[(,)]' '{ print $2}' | sed -e 's/^\s*//1' -e 's/\s*$//1')
	
	echo -e "Sqoop Execute Scalar Successfully Extracted Values In Temp File : ## ${tmpfile} ## for Columns : ## ${dataHeader} ##.\n" >> ${logfile}
	
	echo -e "Sqoop Execute Scalar Extracted Data From The Temp File : ## ${tmpfile} ## Is As Below : \n\n" >> ${logfile}
	
	cat "${tmpfile}" >> ${logfile}
	
	local dataRow="";
	while 
		read dataRow
	do
		mapParameters "${dataRow}" "${scalarName}" "${__this}"
		__outValue=${!scalarName}
		
	done <<< "$(sed -n '/^|/p' "${tmpfile}" | sed -n  '2p'  | sed -e 's/^|/(/1' -e 's/ | $/)/1' -e 's/ | /,/g')"
	
	
	
	echo -e "\n\nSqoop Execute Scalar Extracted Header : ${scalarName}\n" >> ${logfile}
	echo -e "Sqoop Execute Scalar Extracted Data : ${__outValue}\n" >> ${logfile}
	
	echo -e "Sqoop Execute Scalar Output: ## ${scalarName}=${__outValue} ##\n" >> ${logfile}
	
	# Clear argument variables from the environment
	
	clearParameters "${scalarName}" "${__this}"
	clearParameters "${configRequiredParam}" "${__this}"
	clearParameters "${configExpectedParam}" "${__this}"
	clearParameters "${__expectedParam}" "${__this}"
	
	echo "${scalarName}=${__outValue}"

}	

# Sample Usage Call From Main Script :
# OUT_FILE=$( sqoopExecQuery "(query=SELECT * FROM TABLE,configName=<<CONFIG_NAME>>,configfile=${arg_c},tmpdir=${arg_t},logdir=${arg_l},uid=${__uid})" )

function sqoopExecQuery()
{
	local __expectedParam='(query,configName,configfile,tmpdir,logdir,uid)'
	local __this="${FUNCNAME[0]} ${1}"
	local __fnName="${FUNCNAME[0]}"
	local __outValue=""
	
	# Extract param values from input arguments
	getParameters "${1}" "${__expectedParam}" "${__this}"
	
	local configExpectedParam='(SQOOP_EXEC_QUERY_COMMAND)'
	local configParamString=$(sh "${configfile}" "${configName}")
	
	
	local tmpfile="${tmpdir}/${uid}-${__fnName}_${configName}_$(date '+%Y%m%d%H%M%S').$RANDOM.tmp"
	local logfile="${logdir}/${uid}-${__fnName}_${configName}_$(date '+%Y%m%d%H%M%S').log"
	
	getParameters "${configParamString}" "${configExpectedParam}" "${__this}"
	
	# get the list of variables used in the sqoop command and read thier values from config as well.
	# example: SQOOP_EXEC_QUERY_COMMAND="select ${a} from ${b}" will return : ( a,b )
	local configRequiredParam=$( echo $(echo ${SQOOP_EXEC_QUERY_COMMAND} | awk 'BEGIN{ RS="[\$}]"} !/^{query*/{print $0}' | grep '^{' | sed 's/^{//1') | awk 'BEGIN { print "("; } {gsub(/ /,",");print;} END { print ")"; }' | tr '\n' ' ');

	getParameters "${configParamString}" "${configRequiredParam}" "${__this}"
	
	local configRequiredParamList="$( echo "${configRequiredParam}" | sed 's/[()]//g' | sed '/^\s*$/d' | sed 's/,/\n/g' )"
	
	info $(echo "Executing Sqoop Execute Query Command : ## ${SQOOP_EXEC_QUERY_COMMAND} ## Using Below Params: ")  
	
	printVarValues "${configRequiredParam}" "${__this}" 
	info "query=${query};"
	
	echo "$(echo "Executing Sqoop Execute Query Command : ## ${SQOOP_EXEC_QUERY_COMMAND} ## Using Below Params: ")" >> ${logfile}
	
	while
	read -r param
	do
		param=$(echo "${param}" | sed -e 's/^\s*//g' -e 's/\s*$//g')
		paramValue="${!param:=}"
		[[ "${param}" =~ .*PWD$ ]] && paramValue="XXXXXX";
		echo "           ${param}=${paramValue};" >> ${logfile}
	done <<< "$(echo "${configRequiredParamList}")"
	echo "           query=${query};" >> ${logfile}
	
	echo -e "\n\n###############################################" >> ${logfile}
	echo "Begin Sqoop Command Processing..." >> ${logfile}
	echo "|||||||||||||||||||||||||||||||||||||||||||||" >> ${logfile}
	echo -e "vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv\n\n" >> ${logfile}
	
	eval "time ${SQOOP_EXEC_QUERY_COMMAND}" 2>> ${logfile} 1>${tmpfile} \
		|| emergency "Sqoop Execute Query Failed For Function Call : ## ${__this} ##. Exiting.";
	
	echo "Sqoop Execute Query Runstats As Shown Above." >> ${logfile}
	echo "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^" >> ${logfile}
	echo "|||||||||||||||||||||||||||||||||||||||||||||" >> ${logfile}
	echo "End Sqoop Command Processing." >> ${logfile}
	echo -e "###############################################\n\n" >> ${logfile}
	
	echo -e "Sqoop Execute Query Successful For Function Call : ## ${__this} ##.\n" >> ${logfile}
	
	
	local dataHeader=$( sed -n '/^|/p' "${tmpfile}" | sed -n  '1p'  | sed -e 's/^|/(/1' -e 's/ | $/)/1' -e 's/ | /,/g'  )
	
	__outValue=${tmpfile}
	
	echo -e "Sqoop Execute Query Successfully Extracted Values In Temp File : ## ${__outValue} ## for Columns : ## ${dataHeader} ##.\n" >> ${logfile}
	
	echo -e "Sqoop Execute Query Extracted Data From The Temp File : ## ${__outValue} ## Is As Below : \n\n" >> ${logfile}
	
	cat "${__outValue}" >> ${logfile}
	
	# Below loop can be used to see the extracted data values row by row. Uncomment In case of debugging Only.
	# Begin debug block
	
		# local dataRow="";
		# while 
		# 	read dataRow
		# do
		# 	
		# 	mapParameters "${dataRow}" "${dataHeader}" "${__this}"
		# 	printVarValues "${dataHeader}" "${__this}"
		# 	
		# done <<< "$(sed -n '/^|/p' "${tmpfile}" | sed -n  '2,$p'  | sed -e 's/^|/(/1' -e 's/ | $/)/1' -e 's/ | /,/g')"
		# clearParameters "${dataHeader}" "${__this}"
		
	# End debug block
	
	
	
	# Clear argument variables from the environment
	clearParameters "${configRequiredParam}" "${__this}"
	clearParameters "${configExpectedParam}" "${__this}"
	clearParameters "${__expectedParam}" "${__this}"
	
	echo "${__outValue}"

}


# Sample Usage Call From Main Script :
# EXEC_NONQUERY=$( sqoopExecNonQuery "(query=UPDATE TABLE SET COLA='ABC',configName=<<CONFIG_NAME>>,configfile=${arg_c},tmpdir=${arg_t},logdir=${arg_l},uid=${__uid})" )

function sqoopExecNonQuery()
{
	local __expectedParam='(query,configName,configfile,tmpdir,logdir,uid)'
	local __this="${FUNCNAME[0]} ${1}"
	local __fnName="${FUNCNAME[0]}"
	local __outValue=""
	
	# Extract param values from input arguments
	getParameters "${1}" "${__expectedParam}" "${__this}"
	
	local configExpectedParam='(SQOOP_EXEC_NONQUERY_COMMAND)'
	local configParamString=$(sh "${configfile}" "${configName}")
	
	
	local tmpfile="${tmpdir}/${uid}-${__fnName}_${configName}_$(date '+%Y%m%d%H%M%S').$RANDOM.tmp"
	local logfile="${logdir}/${uid}-${__fnName}_${configName}_$(date '+%Y%m%d%H%M%S').log"
	
	getParameters "${configParamString}" "${configExpectedParam}" "${__this}"

	# get the list of variables used in the sqoop command and read thier values from config as well.
	# example: SQOOP_EXEC_NONQUERY_COMMAND="select ${a} from ${b}" will return : ( a,b )
	local configRequiredParam=$( echo $(echo ${SQOOP_EXEC_NONQUERY_COMMAND} | awk 'BEGIN{ RS="[\$}]"} !/^{query*/{print $0}' | grep '^{' | sed 's/^{//1') | awk 'BEGIN { print "("; } {gsub(/ /,",");print;} END { print ")"; }' | tr '\n' ' ');
	
	getParameters "${configParamString}" "${configRequiredParam}" "${__this}"
	
	local configRequiredParamList="$( echo "${configRequiredParam}" | sed 's/[()]//g' | sed '/^\s*$/d' | sed 's/,/\n/g' )"
	
	info $(echo "Executing Sqoop Execute NonQuery Command : ## ${SQOOP_EXEC_NONQUERY_COMMAND} ## Using Below Params: ")
	
	printVarValues "${configRequiredParam}" "${__this}"
	info "query=${query};"
	
	echo "$(echo "Executing Sqoop Execute NonQuery Command : ## ${SQOOP_EXEC_NONQUERY_COMMAND} ## Using Below Params: ")" >> ${logfile}
	
	while
	read -r param
	do
		param=$(echo "${param}" | sed -e 's/^\s*//g' -e 's/\s*$//g')
		paramValue="${!param:=}"
		[[ "${param}" =~ .*PWD$ ]] && paramValue="XXXXXX";
		echo "           ${param}=${paramValue};" >> ${logfile}
	done <<< "$(echo "${configRequiredParamList}")"
	echo "           query=${query};" >> ${logfile}
	
	echo -e "\n\n###############################################" >> ${logfile}
	echo "Begin Sqoop Command Processing..." >> ${logfile}
	echo "|||||||||||||||||||||||||||||||||||||||||||||" >> ${logfile}
	echo -e "vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv\n\n" >> ${logfile}
	
	eval "time ${SQOOP_EXEC_NONQUERY_COMMAND}" 2>> ${logfile} 1>${tmpfile} \
		|| emergency "Sqoop Execute NonQuery Failed For Function Call : ## ${__this} ##. Exiting.";
		
	echo "Sqoop Execute NonQuery Runstats As Shown Above." >> ${logfile}
	echo "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^" >> ${logfile}
	echo "|||||||||||||||||||||||||||||||||||||||||||||" >> ${logfile}
	echo "End Sqoop Command Processing." >> ${logfile}
	echo -e "###############################################\n\n" >> ${logfile}

		
	echo -e "Sqoop Execute NonQuery Successful For Function Call : ## ${__this} ##.\n" >> ${logfile}
	
	echo -e "Sqoop Execute NonQuery Successfully Executed And Generated Output Log In Temp File : ## ${tmpfile} ##.\n" >> ${logfile}
	
	echo -e "Sqoop Execute NonQuery Generated Output From The Temp File : ## ${tmpfile} ## Is As Below : \n" >> ${logfile}
	
	cat "${tmpfile}" >> ${logfile}
	
	__outValue="$(sed -n '/^Begin Sqoop Command Processing\.\.\./,/^End Sqoop Command Processing\./p' "${logfile}" | grep '^.*INFO tool.EvalSqlTool: ' | tail -1 | sed 's/^.*INFO tool.EvalSqlTool: //1' | awk -F' ' '{ print $1}')"
	
	# Clear argument variables from the environment
	clearParameters "${configRequiredParam}" "${__this}"
	clearParameters "${configExpectedParam}" "${__this}"
	clearParameters "${__expectedParam}" "${__this}"
	
	echo "${__outValue}"

}
