#!/usr/bin/env bash
#
#---------------
#  DESCRIPTION:
#---------------
#  - This is a function library which contains functions which will be responsible for taking the  
#    input line as input and parse that line to return the commands which will then be executed by the 
#    decoupler framework. The idea behind this is to create a layer between the input file format and  
#    functionality provided by the framework.
#
#
#
#---------------
#  USAGE:
#---------------
#  - Usage:  source helperCmdRdr.sh
#
#---------------
#  VERSION: 1.0.0
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


### Extract Unix Command
##############################################################################
# -----------------------------------
# Below function takes as input any line of text and extracts the unix command from the last instance
# of command tag : #{cmd: any unix command}# present in that line.
#
# Usage: extUnixCmd '(inputString={input line})'
# Usage examples: extUnixCmd '(inputString=<env:e2 path="#{cmd:ls -lrt | tail -1}#" default="#{cmd: echo hi}#"/>)'
# e.g for inputString : <env:e2 path="#{cmd:ls -lrt | tail -1}#" default="#{cmd: echo hi}#"/>
# it will return: echo hi
#
##VERSION CONTROL LOG:
# Update: Functions modfied to use the new param passing approach with help of paramHelper.sh - Manish Dixit : 02-Dec-2017
# -----------------------------------
function extUnixCmd()
{
	local __expectedParam="(inputString)"
	local __this="${FUNCNAME[0]} ${1}"
	local __fnName="${FUNCNAME[0]}"
	
	# Extract param values from input arguments
	getParameters "${1}" "${__expectedParam}" "${__this}"
	
	# ltrim & rtrim the input line and assigning to local variable
	local inputLine=$( echo "${inputString}" | tail -1 | sed 's/^\s*//g' | sed 's/\s*$//g' );
	
	local extractedCmd="";
	# Extract the last command tag from the input line 
	# e.g for input line : <env:e2 path="#{cmd:ls -lrt | tail -1}#" default="#{cmd: echo hi}#"/>
	# fetch the part : #{cmd: echo hi}#
	
	extractedCmd=$( echo "${inputLine}" | sed 's/^.*#{cmd:\([^{]*}#\).*$/#{cmd:\1/1' );
	
	# From the extractedCmd above extract only the part which contains the command which will be executed in unix
	# e.g from the extracted value above: #{cmd: echo hi}#
	# extract: echo hi
	
	extractedCmd=$( echo "${extractedCmd}" | sed "s/^#{cmd:\s*//1" | sed "s/}#$//1");
	
	# Clear argument variables from the environment
	clearParameters "${__expectedParam}" "${__this}"	
	
	echo ${extractedCmd};
}


### Extract Env Command
##############################################################################
# -----------------------------------
# Below function takes as input any line of text and extracts the env varaible name from the last instance
# of env tag : #{env: e1.varName}# present in that line.
#
# Usage: extEnvCmd '(inputString={input line})'
# Usage examples: extEnvCmd '(inputString=<param name="INPUT_FILE" value="#{env:e1.dirName}#/#{env:e1.fileName}#" default=""/>)'
# e.g for inputString : '<param name="INPUT_FILE" value="#{env:e1.dirName}#/#{env: e1.fileName}#" default=""/>'
# it will return: e1.fileName
#
##VERSION CONTROL LOG:
# Update: Functions modfied to use the new param passing approach with help of paramHelper.sh - Manish Dixit : 02-Dec-2017
# -----------------------------------
function extEnvCmd()
{
	local __expectedParam="(inputString)"
	local __this="${FUNCNAME[0]} ${1}"
	local __fnName="${FUNCNAME[0]}"
	
	# Extract param values from input arguments
	getParameters "${1}" "${__expectedParam}" "${__this}"
	
	# ltrim & rtrim the input line and assigning to local variable
	local inputLine=$( echo "${inputString}" | tail -1 | sed 's/^\s*//g' | sed 's/\s*$//g' );
	
	local extractedCmd="";
	# Extract the last env tag from the input line 
	# e.g for input line : '<param name="INPUT_FILE" value="#{env:e1.dirName}#/#{env:e1.fileName}#" default=""/>'
	# fetch the part : #{env:e1.fileName}#
	
	extractedCmd=$( echo "${inputLine}" | sed 's/^.*#{env:\([^{]*}#\).*$/#{env:\1/1' );
	
	# From the extractedCmd above extract only the part which contains the name of the env variable
	# e.g from the value: #{env:e1.fileName}#
	# extract: e1.fileName
	
	extractedCmd=$( echo "${extractedCmd}" | sed "s/^#{env:\s*//1" | sed "s/}#$//1");

	# Clear argument variables from the environment
	clearParameters "${__expectedParam}" "${__this}"
	
	echo ${extractedCmd};
}


