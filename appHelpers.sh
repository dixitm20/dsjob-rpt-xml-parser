function loadConfigToRuntimeEnv()
{
	local __expectedParam='(configfile,envfile,tmpdir,logdir,unqid)'
	local __this="${FUNCNAME[0]} ${1}"
	local __fnName="${FUNCNAME[0]}"
	local __outValue=""


	debug "################## BEGIN FUNCTION: ${__fnName}  ##################"
	__INDENT="${__INDENT}\t|"
	
	
	# Extract expected param values from input arguments
	getParameters "${1}" "${__expectedParam}" "${__this}"
	
	local cmdtmplteprefx="APP_MTD_SQOOP"
	local attribName="PURGE_TBL_FETCH_METADATA_QUERY"
	
	
	
	local execQueryOutput=$( sqoopExecQuery4ConfigAttrib "(cmdtmplteprefx=${cmdtmplteprefx}, attribName=${attribName}, configfile=${configfile}, envfile=${envfile}, tmpdir=${tmpdir}, logdir=${logdir}, unqid=${unqid})" )
	
	
	
	
	# Below loop can be used to see the extracted data values row by row. Uncomment In case of debugging Only.
	# Begin debug block
	
		local dataHeader=$( sed -n '/^|/p' "${execQueryOutput}" | sed -n  '1p'  | sed -e 's/^|/(/1' -e 's/ | $/)/1' -e 's/ | /,/g'  )
		
		local dataRow="";
		while 
			read dataRow
		do
			
			mapParameters "${dataRow}:delim='#@#';" "${dataHeader}" "${__this}"
			printEnvParameters "${dataHeader}" "${__this}" "${logdir}" "${unqid}" "TRUE"
			
		done <<< "$(sed -n '/^|/p' "${execQueryOutput}" | sed -n  '2,$p'  | sed -e 's/^|/(/1' -e 's/ | $/)/1' -e 's/ | /#@#/g' | tail -1 )"
		
		
	# End debug block
	
	# If PARAM_BAG is not empty then add params in the BAG to the env file as well
	if [[ "${PARAM_BAG}" != "(null)" ]]; then
		getParameters "${PARAM_BAG}" "${PARAM_BAG}" "${__this}"
		printEnvParameters "${PARAM_BAG}" "${__this}" "${logdir}" "${unqid}" "TRUE"
	fi
	
	# Evalauate Boundary_Condition
	cmdtmplteprefx="${SQOOP_CMD_TMPLT_IDNTFR}"
	attribName="${SQOOP_CMD_TMPLT_IDNTFR}_BOUNDARY_CONDITION"
	
	local execScalarOutput=$( sqoopExecScalar4ConfigAttrib "(cmdtmplteprefx=${cmdtmplteprefx}, attribName=${attribName}, configfile=${configfile}, envfile=${envfile}, tmpdir=${tmpdir}, logdir=${logdir}, unqid=${unqid})" )
	
	getParameters "(BOUNDARY_CONDITION=${execScalarOutput}):delim='#@#';" "(BOUNDARY_CONDITION)" "${__this}"
	printEnvParameters "(BOUNDARY_CONDITION)" "${__this}" "${logdir}" "${unqid}" "TRUE"
	
	# Get Purge Row Count From Source
	cmdtmplteprefx="${SQOOP_CMD_TMPLT_IDNTFR}"
	attribName="${SQOOP_CMD_TMPLT_IDNTFR}_SRC_PURGE_ROW_COUNT"
	
	local execScalarOutput=$( sqoopExecScalar4ConfigAttrib "(cmdtmplteprefx=${cmdtmplteprefx}, attribName=${attribName}, configfile=${configfile}, envfile=${envfile}, tmpdir=${tmpdir}, logdir=${logdir}, unqid=${unqid})" )
	
	getParameters "(SRC_PURGE_ROW_COUNT=${execScalarOutput}):delim='#@#';" "(SRC_PURGE_ROW_COUNT)" "${__this}"
	printEnvParameters "(SRC_PURGE_ROW_COUNT)" "${__this}" "${logdir}" "${unqid}" "TRUE"	
	
	# Return the path of the environment file
	__outValue="$(getRuntimeEnvFile "(logdir=${logdir},unqid=${unqid})")"
	
	clearParameters "(SRC_PURGE_ROW_COUNT)" "${__this}"
	clearParameters "(BOUNDARY_CONDITION)" "${__this}"
	clearParameters "${PARAM_BAG}" "${__this}"
	clearParameters "${dataHeader}" "${__this}"
	clearParameters "${__expectedParam}" "${__this}"
	
	__INDENT="${__INDENT::-3}"
	debug "################### END FUNCTION: ${__fnName}  ###################\n\n"
	
	echo "${__outValue}"

}





