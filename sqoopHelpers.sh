#!/usr/bin/env bash


# Sample Usage Call From Main Script :
# EXEC_SCALAR=$( sqoopExecScalar "(query=SELECT CAST(MAX(LOG_DT) AS FORMAT 'YYYY-MM-DD') \
#                AS MAX_LOG_DT FROM PURGE_QUE_TBL,configName=APP_METADATA_CONFIG, \
# 			     envfile=${arg_c},tmpdir=${arg_t},logdir=${arg_l},unqid=${__unqid})" )

function sqoopExecScalar()
{
	local __expectedParam='(cmdtmplteprefx,query,configfile,envfile,tmpdir,logdir,unqid)'
	local __this="${FUNCNAME[0]} ${1}"
	local __fnName="${FUNCNAME[0]}"
	local __outValue=""
	local configName="$(echo "${configfile##*\/}")"
	configName="$(echo "${configName%%.*}")"
	local cmdtmplte="${cmdtmplteprefx}_EXEC_SCALAR"

	debug "################## BEGIN FUNCTION: ${__fnName}  ##################"
	__INDENT="${__INDENT}\t|"
	
	
	# Extract expected param values from input arguments
	getParameters "${1}" "${__expectedParam}" "${__this}"
	
	
	local tmpruntimeconfigfile="$(genNewTmpFile "(tmpdir=${tmpdir},unqid=${unqid})")"
	echo "query=\"${query}\"" > ${tmpruntimeconfigfile}
	
	local SQOOP_EXEC_SCALAR_COMMAND=$( configAttribResolver "(attribName=${cmdtmplte},\
	           configfile=${configfile},envfile=${envfile},runtimeconfigfile=${tmpruntimeconfigfile},tmpdir=${tmpdir},logdir=${logdir},unqid=${unqid})" )
	
	
	# Set temp dir & the log dir
	local tmpfile="$(genNewTmpFile "(tmpdir=${tmpdir},unqid=${unqid})")"
	local logfile="$(getLogFile "(logdir=${logdir},unqid=${unqid})")"

	
	local SQOOP_EXEC_SCALAR_COMMAND_ENCRYPTED=$(encryptPWDtags "(inputString=${SQOOP_EXEC_SCALAR_COMMAND}):delim='#@#';")
	local SQOOP_EXEC_SCALAR_COMMAND_RUN=$(removePWDtags "(inputString=${SQOOP_EXEC_SCALAR_COMMAND}):delim='#@#';")
	
	info $(echo "Executing Sqoop Execute Scalar Command : ## ${SQOOP_EXEC_SCALAR_COMMAND_ENCRYPTED} ##. ")
	
	
	echo "$(echo "Executing Sqoop Execute Scalar Command : ## ${SQOOP_EXEC_SCALAR_COMMAND_ENCRYPTED} ##: ")" >> ${logfile}
	
	
	echo -e "\n\n###############################################" >> ${logfile}
	echo "Begin Sqoop Command Processing..." >> ${logfile}
	echo "|||||||||||||||||||||||||||||||||||||||||||||" >> ${logfile}
	echo -e "vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv\n\n" >> ${logfile}
	

	eval "time ${SQOOP_EXEC_SCALAR_COMMAND_RUN}" 2>> ${logfile} 1>${tmpfile} \
		|| emergency "Sqoop Execute Scalar Failed For Function Call : ## ${__this} ##. Exiting.";
	
	echo "Sqoop Execute Scalar Runstats As Shown Above." >> ${logfile}
	echo "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^" >> ${logfile}
	echo "|||||||||||||||||||||||||||||||||||||||||||||" >> ${logfile}
	echo "End Sqoop Command Processing." >> ${logfile}
	echo -e "###############################################\n\n" >> ${logfile}
	
	
	echo -e "Sqoop Execute Scalar Successful For Function Call : ## ${__this} ##.\n" >> ${logfile}
	info "Sqoop Execute Scalar Successful For Function Call : ## ${__this} ##." >> ${logfile}
	
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
		
	done <<< "$(sed -n '/^|/p' "${tmpfile}" | sed -n  '2p'  | \
	sed -e 's/^|/(/1' -e 's/ | $/)/1' -e 's/ | /,/g')"
	
	
	echo -e "\n\nSqoop Execute Scalar Extracted Header : ${scalarName}\n" >> ${logfile}
	echo -e "Sqoop Execute Scalar Extracted Data : ${__outValue}\n" >> ${logfile}
	
	echo -e "Sqoop Execute Scalar Output: ## ${scalarName}=${__outValue} ##\n" >> ${logfile}
	
	# Clear argument variables from the environment
	
	clearParameters "${scalarName}" "${__this}"
	clearParameters "${__expectedParam}" "${__this}"
	
	__INDENT="${__INDENT::-3}"
	debug "################### END FUNCTION: ${__fnName}  ###################\n\n"
	
	echo "${__outValue}"

}	

# Sample Usage Call From Main Script :
# EXEC_QUERY=$( sqoopExecQuery "(query=SELECT * FROM PURGE_QUE_TBL,configName=APP_METADATA_CONFIG,envfile=${arg_c},tmpdir=${arg_t},logdir=${arg_l},unqid=${__unqid})" )

function sqoopExecQuery()
{
	local __expectedParam='(cmdtmplteprefx,query,configfile,envfile,tmpdir,logdir,unqid)'
	local __this="${FUNCNAME[0]} ${1}"
	local __fnName="${FUNCNAME[0]}"
	local __outValue=""
	local configName="$(echo "${configfile##*\/}")"
	configName="$(echo "${configName%%.*}")"
	local cmdtmplte="${cmdtmplteprefx}_EXEC_QUERY"
	
	debug "################## BEGIN FUNCTION: ${__fnName}  ##################"
	__INDENT="${__INDENT}\t|"

	
	# Extract param values from input arguments
	getParameters "${1}" "${__expectedParam}" "${__this}"
	
	
	local tmpruntimeconfigfile="$(genNewTmpFile "(tmpdir=${tmpdir},unqid=${unqid})")"
	echo "query=\"${query}\"" > ${tmpruntimeconfigfile}
	
	local SQOOP_EXEC_QUERY_COMMAND=$( configAttribResolver "(attribName=${cmdtmplte},\
	           configfile=${configfile},envfile=${envfile},runtimeconfigfile=${tmpruntimeconfigfile},tmpdir=${tmpdir},logdir=${logdir},unqid=${unqid})" )
	
	
	# Set temp dir & the log dir
	local tmpfile="$(genNewTmpFile "(tmpdir=${tmpdir},unqid=${unqid})")"
	local logfile="$(getLogFile "(logdir=${logdir},unqid=${unqid})")"
		
	
	local SQOOP_EXEC_QUERY_COMMAND_ENCRYPTED=$(encryptPWDtags "(inputString=${SQOOP_EXEC_QUERY_COMMAND}):delim='#@#';")
	local SQOOP_EXEC_QUERY_COMMAND_RUN=$(removePWDtags "(inputString=${SQOOP_EXEC_QUERY_COMMAND}):delim='#@#';")
	
	
	info $(echo "Executing Sqoop Execute Query Command : ## ${SQOOP_EXEC_QUERY_COMMAND_ENCRYPTED} ##: ")  
	
	
	echo "$(echo "Executing Sqoop Execute Query Command : ## ${SQOOP_EXEC_QUERY_COMMAND_ENCRYPTED} ##: ")" >> ${logfile}
	
	
	echo -e "\n\n###############################################" >> ${logfile}
	echo "Begin Sqoop Command Processing..." >> ${logfile}
	echo "|||||||||||||||||||||||||||||||||||||||||||||" >> ${logfile}
	echo -e "vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv\n\n" >> ${logfile}
	
	eval "time ${SQOOP_EXEC_QUERY_COMMAND_RUN}" 2>> ${logfile} 1>${tmpfile} \
		|| emergency "Sqoop Execute Query Failed For Function Call : ## ${__this} ##. Exiting.";
	
	echo "Sqoop Execute Query Runstats As Shown Above." >> ${logfile}
	echo "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^" >> ${logfile}
	echo "|||||||||||||||||||||||||||||||||||||||||||||" >> ${logfile}
	echo "End Sqoop Command Processing." >> ${logfile}
	echo -e "###############################################\n\n" >> ${logfile}
	
	echo -e "Sqoop Execute Query Successful For Function Call : ## ${__this} ##.\n" >> ${logfile}
	info "Sqoop Execute Query Successful For Function Call : ## ${__this} ##."
	
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
		# 	mapParameters "${dataRow}:delim='#@#';" "${dataHeader}" "${__this}"
		# 	printVarValues "${dataHeader}" "${__this}"
		# 	
		# done <<< "$(sed -n '/^|/p' "${tmpfile}" | sed -n  '2,$p'  | sed -e 's/^|/(/1' -e 's/ | $/)/1' -e 's/ | /#@#/g')"
		# clearParameters "${dataHeader}" "${__this}"
		
	# End debug block
	
	
	
	# Clear argument variables from the environment
	clearParameters "${__expectedParam}" "${__this}"
	
	__INDENT="${__INDENT::-3}"
	debug "################### END FUNCTION: ${__fnName}  ###################\n\n"
	
	echo "${__outValue}"

}


# Sample Usage Call From Main Script :
# EXEC_NONQUERY=$( sqoopExecNonQuery "(query=UPDATE PURGE_QUE_TBL SET DB_NM='TM901',configName=APP_METADATA_CONFIG,envfile=${arg_c},tmpdir=${arg_t},logdir=${arg_l},unqid=${__unqid})" )

function sqoopExecNonQuery()
{
	local __expectedParam='(cmdtmplteprefx,query,configfile,envfile,tmpdir,logdir,unqid)'
	local __this="${FUNCNAME[0]} ${1}"
	local __fnName="${FUNCNAME[0]}"
	local __outValue=""
	local configName="$(echo "${configfile##*\/}")"
	configName="$(echo "${configName%%.*}")"
	local cmdtmplte="${cmdtmplteprefx}_EXEC_NONQUERY"

	
	debug "################## BEGIN FUNCTION: ${__fnName}  ##################"
	__INDENT="${__INDENT}\t|"
	
	
	# Extract param values from input arguments
	getParameters "${1}" "${__expectedParam}" "${__this}"
	
	
	local tmpruntimeconfigfile="$(genNewTmpFile "(tmpdir=${tmpdir},unqid=${unqid})")"
	echo "query=\"${query}\"" > ${tmpruntimeconfigfile}
	
	local SQOOP_EXEC_NONQUERY_COMMAND=$( configAttribResolver "(attribName=${cmdtmplte},\
	           configfile=${configfile},envfile=${envfile},runtimeconfigfile=${tmpruntimeconfigfile},tmpdir=${tmpdir},logdir=${logdir},unqid=${unqid})" )
	
	
	# Set temp dir & the log dir
	local tmpfile="$(genNewTmpFile "(tmpdir=${tmpdir},unqid=${unqid})")"
	local logfile="$(getLogFile "(logdir=${logdir},unqid=${unqid})")"
		
	
	local SQOOP_EXEC_NONQUERY_COMMAND_ENCRYPTED=$(encryptPWDtags "(inputString=${SQOOP_EXEC_NONQUERY_COMMAND}):delim='#@#';")
	local SQOOP_EXEC_NONQUERY_COMMAND_RUN=$(removePWDtags "(inputString=${SQOOP_EXEC_NONQUERY_COMMAND}):delim='#@#';")

	
	info $(echo "Executing Sqoop Execute NonQuery Command : ## ${SQOOP_EXEC_NONQUERY_COMMAND_ENCRYPTED} ##: ")
	

	echo "$(echo "Executing Sqoop Execute NonQuery Command : ## ${SQOOP_EXEC_NONQUERY_COMMAND_ENCRYPTED} ##: ")" >> ${logfile}
	
	
	echo -e "\n\n###############################################" >> ${logfile}
	echo "Begin Sqoop Command Processing..." >> ${logfile}
	echo "|||||||||||||||||||||||||||||||||||||||||||||" >> ${logfile}
	echo -e "vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv\n\n" >> ${logfile}
	
	eval "time ${SQOOP_EXEC_NONQUERY_COMMAND_RUN}" 2>> ${logfile} 1>${tmpfile} \
		|| emergency "Sqoop Execute NonQuery Failed For Function Call : ## ${__this} ##. Exiting.";
		
	echo "Sqoop Execute NonQuery Runstats As Shown Above." >> ${logfile}
	echo "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^" >> ${logfile}
	echo "|||||||||||||||||||||||||||||||||||||||||||||" >> ${logfile}
	echo "End Sqoop Command Processing." >> ${logfile}
	echo -e "###############################################\n\n" >> ${logfile}

		
	echo -e "Sqoop Execute NonQuery Successful For Function Call : ## ${__this} ##.\n" >> ${logfile}
	info "Sqoop Execute NonQuery Successful For Function Call : ## ${__this} ##."
	
	echo -e "Sqoop Execute NonQuery Successfully Executed And Generated Output Log In Temp File : ## ${tmpfile} ##.\n" >> ${logfile}
	
	echo -e "Sqoop Execute NonQuery Generated Output From The Temp File : ## ${tmpfile} ## Is As Below : \n" >> ${logfile}
	
	cat "${tmpfile}" >> ${logfile}
	
	__outValue="$(sed -n '/^Begin Sqoop Command Processing\.\.\./,/^End Sqoop Command Processing\./p' "${logfile}" | \
	grep '^.*INFO tool.EvalSqlTool: ' | tail -1 | sed 's/^.*INFO tool.EvalSqlTool: //1' | awk -F' ' '{ print $1}')"
	
	# Clear argument variables from the environment
	clearParameters "${__expectedParam}" "${__this}"
	
	
	__INDENT="${__INDENT::-3}"
	debug "################### END FUNCTION: ${__fnName}  ###################\n\n"
	
	echo "${__outValue}"

}



function sqoopExecScalar4ConfigAttrib()
{
	local __expectedParam='(cmdtmplteprefx,attribName,configfile,envfile,tmpdir,logdir,unqid)'
	local __this="${FUNCNAME[0]} ${1}"
	local __fnName="${FUNCNAME[0]}"
	local __outValue=""
	

	debug "################## BEGIN FUNCTION: ${__fnName}  ##################"
	__INDENT="${__INDENT}\t|"
	
	
	# Extract expected param values from input arguments
	getParameters "${1}" "${__expectedParam}" "${__this}"
	
	local query=$( configAttribResolver "(attribName=${attribName}, configfile=${configfile},envfile=${envfile},tmpdir=${tmpdir},logdir=${logdir},unqid=${unqid})" )
	
	local execScalarOutput=$( sqoopExecScalar "(cmdtmplteprefx=${cmdtmplteprefx}#@# query=${query}#@# configfile=${configfile}#@# envfile=${envfile}#@# tmpdir=${tmpdir}#@# logdir=${logdir}#@# unqid=${unqid}):delim='#@#';" )
	
	
	__outValue="${execScalarOutput}"
	
	clearParameters "${__expectedParam}" "${__this}"
	
	__INDENT="${__INDENT::-3}"
	debug "################### END FUNCTION: ${__fnName}  ###################\n\n"
	
	echo "${__outValue}"

}


function sqoopExecNonQuery4ConfigAttrib()
{
	local __expectedParam='(cmdtmplteprefx,attribName,configfile,envfile,tmpdir,logdir,unqid)'
	local __this="${FUNCNAME[0]} ${1}"
	local __fnName="${FUNCNAME[0]}"
	local __outValue=""
	

	debug "################## BEGIN FUNCTION: ${__fnName}  ##################"
	__INDENT="${__INDENT}\t|"
	
	
	# Extract expected param values from input arguments
	getParameters "${1}" "${__expectedParam}" "${__this}"
	
	local query=$( configAttribResolver "(attribName=${attribName}, configfile=${configfile},envfile=${envfile},tmpdir=${tmpdir},logdir=${logdir},unqid=${unqid})" )
	
	local execNonQueryOutput=$( sqoopExecNonQuery "(cmdtmplteprefx=${cmdtmplteprefx}#@# query=${query}#@# configfile=${configfile}#@# envfile=${envfile}#@# tmpdir=${tmpdir}#@# logdir=${logdir}#@# unqid=${unqid}):delim='#@#';" )
	
	
	
	__outValue="${execNonQueryOutput}"
	
	clearParameters "${__expectedParam}" "${__this}"
	
	__INDENT="${__INDENT::-3}"
	debug "################### END FUNCTION: ${__fnName}  ###################\n\n"
	
	echo "${__outValue}"

}



function sqoopExecQuery4ConfigAttrib()
{
	local __expectedParam='(cmdtmplteprefx,attribName,configfile,envfile,tmpdir,logdir,unqid)'
	local __this="${FUNCNAME[0]} ${1}"
	local __fnName="${FUNCNAME[0]}"
	local __outValue=""

	debug "################## BEGIN FUNCTION: ${__fnName}  ##################"
	__INDENT="${__INDENT}\t|"
	
	
	# Extract expected param values from input arguments
	getParameters "${1}" "${__expectedParam}" "${__this}"
	
	local query=$( configAttribResolver "(attribName=${attribName}, configfile=${configfile},envfile=${envfile},tmpdir=${tmpdir},logdir=${logdir},unqid=${unqid})" )
	
	local execQueryOutput=$( sqoopExecQuery "(cmdtmplteprefx=${cmdtmplteprefx}#@# query=${query}#@# configfile=${configfile}#@# envfile=${envfile}#@# tmpdir=${tmpdir}#@# logdir=${logdir}#@# unqid=${unqid}):delim='#@#';" )
	
	
	__outValue="${execQueryOutput}"
	
	clearParameters "${__expectedParam}" "${__this}"
	
	__INDENT="${__INDENT::-3}"
	debug "################### END FUNCTION: ${__fnName}  ###################\n\n"
	
	echo "${__outValue}"

}