### Extract Eval Command
##############################################################################
# -----------------------------------
# Below function takes as input any line of text and extracts the Eval variable name from the last instance
# of eval tag : #{env: e1.varName}# present in that line.
#
# Usage: extEvalCmd '(inputString={input line})'
# Usage examples: extEvalCmd '(inputString=<param name="INPUT_FILE" value="#{eval:e1.cycleid}#/#{eval:e2.procid}#" default=""/>)'
# e.g for inputString : '<param name="INPUT_FILE" value="#{eval:e1.cycleid}#/#{eval:e2.procid}#" default=""/>'
# it will return: e2.procid
#
##VERSION CONTROL LOG:
# Update: Functions modfied to use the new param passing approach with help of paramHelper.sh - Manish Dixit : 02-Dec-2017
# -----------------------------------
function extEvalCmd()
{
	local __expectedParam="(inputString)"
	local __this="${FUNCNAME[0]} ${1}"
	local __fnName="${FUNCNAME[0]}"
	
	# Extract param values from input arguments
	getParameters "${1}" "${__expectedParam}" "${__this}"
	
	# ltrim & rtrim the input line and assigning to local variable
	local inputLine=$( echo "${inputString}" | tail -1 | sed 's/^\s*//g' | sed 's/\s*$//g' );
	
	local extractedCmd="";
	# Extract the last eval tag from the input line 
	# e.g for input line : '<param name="INPUT_FILE" value="#{eval:e1.cycleid}#/#{eval:e2.procid}#" default=""/>'
	# fetch the part : #{eval:e2.procid}#
	
	extractedCmd=$( echo "${inputLine}" | sed 's/^.*#{procid:\([^{]*}#\).*$/#{procid:\1/1' );
	
	# From the extractedCmd above extract only the part which contains the name of the eval variable
	# e.g from the value: #{eval:e2.procid}#
	# extract: e2.procid
	
	extractedCmd=$( echo "${extractedCmd}" | sed "s/^#{eval:\s*//1" | sed "s/}#$//1");
	
	
	# Clear argument variables from the environment
	clearParameters "${__expectedParam}" "${__this}"
	
	echo ${extractedCmd};
}

