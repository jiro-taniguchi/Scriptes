
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
	
