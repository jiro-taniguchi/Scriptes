#!/bin/bash
#===============================================================================
#
#          FILE:  templates.sh
# 
#         USAGE:  ./templates.sh 
# 
#   DESCRIPTION:  Scripte de base pour l'execution de container applicatif.
# 
#       OPTIONS:  -f -q -h -d
#  REQUIREMENTS:  lxc
#          BUGS:  Many at the moment.
#         NOTES:  ---
#        AUTHOR:  Kazuma Yoshiyuki (), mohamed.ladghem@kinkazma.ga
#       COMPANY:  KINKAZMA.GA
#       VERSION:  0.5
#       CREATED:  18/05/2018 00:27:31 CEST
#      REVISION:  ---
#===============================================================================
#
#
#==========================================================================
#  This program is free software; you can redistribute it and/or modify 
#  it under the terms of the GNU General Public License as published by 
#  the Free Software Foundation; either version 2 of the License, or    
#  (at your option) any later version.                                  
#==========================================================================
#
set -o nounset                                  # treat unset variables as errors
#===============================================================================
#   GLOBAL DECLARATIONS
#===============================================================================
declare -rx SCRIPT=${0##*/}                     # the name of this script
declare -rx mkdir='/bin/mkdir'                  # the mkdir(1) command

#===============================================================================
#   SANITY CHECKS
#===============================================================================
if [ -z "$BASH" ] ; then
	printf "$SCRIPT:$LINENO: run this script with the BASH shell\n" >&2
	exit 192
fi

if [ ! -x "$mkdir" ] ; then
	printf "$SCRIPT:$LINENO: command '$mkdir' not available - aborting\n" >&2
	exit 192
fi
stty -echo

trap EXIT_ON_INT INT TERM
#===============================================================================
#   MAIN SCRIPT
#===============================================================================
## COLORS VARS
RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

## REGEXP VARS
RE_NUMERIC='^[0-9]+$'

## DEFAULT VALUES 
PS3="Your choice:"
APP_NAME="APP_SMTP"
HIDE=' >/dev/null 2>&1'
## LXC VARS
#LXC_IP=192.168.113.58/24
LXC_IP=""
LXC_NET=""
## SOME VARS
HELP="""$(basename ${0}) - Templates.sh : Scriptes de base pour la création de container applicatifs

	-h 	-	Show this help.
	-f	-	Force creation of container.
	-d	-	Debug mode.
	-q	-	Quiet mode. (Assume -f)

	Created by Kinkazma - www.kinkazma.ml
"""
F_TRIGG=false
D_TRIGG=false
Q_TRIGG=false
function error(){
	echo -en "${RED}[ERR] $1${NC}\n"
	if test $# -eq 1;then
		exit 100
	fi
	exit $2
}

function quiet(){
	exec &>/dev/null
	F_TRIGG=true
}

function silent(){
	if test ${D_TRIGG} != "true"; then
		"${@}" >/dev/null 2>&1
	else
		"${@}"
	fi
}
function confirm(){
	stty echo
	if test ${F_TRIGG} = "true";then
		return 0
	fi
	SENTENCE=${1:="Are you sure about this ? "}
	SENTENCE=${SENTENCE}" (yes/no)"
	echo -en "${BLUE}[?] ${SENTENCE}${NC}\n"
	select answer in yes no;do
		case ${answer} in
			yes)  return 0;;
			no) return 1;;
			*) warn "Did not understant your choice !"
		esac
	done
	stty -echo
}


function info(){
	echo -en "\033[1m[-] ${1}${NC}\n"
}
function sucess(){
	echo -en "${GREEN}[+] $1${NC}\n"
}
function warn(){
	echo -en "${YELLOW}[!] $1${NC}\n"
}
function debug(){
	set +o nounset
  if test ${D_TRIGG} = true;then
    if [ -n "$1" ];then
      INPUT="$1"
    else
      read -t 0.1 INPUT
    fi
    [[ -z $INPUT ]] && exit 0
	  >&2 echo -en "\033[1m[${YELLOW}debug${NC}\033[1m]${NC} ${INPUT}\n"
  fi
}