function beginCycleForApp()
{
	local __expectedParam='(appname,configfile,tmpdir,logdir,uid)'
	local __this="${FUNCNAME[0]} ${1}"
	local __fnName="${FUNCNAME[0]}"
	local __outValue=""

	# Extract param values from input arguments
	getParameters "${1}" "${__expectedParam}" "${__this}"
	
	local isBaseCycleExists=$( sqoopExecScalar "(query=SELECT COALESCE(MAX(CYCLE_ID)+1,0 ) AS IS_BASE_CYCLE_EXISTS FROM PURGE_CYCLE_DETAIL WHERE APP_NAME='${appname}'~configName=APP~configfile=${configfile}~tmpdir=${tmpdir}~logdir=${logdir}~uid=${uid}):delim='~';" )


	[[ "${isBaseCycleExists:=}" == "" ]] && emergency "Failed to get value of IS_BASE_CYCLE_EXISTS in Function Call : ${__this}"
	
	info "Fetched IS_BASE_CYCLE_EXISTS Using Sqoop Execute Scalar Output: ## ${isBaseCycleExists} ##"
	
	[[ "${isBaseCycleExists}" == "0" ]] && emergency "Base Cycle Entry For App : ## ${appname} ## Not Found In PURGE_CYCLE_DETAIL."
	
	local isAnyCycleAlreadyOpen=$( sqoopExecScalar "(query=SELECT COUNT(*) AS IS_CYCLE_ALREADY_OPEN FROM PURGE_CYCLE_DETAIL WHERE CYCLE_END_TS IS NULL AND APP_NAME='${appname}'~configName=APP~configfile=${configfile}~tmpdir=${tmpdir}~logdir=${logdir}~uid=${uid}):delim='~';" )
	
	[[ "${isAnyCycleAlreadyOpen:=}" == "" ]] && emergency "Failed to get value of IS_CYCLE_ALREADY_OPEN in Function Call : ${__this}"
	
	info "Fetched IS_CYCLE_ALREADY_OPEN Using Sqoop Execute Scalar Output: ## ${isAnyCycleAlreadyOpen} ##"
	
	[[ "${isAnyCycleAlreadyOpen}" != "0" ]] && emergency "Cycle Already Open For App : ## ${appname} ## In PURGE_CYCLE_DETAIL. Close All Open Cycle To Proceed"
	
	info "Good to proceed with creation of new Cycle for processing. Intiate Cycle Opening.."

	local isCycleOpenSuccessful=$( sqoopExecNonQuery "(query=INSERT INTO PURGE_CYCLE_DETAIL(APP_NAME,CYCLE_START_TS) VALUES ('${appname}',CURRENT_TIMESTAMP)~configName=APP~configfile=${configfile}~tmpdir=${tmpdir}~logdir=${logdir}~uid=${uid}):delim='~';" )

	[[ "${isCycleOpenSuccessful:=0}" == "0" ]] && emergency "Failed to open cycle for App : ## ${appname} ## in Function Call : ${__this}"
	
	[[ "${isCycleOpenSuccessful:=}" != "1" ]] && emergency "Error while trying to open cycle for App : ## ${appname} ## in table: PURGE_CYCLE_DETAIL"
	
	info "Cycle Opened Successfully."

	local getMaxCycleId=$( sqoopExecScalar "(query=SELECT COALESCE(MAX(CYCLE_ID),0) AS MAX_CYCLE_ID FROM PURGE_CYCLE_DETAIL WHERE CYCLE_END_TS IS NULL AND APP_NAME='${appname}'~configName=APP~configfile=${configfile}~tmpdir=${tmpdir}~logdir=${logdir}~uid=${uid}):delim='~';" )
	
	[[ "${getMaxCycleId:=}" == "" ]] && emergency "Failed to get value of MAX_CYCLE_ID in Function Call : ${__this}"
	
	info "Fetched MAX_CYCLE_ID Using Sqoop Execute Scalar Output: ## ${getMaxCycleId} ##"
	
	[[ "${getMaxCycleId}" == "0" ]] && emergency "Error while trying to open cycle for App : ## ${appname} ## in table: PURGE_CYCLE_DETAIL"
	
	info "Good to proceed with creation of new Cycle for processing. Intiate Cycle Opening.."
	
	__outValue="${getMaxCycleId}"
	
	clearParameters "${__expectedParam}" "${__this}"
	
	echo "${__outValue}"
}


