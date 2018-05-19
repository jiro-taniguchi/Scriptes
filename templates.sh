#!/bin/bash
#===============================================================================
#
#          FILE:  templates.sh
# 
#         USAGE:  ./templates.sh 
# 
#   DESCRIPTION:  Scripte de base pour l'execution de container applicatif.
# 
#       OPTIONS:  ---
#  REQUIREMENTS:  ---
#          BUGS:  ---
#         NOTES:  ---
#        AUTHOR:  Kazuma Yoshiyuki (), mohamed.ladghem@kinkazma.ga
#       COMPANY:  KINKAZMA.GA
#       VERSION:  1.0
#       CREATED:  18/05/2018 00:27:31 CEST
#      REVISION:  ---
#===============================================================================
# Jolie mais pas fonctionelle
# cat /etc/os-release| grep -o -P '(?<=VERSION_ID\=).[0-9]{1,2}(\.[0-9]{1,2})?'

#
#==========================================================================
#  This program is free software; you can redistribute it and/or modify 
#  it under the terms of the GNU General Public License as published by 
#  the Free Software Foundation; either version 2 of the License, or    
#  (at your option) any later version.                                  
#==========================================================================
#

## COLORS VARS
RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

## REGEXP VARS
RE_NUMERIC='^[0-9]+$'

## SHELL RUNTIME
PS3="Your choice:"
APP_NAME="APP_SMTP"
D_TRIGG=false

## LXC VARS
#LXC_IP=192.168.113.58/24
LXC_IP=""

function error(){
	echo -en "${RED}[ERR] $1${NC}\n"
	if test $# -eq 1;then
		exit 100
	fi
	exit $2
}

function confirm(){
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
	if test $(df . --output=pcent |tail -n1|sed 's/%//') -gt 95;then
		warn "Near to hit the no more space avaible (>95%)"
	fi
			
}

function PHASE1(){
	info "PHASE1 Starting"
	debug "Looking for old container"
	local APP_NAME_TEST=$(lxc-ls ${APP_NAME})
	if ! test -z ${APP_NAME_TEST};then
		confirm "${APP_NAME} found, do you want to erase it ?" && APP_CLEAN 
		if test ${?} -ne 0;then
			error "Can't go further"
		fi
	fi		
	info "Creation du container ${APP_NAME}"
	lxc-create -n ${APP_NAME} -t download -- -d ubuntu -r bionic -a amd64 >/dev/null 2>&1
	if test ${UID} -eq 0 ;then 
		LXC_PATH=$(grep -oP '(?<=lxc.lxcpath=).*' /etc/lxc/lxc.conf)
		if test -z ${LXC_PATH};then
			LXC_PATH=/var/lib/lxc
		fi
	else
		LXC_PATH=$(grep -oP '(?<=lxc.lxcpath=).*' ${HOME}/.config/lxc/lxc.conf)
		if test -z ${LXC_PATH};then
			LXC_PATH=${HOME}/.local/share/lxc
		fi
	fi
	APP_PATH=${LXC_PATH}/${APP_NAME}
	APP_CONFIG=${APP_PATH}/config
	APP_ROOTFS=${APP_PATH}/rootfs
	if ! test -z ${LXC_IP};then	
		case "${LXC_VERS}" in
			2) LXC_NET="lxc.network.ipv4.address = ${LXC_IP}" ;;
			3) LXC_NET="lxc.net.0.ipv4.address = ${LXC_IP}" ;;
		esac
		echo "${LXC_NET}" >> ${APP_CONFIG}
	fi
	sucess "PHASE1 Ended"
}
function PHASE2(){
	info "PHASE2 Starting"

}

function APP_START(){
	local _APP_NAME=${1:-${APP_NAME}}
	lxc-start -n ${_APP_NAME} 2>&1 | debug 
	if test ${PIPESTATUS[0]} -ne 0;then 
		error "Can't start ${_APP_NAME}"
	fi
	info "Started container ${_APP_NAME}"
	APP_PID=$(lxc-info -n ${_APP_NAME}| grep -i PID | cut -d":" -f2)
	return 0
}

function APP_CLOSE(){
	local _APP_NAME=${1:-${APP_NAME}}
	lxc-stop -n ${_APP_NAME} 2>&1 | debug
	if test ${PIPESTATUS[0]} -ne 0;then 
		error "Can't close ${_APP_NAME}"
	fi
	info "Closed container ${_APP_NAME}"

	return 0
}

function APP_CLEAN(){
	if test $(APP_STATE) -eq 0;then 
		APP_CLOSE
	fi
	local _APP_NAME=${1:-${APP_NAME}}
	lxc-destroy -n ${_APP_NAME} 2>&1| debug
	declare -a PIPCODE
	PIPECODE=${PIPESTATUS[@]}
	if test ${PIPECODE[0]} -ne 0 && test ${PIPECODE[0]} -ne 141;then 
		error "Can't destroy ${_APP_NAME}"
		echo ${PIPECODE[0]}
	fi
	info "Container ${APP_NAME} destroyed"
	return 0
}

function APP_STATE(){
	local _APP_NAME=${1:-${APP_NAME}}
	local STATE=$(lxc-info -n ${_APP_NAME} | grep -i "state"| cut -d':' -f 2) 
	if test ${STATE} = "RUNNING";then
		echo 0
		return 0
	elif test ${STATE} = "STOPPED";then
		echo 1
		return 1
	else
		warn "Unable to get ${_APP_NAME} state"
		echo 2
		return 2
	fi
}

function MAIN(){
	GET_INFO
	DO_VARS_SETTINGS
	PHASE1
	
}

MAIN
exit 0