function GET_INFO(){
	OS_NAME=$(cat /etc/os-release| grep -E "^ID=" | cut -d "=" -f2)
	OS_VERS=$(cat /etc/os-release| grep -E "^VERSION_ID=" | cut -d "=" -f2)
	BASH_VERS=$(bash --version | grep -o -E 'version [0-9]{1,2}\.[0-9]{1,2}' | awk '{print $2}')
	for interface in $(ls /sys/class/net | grep -v lo	);do
		if test "$(cat /sys/class/net/${interface}/carrier | grep -v -e lo  -e "*br0*" -e "*ovs*" )" = "1";then
			CONNECTED=true
			break
		else
			CONNECTED=false
		fi
	done
	
	# A voir si on dois ajouté des trucs
}

function DEBIAN_PKG_INSTALLED(){
	dpkg-query -s ${1}  2>/dev/null| grep -q "install ok installed" && echo 0 || echo 1
}

function REDHAT_PKG_INSTALLED(){
	rpm -q ${1} >/dev/null 2>1 && echo  0 || echo 1
}

function DO_VARS_SETTINGS(){
	if test -z ${APP_NAME};then
		warn "APP_NAME is not set"
		error "Can't proceed without APP_NAME filename"
	fi 
	case "${OS_NAME}" in
		"ubuntu") PKG_INSTALL="apt install -y"; PKG_QUERY="DEBIAN_PKG_INSTALLED"
			;;
		"fedora") PKG_INSTALL="dnf install -y"; PKG_QUERY="REDHAT_PKG_INSTALLED"
			;;
		"redhat") PKG_INSTALL="yum install -y"; PKG_QUERY="REDHAT_PKG_INSTALLED"
			;;
		"centos") PKG_INSTALL="yum install -y"; PKG_QUERY="REDHAT_PKG_INSTALLED"
			;;
		"debian") PKG_INSTALL="apt install -y"; PKG_QUERY="DEBIAN_PKG_INSTALLED"
			;;
	esac
	declare -a DEPENDENCIES
	DEPENDENCIES=( lxc )
	if ! test ${CONNECTED} = true;then
		error "Not connected to internet"
	fi
	for i in ${DEPENDENCIES[@]};do 
		if test $(eval "${PKG_QUERY} ${i}") -ne 0;then
			warn "Dependencie ${i} is missing"
			test ${UID} -eq 0 && info "Installing ${i}" && { eval "${PKG_INSTALL} ${i}" ; } || error "Can't install ${i}"
		fi
	done
	LXC_VERS=$(lxc-ls --version | cut -c 1)
	if ! test -r . ;then
		error "Can't write here"
	fi
		
}
function APP_CREATE(){
	local APP_DISTRIB_ID="alpine"
	local APP_DISTRIB_VERS="3.7"
 	local APP_DISTRIB_ARCH="amd64"
	if test $(df ${LXC_PATH} --output=pcent |tail -n1|sed 's/%//') -gt 95;then
		warn "Near to hit the no more space avaible (>95%)"
	fi
	info "Creation du container"
	lxc-create -n ${APP_NAME} -t download -- -d ${APP_DISTRIB_ID} -r ${APP_DISTRIB_VERS} -a ${APP_DISTRIB_ARCH} >/dev/null 2>&1 | debug
	return $?	
}
function APP_START(){
	local _APP_NAME=${1:-${APP_NAME}}
	local RESULT_CODE
	declare -a PIPECODE
	silent lxc-start -n ${_APP_NAME}  
	RESULT_CODE=$?
	if test ${RESULT_CODE} -ne 0 ;then 
		error "Can't start ${_APP_NAME}"
	fi
	info "Started container ${_APP_NAME}"
	APP_PID=$(lxc-info -n ${_APP_NAME}| grep -i PID | cut -d":" -f2)
	return 0
}

function APP_CLOSE(){
	local _APP_NAME=${1:-${APP_NAME}}
	declare -a PIPECODE
	lxc-stop -n ${_APP_NAME} 2>&1 | debug
	PIPECODE=(${PIPESTATUS[@]})
	if test ${PIPECODE[0]} -ne 0 && test ${PIPECODE[0]} -ne 141;then 
		error "Can't close ${_APP_NAME}"
	fi
	info "Closed container ${_APP_NAME}"

	return 0
}