function getWhereClause()
{
	local __expectedParam='(configName,configfile,tmpdir,logdir,uid)'
	local __this="${FUNCNAME[0]} ${1}"
	local __fnName="${FUNCNAME[0]}"
	local __outValue=""
	
	debug "################## BEGIN FUNCTION: ${__fnName}  ##################"
	INDENT="${INDENT}\t|"
	
	# Extract expected param values from input arguments
	getParameters "${1}" "${__expectedParam}" "${__this}"
	
	
	local configExpectedParam='(WHERE_CLAUSE_DERIVATION_QUERY)'
	local configParamString=$(genConfigParamString "( configName=${configName},configfile=${configfile},outdelim=~ ):delim=',';" )
	
	
	# Get the value of the sqoop scalar commmand
	getParameters "${configParamString}" "${configExpectedParam}" "${__this}"

	# get the list of variables used in the sqoop command and read thier values from config as well.
	# example: SQOOP_EXEC_SCALAR_COMMAND="select ${a} from ${b}" will return : ( a,b )
	local configRequiredParam=$( echo $(echo ${WHERE_CLAUSE_DERIVATION_QUERY} | \
	awk 'BEGIN{ RS="[\$}]"} !/^{query*/{print $0}' | grep '^{' | sed 's/^{//1') | \
	awk 'BEGIN { print "("; } {gsub(/ /,",");print;} END { print ")"; }' | tr '\n' ' ');
	
	getParameters "${configParamString}" "${configRequiredParam}" "${__this}"
	
	local query=$(eval "echo ${WHERE_CLAUSE_DERIVATION_QUERY}")
	
	local whereClause=$( sqoopExecScalar "(query=${query}~configName=${configName}~configfile=${configfile}~tmpdir=${tmpdir}~logdir=${logdir}~uid=${uid}):delim='~';" )


	[[ "${whereClause:=}" == "" ]] && emergency "Failed to get value of WHERE_CLAUSE_DERIVATION_QUERY in Function Call : ${__this}"
	
	info "Fetched WHERE_CLAUSE_DERIVATION_QUERY Using Sqoop Execute Scalar Output: ## ${whereClause} ##"
	
	
	clearParameters "${configRequiredParam}" "${__this}"
	clearParameters "${configExpectedParam}" "${__this}"
	clearParameters "${__expectedParam}" "${__this}"
	
	__outValue="${whereClause}"
	
	INDENT="${INDENT::-3}"
	debug "################### END FUNCTION: ${__fnName}  ###################\n\n"	
	
	echo "${__outValue}"
}