### Extract Attribute Value 
##############################################################################
# -----------------------------------
# Below function takes as input an attribute name and a line of text and extracts 
# the attribute value from the input line. If the attribute is not found in the 
# input line then the function returns NULL.
#
# Usage: readAttribValue '(attribute={attribute name},inputString={input line})'
# Usage examples: readAttribValue '(attribute=path,inputString=<env:e2 path="#{cmd:ls -lrt | tail -1}#" default="#{cmd: echo hi}#"/>)' 
# e.g for inputString : <env:e2 path="#{cmd:ls -lrt | tail -1}#" default="#{cmd: echo hi}#"/>
#       & attribute   : path
# it will return: #{cmd:ls -lrt | tail -1}#
#
##VERSION CONTROL LOG:
# Update: Functions modfied to use the new param passing approach with help of paramHelper.sh - Manish Dixit : 02-Dec-2017
# -----------------------------------
function readAttribValue()
{
	local __expectedParam="(attribute,inputString)"
	local __this="${FUNCNAME[0]} ${1}"
	local __fnName="${FUNCNAME[0]}"
	
	# Extract param values from input arguments
	getParameters "${1}" "${__expectedParam}" "${__this}"
	
	local attribName=$( echo "${attribute}" | tail -1 | sed 's/^\s*//g' | sed 's/\s*$//g' );
	local inputLine=$( echo "${inputString}" | tail -1 | sed 's/^\s*//g' | sed 's/\s*$//g' );
	local attribValue=""
	
	# check if input line contains the requested attribute
	if [[ ${inputLine} =~ .*${attribName}\=\".* ]];
	then
	   attribValue=$(echo "${inputLine}" | sed "s/^.*${attribName}=\"//1"  );
	   attribValue=${attribValue%\"*/>};
	   attribValue=${attribValue%\"*=*};
	fi
	
	# Clear argument variables from the environment
	clearParameters "${__expectedParam}" "${__this}"
	
	echo ${attribValue:-NULL};
	
}




### Apply Env Command
##############################################################################
# -----------------------------------
# Below function takes as input the Env command line and any line of text 
# on which the the Env command has to be applied. Based the Env command the below 
# function will open the respective env file and will replace the values of the 
# env tags present in the input line with the corresponding values present for those 
# variables present in the env file. If the variable is not present in the given env
# file but is being referenced in the input line then it is replaced with NULL. 
# Also if the env file is not found then the process ABORTS.
#
# Usage: ApplyEnvCommand '(commandLine=<env:e1 path="/home/dixitm/testScripts/envfile1"/>, 
#                          inputString=<param name="INPUT_FILE" value="#{env:e1.dirName}#/#{env: e1.fileName}#" default=""/>)'
#
# Assuming the env file : /home/dixitm/testScripts/envfile1 contains below entries :
# dirName=/tmp
# fileName=file1.txt
#
# e.g line:  '<param name="INPUT_FILE" value="#{env:e1.dirName}#/#{env: e1.fileName}#" default=""/>' 
#             will be changed to '<param name="INPUT_FILE" value="/tmp/file1.txt" default=""/>' 
#
# e.g line:  '<param name="INPUT_FILE" value="#{env:e1.dir00Name}#/#{env: e1.file00Name}#" default=""/>' 
#             will be changed to '<param name="INPUT_FILE" value="/NULL/NULL" default=""/>' 
#
##VERSION CONTROL LOG:
# Update: Functions modfied to use the new param passing approach with help of paramHelper.sh - Manish Dixit : 02-Dec-2017
# -----------------------------------
# Apply Env Command

function ApplyEnvCommand()
{
	local __expectedParam="(commandLine,inputString)"
	local __this="${FUNCNAME[0]} ${1}"
	local __fnName="${FUNCNAME[0]}"
	
	# Extract param values from input arguments
	getParameters "${1}" "${__expectedParam}" "${__this}"
	
	#ltrim & rtrim the input command and assing to local variable
	local inputCommand=$( echo "${commandLine}" | tail -1 | sed 's/^\s*//g' | sed 's/\s*$//g' );
	local inputLine="${inputString}";
	local outputLine="${inputString}";
	
	local cmdPrefix=$( echo ${inputCommand} | sed 's/\s/ /g' | sed 's/\(^<env:\)\([^ ]*\).*$/\2/1' );
	
	local envFilePath=$( readAttribValue '(attribute=path,inputString=${inputCommand})' );
	
	
	
	#[[ -f "${envFilePath}" ]]	 || emergency "Failed to apply command ${inputCommand} as the env file is not found"
	[[ -f "${envFilePath}" ]]	 || echo "Failed to apply command ${inputCommand} as the env file is not found"
	
	# Save current IFS
	SAVEIFS=${IFS};
	# Change IFS to new line. 
	IFS=$'\n';

	#read xml file in an array
	declare -a varNameList;
	varNameList=( $(cat ${envFilePath} | sed '
						# Ignore comments lines from the env file, comment lines should always begin with #
						/^\s*#.*/d
						# Extract variable name from the entries in file and add to the array
						s/\(^[^=]*\)=.*/\1/1') );

	declare -a varValueList
	varValueList=( $(cat ${envFilePath} | sed '
						# Ignore comments lines from the env file, comment lines should always begin with #
						/^\s*#.*/d
						# Extract variable name from the entries in file and add to the array
						s/^[^=]*=//1') );
	

	# Restore IFS
	IFS=${SAVEIFS};
	
	
	local execCommand="";
	local replaceString="";
	local bfrCommandPart="";
	local aftrCommandPart="";
	local counter=0;
	local currVarName="";
	local currVarValue="";
		
	
	while :
	do
		if [[ "${outputLine}" != "${outputLine#*\#\{env:*\}\#}" ]]; then
			execCommand="";
			replaceString="";
			bfrCommandPart="";
			aftrCommandPart="";
			counter=0;
			currVarName="";
			currVarValue="";
					
			execCommand=$(extEnvCmd '(inputString=${outputLine})');
			
			
			for currVarName in "${varNameList[@]}"
			do
				currVarName=$(echo ${cmdPrefix}.${currVarName});
				currVarValue=${varValueList[${counter}]};
				if [[ "${execCommand}" = "${currVarName}" ]];
				then
					replaceString=${currVarValue};
					break;
				fi
				counter=$((counter+1));
			done
					
			replaceString=${replaceString:-NULL};
			
			#Extract the part of the command after the last env tag
			#e.g from the command : <env:e2 path="#{cmd:ls -lrt | tail -1}#" default="#{cmd: echo hi}#"/>
			#it will extract the part : "/>
			aftrCommandPart=${outputLine##*\#\{env:*\}\#};
			
			#Extract the part of the command before the first command clause
			#e.g from the command : <env:e2 path="#{cmd:ls -lrt | tail -1}#" default="#{cmd: echo hi}#"/>
			#it will extract the part : <env:e2 path="
			bfrCommandPart=${outputLine%\#\{env:*\}\#*};
			
			#combine the bfrCommandPart,aftrCommandPart and the calculated replaceString
			#to form the output which contains the run time evaluated value of the 
			outputLine="${bfrCommandPart}${replaceString}${aftrCommandPart}";
			
			continue;
		fi
		break;
	done
	
	# Clear argument variables from the environment
	clearParameters "${__expectedParam}" "${__this}"
	
	echo ${outputLine};
}



### Unix command resolution 
##############################################################################
# -----------------------------------
# Below function takes as input any line of text and replaces each instance 
# of #{cmd: any unix command}# in that line with the run time value of that
# command and if the command is not a valid command then it is replaced with
# NULL.
#
# usage: unixCommandResolver '(commandLine=<env:e2 path="#{cmd:pwd}#" default="#{cmd: echo hi}#"/>)'
#
# e.g line: '<env:e2 path="#{cmd:pwd}#" default="#{cmd: echo hi}#"/>' 
#           will be changed to '<env:e2 path="/home/dixitm" default="hi"/>'
#
# e.g  line: Default="#{cmd: fwd}#" will be changed to Default="NULL" in function output
#
##VERSION CONTROL LOG:
# Update: Functions modfied to use the new param passing approach with help of paramHelper.sh - Manish Dixit : 02-Dec-2017
# -----------------------------------
# Unix Command Resolver
function unixCommandResolver()
{
	local __expectedParam="(commandLine=NULL)"
	local __this="${FUNCNAME[0]} ${1}"
	local __fnName="${FUNCNAME[0]}"
	
	
	# Extract param values from input arguments
	getParameters "${1}" "${__expectedParam}" "${__this}"
	

	#ltrim & rtrim the input command and assigning to local variable
	local processCommand=$( echo "${commandLine}" | tail -1 | sed 's/^\s*//g' | sed 's/\s*$//g' );
	local replaceString="";
	local execCommand="";
	local bfrCommandPart="";
	local aftrCommandPart="";

	
	# loop through the input command to resolve command tags one by one
	# e.g for input command : <env:e2 path="#{cmd:pwd}#" default="#{cmd: echo hi}#"/>
	# it will run 2 iterations
	# during first iteration command tag: #{cmd: echo hi}# is extracted and replaced with its runtime value
	# <env:e2 path="#{cmd:pwd}#" default="hi"/>
	# during second iteration command tag: #{cmd:ls -lrt | tail -1}# is extracted and replaced with its runtime value
	# <env:e2 path="/home/dixitm" default="hi"/>
	
	while :
	do
		if [[ "${processCommand}" != "${processCommand#*\#\{cmd:*\}\#}" ]]; then
			replaceString="";
			execCommand="";
			bfrCommandPart="";
			aftrCommandPart="";
			
			execCommand=$(extUnixCmd "(inputString=${processCommand})");
			
			# Below command will eval the execCommand and put the output in the variable
			set +o errexit; 
			
			# error expected in the below lines and it is also handled in the below lines so no issues.
			replaceString=$( eval "${execCommand}" 2> /dev/null  | tail -1);
			replaceString=${replaceString:-NULL};
			
			# error is no more expected
			set -o errexit;
			
			#Extract the part of the command after the last command tag
			#e.g from the command : <env:e2 path="#{cmd:ls -lrt | tail -1}#" default="#{cmd: echo hi}#"/>
			#it will extract the part : "/>
			aftrCommandPart=${processCommand##*\#\{cmd:*\}\#};
			
			#Extract the part of the command before the last command tag
			#e.g from the command : <env:e2 path="#{cmd:ls -lrt | tail -1}#" default="#{cmd: echo hi}#"/>
			#it will extract the part : <env:e2 path="#{cmd:ls -lrt | tail -1}#" default="
			bfrCommandPart=${processCommand%\#\{cmd:*\}\#*};
			
			#combine the bfrCommandPart,aftrCommandPart and the calculated replaceString
			#to form the output which contains the run time evaluated value of the 
			processCommand="${bfrCommandPart}${replaceString}${aftrCommandPart}";
			
			continue;
		fi
		break;
	done
	
	# Clear argument variables from the environment
	clearParameters "${__expectedParam}" "${__this}"
	
	#and finally return the the resolved command value.
	echo ${processCommand};
}