function APP_CLEAN(){
	rm -rf ${LOCAL_MOUNT_ENTRY} 2>&1 | debug &&	info "Deleted local files" || warn "Erreur pendant la suppresions de ${LOCAL_MOUNT_ENTRY}"
	local CREATE_END_TRIGG=false
	if test $(APP_STATE) -eq 0;then 
		APP_CLOSE
	elif test $(APP_STATE) -eq 1;then
		info "${APP_NAME} is not running, cleaning..."
	else
		for i in $(seq 1 10);do
			debug "lxc-create may be in loading"
			ps -aux|grep lxc-create |grep -v grep | debug
			if test $? -ne 0;then
				CREATE_END_TRIGG=true
				sucess "No lxc-create are running at this stage" | debug
				break
			else
				sleep 1
			fi
		done
		if test ${CREATE_END_TRIGG} = "false";then
			LXC_CREATE_PID=$(ps -aux|grep lxc-create |grep -v grep | awk '{print $2}')
			! test -z ${LXC_CREATE_PID} && rm -rf ${APP_PATH} || error "Aborting ! Can't clean old files"
		fi
	fi
	declare -a PIPECODE
	local _APP_NAME=${1:-${APP_NAME}}
	lxc-destroy -n ${_APP_NAME} 2>&1| debug
	PIPECODE=(${PIPESTATUS[@]})
	if test ${PIPECODE[0]} -ne 0 && test ${PIPECODE[0]} -ne 141;then 
		error "Can't destroy ${_APP_NAME}"
		echo ${PIPECODE[0]}
	fi
	info "Container ${APP_NAME} destroyed"
	return 0
}
function EXIT_ON_INT(){
	APP_CLEAN || warn "Somthing went wrong during cleaning"
	exit $?
}

function APP_STATE(){
	local _APP_NAME=${1:-${APP_NAME}}
	local STATE=$(lxc-info -n ${_APP_NAME} 2>/dev/null | grep -i "state"| cut -d':' -f 2|tr -d " ") 
	if test "${STATE}x" = "RUNNINGx";then
		echo 0
		return 0
	elif test "${STATE}x" = "STOPPEDx";then
		echo 1
		return 1
	else
		warn "Unable to get ${_APP_NAME} state"| debug
		echo 2
		return 2
	fi
}

function GET_APP_IP(){
	APP_IP=$(lxc-info -n ${APP_NAME} | grep -oP '(?<=IP:).*')
	if test -z ${APP_IP};then
		warn "No IP found for ${APP_NAME} container" | debug
		return 1
	fi
	debug "${APP_NAME} IP : ${APP_IP}"
	echo ${APP_IP}
	return 0

}

function APP_EXEC(){
	declare -a PIPECODE
	local DONT_FAIL=${2:-false}
	silent lxc-attach -n ${APP_NAME} -- ash -c " ${1} "
	RESULT_CODE=${?}
	#PIPECODE=(${PIPESTATUS[@]})
	#if test ${PIPECODE[0]} -ne 0 && test ${PIPECODE[0]} -ne 141 && test ${DONT_FAIL} != "true" ;then 
	if test ${RESULT_CODE} -ne 0 && test ${DONT_FAIL} != true;then
		debug "Commande : ${1}"
		debug "Result code : ${RESULT_CODE}"
		error "Execution failed ${APP_NAME}"
	else
		debug "Commande : ${1}"
		sucess "Result code : ${RESULT_CODE}"| debug
	fi
	unset DONT_FAIL
	return ${RESULT_CODE}


}

function DISPLAY_VARS(){
	declare -a VARS
	VARS=( LXC_PATH APP_PATH LXC_NET APP_CONFIG APP_MOUNT_ENTRY LOCAL_MOUNT_ENTRY )
	for i in ${VARS[@]};do
		debug "${i}: $(eval echo \$${i})"
	done
}