function getMaxRunDate4mQueueTable()
{

	local __expectedParam="(configfile,tmpdir,logdir,uid)"
	local __this="${FUNCNAME[0]} ${1}"
	local __fnName="${FUNCNAME[0]}"
	
	# Extract param values from input arguments
	getParameters ${1} ${__expectedParam} ${__this}
	
	local maxDate=$( tdSqoopExecScalar "(query=SELECT CAST(MAX(LOG_DT) AS FORMAT 'YYYY-MM-DD') AS MAX_LOG_DT FROM PURGE_QUE_TBL,configName=PUR_HDP_PURGE_QUE_TBL,configfile=${configfile},tmpdir=${tmpdir},logdir=${logdir},uid=${uid})" ) 

	
	[[ "${maxDate:-}" ]] || emergency "Failed to get value of Max date in Function Call : ${__this}"
	
	info "Fetched Max Date Using Teradata Sqoop Execute Scalar Output: ## ${maxDate} ##"
	
	# Clear argument variables from the environment
	clearParameters ${__expectedParam} ${__this}
	
	echo ${maxDate#*=};
	
}







function prepSqoopCommandList4mQueueTable()
{

	local __expectedParam="(configfile,tmpdir,logdir,uid)"
	local __this="${FUNCNAME[0]} ${1}"
	local __fnName="${FUNCNAME[0]}"
	
	
	# Extract param values from input arguments
	getParameters ${1} ${__expectedParam} ${__this}
	
	local MAX_LOG_DT=$( getMaxRunDate4mQueueTable "(configfile=${configfile},tmpdir=${tmpdir},logdir=${logdir},uid=${uid})" )
	
	
	
	local tdQueryOutFile=$( tdSqoopExecQuery "(query=SELECT Q.DB_NM,Q.TBL_NM,Q.COL_NM1,Q.COL_VAL1,Q.COL_NM2,Q.COL_VAL2,Q.COL_NM3,Q.COL_VAL3,Q.COL_NM4,Q.COL_VAL4,Q.PURGE_ROW_CNT FROM PURGE_QUE_TBL Q ,PURGE_RUL_TBL R WHERE Q.LOG_DT=TO_DATE('${MAX_LOG_DT}') AND Q.TBL_NM = R.TBL_NM AND R.ACTV_ROW_IND = 1 AND R.HDP_ACTV_ROW_IND = 1|configName=PUR_HDP_PURGE_QUE_TBL|configfile=${configfile}|tmpdir=${tmpdir}|logdir=${logdir}|uid=${uid}):delim='|';" );

	
	[[  -s "${tdQueryOutFile}"  ]] || emergency "No Tables Found For Archival In Function Call : ${__this} "
	
	info "Archival Table List Extracted Successfully In Tmp File: ## ${tdQueryOutFile} ##"
		
	local tableHeaderList=$( cat "${tdQueryOutFile}" | sed -n '/|.*/p' | head -1 | sed -e 's/\s\s*|\s\s*/,/g' -e 's/[()]/_/g' -e 's/^|\s*/(/1' -e  's/\s*[,|]$/)/1'  )
	
	
	local tableDataList=""
	
	cat ${tdQueryOutFile} | sed -n '/|.*/p' | sed -n '2,$p' | while read line ; do
		
		tableDataList=$( echo "${line}" | sed -n '/|.*/p' | tail -1 | sed -e 's/\s\s*|\s\s*/,/g' -e 's/^|\s*/(/1' -e 's/\s*[,|]$/)/1' )
		mapParameters "${tableDataList}" "${tableHeaderList}" "${__this}"
		
		info "Processing for Table : ${DB_NM}.${TBL_NM}"
		info "Extracted Column Header List : ${tableHeaderList}"
		info "Mapping Following Data With The Extracted Header List : ${tableDataList}"		
		

		if [ ${PURGE_ROW_CNT} != "0" ]
		then

			QUERY_PART='SELECT * FROM '${DB_NM}'.'${TBL_NM}' WHERE '

			if [ ${COL_NM1} != "null" ]
			then
				QUERY_PART=${QUERY_PART}${COL_NM1}'<=TO_DATE('\'${COL_VAL1}\'')'
			fi

			if [ ${COL_NM2} != "null" ]
			then
				if [ ${COL_NM1} != "null" ]
				then
					QUERY_PART=${QUERY_PART}" AND "${COL_NM2}"=""'"${COL_VAL2}"'"
				else
					QUERY_PART=${QUERY_PART}'SUBSTR('${COL_NM2}',1,4)<''SUBSTR('"'"${COL_VAL2}"'"',1,4)'" OR "'(''SUBSTR('${COL_NM2}',1,4)=''SUBSTR('"'"${COL_VAL2}"'"',1,4)'
				fi
			fi

			if [ ${COL_NM3} != "null" ]
			then
				if [ ${COL_NM2} != "null" ]
				then
					QUERY_PART=${QUERY_PART}' AND \"'${COL_NM3}'\"<='\'${COL_VAL3}\'')'
				else
					QUERY_PART=${QUERY_PART}'\"'${COL_NM3}'\"'"<=""'"${COL_VAL3}"'"')'
				fi
			fi

			if [ ${COL_NM4} != "null" ]
			then
				if [ ${COL_NM3} != "null" ]
				then
					QUERY_PART=${QUERY_PART}" AND "${COL_NM4}"<="${COL_VAL4}
				else
					QUERY_PART=${QUERY_PART}${COL_NM4}"<="${COL_VAL4}
				fi
			fi

			echo "${QUERY_PART} AND \\\$CONDITIONS" > ${logdir}/${TBL_NM}.sql
		
		else
			notice "No Records Found For Hadoop Archival In Table : ${DB_NM}.${TBL_NM}"
		fi
	done

	clearParameters "${tableHeaderList}" "${__this}"
	
	
	 
	
	cat ${tdQueryOutFile}
	
	
	
	
	
	# Clear argument variables from the environment
	clearParameters ${__expectedParam} ${__this}
	
	echo ${MAX_LOG_DT#*=};
	
}
