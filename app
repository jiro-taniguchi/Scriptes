#!/bin/bash
#===============================================================================
#
#          FILE:  app.sh
# 
#         USAGE:  ./app.sh 
# 
#   DESCRIPTION:  
# 
#       OPTIONS:  ---
#  REQUIREMENTS:  ---
#          BUGS:  ---
#         NOTES:  ---
#        AUTHOR:  Kazuma Yoshiyuki (), mohamed.ladghem@kinkazma.ga
#       COMPANY:  KINKAZMA.GA
#       VERSION:  1.0
#       CREATED:  25/06/2018 20:51:03 CEST
#      REVISION:  ---
#===============================================================================

NAME="INIT" # Your name of the app
DEPENDENCIES="" # Dependencies needed
APP_DEPENDENCIES=${APP_DEPENDENCIES}"${DEPENDENCIES}"
APP_NAME=${APP_NAME}"${NAME}"  
DOMAIN="hakase.lab"

function PHASE2(){

	:
	# Votre code ici.

}

function HELPER(){
	local OPTIND
	local OPTARG
	shift


	HELP="""${HELP}
	------- ${0} Options -------
	-h	- Show this help
	"""
	while getopts 'h' OPTIONS;do
		case "${OPTIONS}" in
			h) echo "${HELP}"; exit 0
				;;
			*) echo "Did not understand"; exit 0
				;;
		esac
	done
	if test $((${OPTIND} -1)) -eq 0;then
		echo "${HELP}"
		exit 0
	fi

}

if test ${0} = ${BASH_SOURCE};then
	echo "Must be run from template."
	exit 0
fi