function GET_CONF(){
	test $# -eq 2 || { error "Wrong usage of get_conf";	return 1; };
	APP_EXEC "grep -v -E \"^#\" ${1} | grep -i -q \"${2}\"" true || return 1; 
	VALUE=$(APP_EXEC "grep  \"${2}\" ${1} | cut -d'=' -f2 " true)
	if ! test -z "${VALUE}";then
		echo ${VALUE}; 
		return 0;   
	else 
		 return 1
	fi
}

function DEL_CONF(){
	test $# -eq 2 || { error "Wrong usage of del_conf";	return 1; };
	GET_CONF ${1} "${2}" &>/dev/null && APP_EXEC "sed -i \"/${2}/d\" ${1}" || error "Can't find ${2} in ${1}" | debug
	sucess "Deleted ${2} from ${1}" | debug
}

function SET_CONF(){
	test $# -eq 3 || { error "Wrong usage of set_conf";	return 1; };
  APP_EXEC "grep -vE '^#' ${1} | grep -iq \"${2}\" 2>&1" true  && { warn "Found same entry for ${2} = ${3}"; } | debug
	APP_EXEC sed\ -E\ -i\ \'s/\#?${2}.*/${2}="${3}"/\'\ ${1} || error "Set conf failed:
		FILE : ${1} 
		VARS : ${2}
		VALUE: ${3}
	"
	GET_CONF ${1} ${2} &>/dev/null || APP_EXEC "echo \"${2}=${3}\" >> ${1} "
	sucess "Added ${2}=${3} from ${1}" | debug
}

function COMMENT_CONF(){
	test $# -eq 2 || { error "Wrong usage of comment_conf";	return 1; };
	APP_EXEC sed\ -E\ -i\ \'s/${2}.*/\#${2}/\'\ ${1} || error "comment conf failed:
		FILE : ${1} 
		VARS : ${2}
	"
	sucess "Commented ${2} from ${1}" | debug

}

function ADD_CONF(){
	test $# -eq 2 || { error "Wrong usage of add_conf";	return 1; };
	GET_CONF ${1} "${2}" &>/dev/null || APP_EXEC "echo \"${2}\" >> ${1} " || error "add conf failed:
		FILE : ${1} 
		VARS : ${2}
	"
	sucess "Add conf ${2} from ${1}" | debug

}


function PHASE1(){
	info "PHASE1 Starting"
	debug "Looking for old container"
	local APP_NAME_TEST=$(lxc-ls ${APP_NAME})
	if test ${UID} -eq 0 ;then 
		LXC_PATH=$(grep -vE '^#' /etc/lxc/lxc.conf | grep lxc.lxcpath | cut -d"=" -f 2)
		if test -z ${LXC_PATH};then
			LXC_PATH=/var/lib/lxc
		fi
	else
		LXC_PATH=$(grep -vE '^#' ${HOME}/.config/lxc/lxc.conf | grep lxc.lxcpath | cut -d"=" -f 2)
		if test -z ${LXC_PATH};then
			LXC_PATH=${HOME}/.local/share/lxc
		fi
	fi
	APP_PATH=${LXC_PATH}/${APP_NAME}
	APP_CONFIG=${APP_PATH}/config
	APP_ROOTFS=${APP_PATH}/rootfs
	APP_MOUNT_ENTRY="srv/files/"
	LOCAL_MOUNT_ENTRY="./share_${APP_NAME}"

	if ! test -z ${APP_NAME_TEST};then
		confirm "${APP_NAME} found, do you want to erase it ?" && APP_CLEAN 
		if test ${?} -ne 0;then
			APP_CURRENT=$(grep -oP '(?<=^ID=).*' ${APP_ROOTFS}/etc/os-release )
			test "${APP_CURRENT}x" = "alpinex" && warn "We're using old APP_SMTP" ||	error "Can't go further, APP_SMTP is not alpine"

		else
			APP_CREATE
		fi
	else
		APP_CREATE
	fi
	mkdir -p ${LOCAL_MOUNT_ENTRY}
	if ! test -z ${LXC_IP};then	
		case "${LXC_VERS}" in
			2) LXC_NET="lxc.network.ipv4.address = ${LXC_IP}" ;;
			3) LXC_NET="lxc.net.0.ipv4.address = ${LXC_IP}" ;;
		esac
		echo "${LXC_NET}" >> ${APP_CONFIG}
	fi
	echo "lxc.mount.entry = $(realpath ${LOCAL_MOUNT_ENTRY}) ${APP_MOUNT_ENTRY} none bind,optional,create=dir 0 0" >> ${APP_CONFIG}
	info "Starting container"
	APP_START
	sucess "PHASE1 Ended"
	DISPLAY_VARS
}


