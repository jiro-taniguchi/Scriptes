#!/bin/bash
#===============================================================================
#
#          FILE:  data.sh
# 
#         USAGE:  ./data.sh 
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
#       CREATED:  27/05/2018 15:06:46 CEST
#      REVISION:  ---
#===============================================================================
## VARS 

APP_DEPENDENCIES=${APP_DEPENDENCIES}"dovecot dovecot-sqlite postfix sqlite"
APP_NAME=${APP_NAME}"SMTP"

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

function 10_MASTER(){
	data="""
	service imap-login {
  inet_listener imap {
	port = 143
  }
  inet_listener imaps {

  }
}
service pop3-login {
  inet_listener pop3 {
  }
  inet_listener pop3s {
  }
}
service lmtp {
  unix_listener lmtp {
	mode = 0666
  }
}
service imap {

}
service pop3 {
}

service auth {
  unix_listener /var/spool/postfix/private/auth {
    mode = 0666
  }
  unix_listener auth-userdb {
    mode = 0666
    user = vmail
    group = vmail
  }

}
service auth-worker {
}
service dict {
  unix_listener dict {
  }
}
	"""
	return 0
}


function PHASE2(){
	info "${FUNCNAME[0]} Starting"
	DATABASE_CREATION
	MAILBOX_PATH="/var/mail"
	mkdir -p ${MAILBOX_PATH}
	APP_EXEC "addgroup vmail"
	APP_EXEC "adduser vmail" true
	DOVE_PATH="/etc/dovecot"
	DOVE_PATH_CONF="${DOVE_PATH}/conf.d"
	DOVE_MAIN_CONF="${DOVE_PATH}/dovecot.conf"
	DOVE_AUTH_CONF="${DOVE_PATH_CONF}/10-auth.conf"
	DOVE_MAIL_CONF="${DOVE_PATH_CONF}/10-mail.conf"
	DOVE_SQL_CONF="${DOVE_PATH}/dovecot-sql.conf.ext"
	SET_CONF ${DOVE_PATH_CONF}/10-ssl.conf ssl no
	SET_CONF ${DOVE_MAIN_CONF} login_greeting "Welcome to kinkazma"
	SET_CONF ${DOVE_MAIN_CONF} protocols "imap lmtp"
	SET_CONF ${DOVE_MAIN_CONF} listen "0.0.0.0, ::"
	ADD_CONF ${DOVE_AUTH_CONF} "!include auth-sql.conf.ext"
	COMMENT_CONF ${DOVE_AUTH_CONF} "!include auth-passwdfile.conf.ext"
	SET_CONF ${DOVE_SQL_CONF} driver "sqlite"
	ADD_CONF ${DOVE_SQL_CONF} "connect = ${SQL_DB_FILE}"
	ADD_CONF ${DOVE_SQL_CONF} "password_query = SELECT username, domain, password  FROM users WHERE username = '%n' AND domain = '%d'" 
	ADD_CONF ${DOVE_SQL_CONF} "user_query = SELECT home, uid, gid  FROM users WHERE username = '%n' AND domain = '%d'"
	ADD_CONF ${DOVE_MAIL_CONF} "mail_location = mbox:~/mail:INBOX=${MAILBOX_PATH}/%u"
	REWRITE_FILE 10_MASTER ${DOVE_PATH_CONF}/10-master.conf

	APP_EXEC "rc-update add dovecot default"
}


