#/bin/bash
# $Id$
# Marcus Vinicius Ferreira          ferreira.mv[ at ]gmail.com
#                 Jul/2009
#
# Backup postgres 8.1
#

PATH=/opt/csw/bin:opt/csw/sbin
PATH=$PATH:/opt/local/bin:/opt/local/sbin
PATH=$PATH:/usr/local/bin:/usr/local/sbin
PATH=$PATH:/usr/bin:/usr/sbin:/bin:/sbin

[ "$1" != '-f' ] && {
    echo
    echo "Usage: $0 -f"
    echo
    echo "    Postgres backup - create one dump file for each database."
    echo
    exit 1
}

 BKPDIR=/abd/bkp/depot/pgsql
 LOGDIR=/abd/bkp/log
   FILE=${0##*/}
LOGFILE=${LOGDIR}/${FILE%.*}.log

MAIL_FROM="noreply@webcointernet.com"
  MAIL_TO="marcus.ferreira@abril.com.br"

### pgsql:
###     CREATE ROLE backup LOGIN SUPERUSER PASSWORD 'Back-Up#2009';
### pg_hba.conf:
###     # TYPE  DATABASE    USER        CIDR-ADDRESS          METHOD
###     host    all         backup      127.0.0.1/32          trust
###
export     PGHOST="localhost"
export     PGPORT=5432
export PGDATABASE=template1
export     PGUSER="backup"
export PGPASSWORD='Back-Up#2009'

dtnow() {
    date "+%Y-%m-%d-%H%M"
}

logmsg() {
    echo "`date '+%Y-%m-%d %H:%M:%S'` : $1" | tee -a $LOGFILE
}

mailmsg() {
    MSG=$1
    ERROR=$2

    LINES=15
    LOG=`cat -n $LOGFILE | tail -${LINES}`

    [ "$ERROR" ] && MSG="WARNING: $MSG"

    mail $MAIL_TO <<MAIL
From: $MAIL_FROM
To: $MAIL_TO
Subject: ${HOSTNAME}: $MSG


$MSG

Message generated by $0 at `date`

Last $LINES lines at log $LOGFILE:
__________________________________________________________________

$LOG
__________________________________________________________________


MAIL
}

pgsql_dump() {
    pg_dump                         \
        --clean                     \
        --column-inserts            \
        --disable-dollar-quoting    \
        $1 | gzip > ${2}.gz
}

logmsg "PgSQL Backup - Started."

DB_LIST=$( echo "SELECT datname FROM pg_catalog.pg_database WHERE datname <> 'template0' ORDER BY 1" | psql -t )
if [ ! "$DB_LIST" ]
then
    logmsg  "Database List empty. Backup will not be done."
    mailmsg "Database List empty. Backup will not be done." $ERR
    exit 4
fi

HOSTNAME=`hostname`
HOSTNAME=${HOSTNAME%%.*}
for DB in $DB_LIST
do
      DT=`dtnow`
    FILE="${BKPDIR}/${HOSTNAME}_${DT}_${DB}.pgdump.sql"
    logmsg "Backup BEGIN [$DB]"
    logmsg "        file [$FILE]"

    if pgsql_dump $DB $FILE
    then
        logmsg "Backup END   [$DB] - Ok"
    else
        ERR="$?"
        logmsg "Backup END   [$DB] - Error [$ERR]"
        mailmsg "PgSQL did not finish backup: [$ERR]" $ERR
    fi

done

logmsg "PgSQL Backup - Completed."

if [ "$ERR" ]
then
    exit $ERR
fi

mailmsg "PgSQL Backup SUCCESS"
exit 0