####----------------------------------------
#  END OF TEMPLATE
####----------------------------------------

function DATABASE_CREATION(){

	SQL_DB_PATH="/srv/db"
	SQL_DB_NAME="mailuser.db"
	SQL_DB_FILE="${SQL_DB_PATH}/${SQL_DB_NAME}"
	SQL_CREATE_DATABASE="""
 CREATE TABLE expires (
   username varchar(100) not null,
   mailbox varchar(255) not null,
   expire_stamp integer not null,
   primary key (username, mailbox)
 );

 CREATE TABLE quota (
   username varchar(100) not null,
   bytes bigint not null default 0,
   messages integer not null default 0,
   primary key (username)
 );

CREATE TABLE users (
     username VARCHAR(128) NOT NULL,
     domain VARCHAR(128) NOT NULL,
     password VARCHAR(64) NOT NULL,
     home VARCHAR(255) NOT NULL,
     uid INTEGER NOT NULL,
     gid INTEGER NOT NULL,
     active CHAR(1) DEFAULT 'Y' NOT NULL
 );
	"""
	echo "${SQL_CREATE_DATABASE}" > ${LOCAL_MOUNT_ENTRY}/create.sql
	info "Database creation"
	APP_EXEC "mkdir -p ${SQL_DB_PATH}"
	APP_EXEC "sqlite3 ${SQL_DB_FILE} < ${APP_MOUNT_ENTRY}/create.sql 2>/dev/null" true
	info "Database created"

}


function PHASE2(){
	info "PHASE2 Starting"
	info "Doing an update"
	for i in {1..10};do
		GET_APP_IP 
		if test $? -eq 0;then
			break
		else 
			sleep 1
		fi
		test ${i} -eq 9 && error "Container don't have any IP address"
	done
	APP_EXEC "apk -q update"
	info "Installing depandencies"
	APP_EXEC  "apk add dovecot dovecot-sqlite postfix sqlite"
	DATABASE_CREATION
	DOVE_PATH="/etc/dovecot"
	DOVE_PATH_CONF="${DOVE_PATH}/conf.d"
	DOVE_MAIN_CONF="${DOVE_PATH}/dovecot.conf"
	DOVE_AUTH_CONF="${DOVE_PATH_CONF}/10-auth.conf"
	DOVE_MAIL_CONF="${DOVE_PATH_CONF}/10-mail.conf"
	SET_CONF ${DOVE_MAIN_CONF} login_greeting "Welcome to kinkazma"
	SET_CONF ${DOVE_MAIN_CONF} protocols "imap lmtp"
	SET_CONF ${DOVE_MAIN_CONF} listen "127.0.0.1"
	ADD_CONF ${DOVE_AUTH_CONF} "!include auth-sql.conf.ext"
	DEL_CONF ${DOVE_AUTH_CONF} "!include auth-passwdfile.conf.ext"
}

function MAIN(){
	GET_INFO
	DO_VARS_SETTINGS
	PHASE1
	PHASE2
	
}

#===============================================================================
#   ARGUMENT PARSING
#===============================================================================

while getopts "hfdq" COMMANDES;do
	case "${COMMANDES}" in
		f) F_TRIGG=true;;
		h) info "${HELP}";exit 0;;
		d) D_TRIGG=true;HIDE="";;
		q) Q_TRIGG=true;;
		*) error "Can't procceed this argument";;
	esac
done

if test ${Q_TRIGG} = true && test ${D_TRIGG} = true;then
	warn "Can't put those argument together"
	exit 1
fi

if test ${Q_TRIGG} = true;then
	quiet
fi

#===============================================================================
#   MAIN LAUNCH
#===============================================================================

MAIN

#===============================================================================
#   STATISTICS / CLEANUP
#===============================================================================
exit 0




