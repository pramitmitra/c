#! /bin/ksh
# Script generated by software licensed from Ab Initio.
# Use and disclosure are subject to Ab Initio confidentiality and license terms.
export AB_HOME;AB_HOME=${AB_HOME:-/usr/local/abinitio-V3-1-4}
export MPOWERHOME;MPOWERHOME="$AB_HOME"
export AB_COMPONENTS;AB_COMPONENTS="$AB_HOME"'/Projects/root/components'
export PATH
typeset _ab_uname=`uname`
case "$_ab_uname" in
Windows_* )
    PATH="$AB_HOME/bin;$PATH" ;;
CYGWIN_* )
    PATH="`cygpath "$AB_HOME"`/bin:/usr/local/bin:/usr/bin:/bin:$PATH" ;;
* )
    PATH="$AB_HOME/bin:$PATH" ;;
esac
unset ENV
export AB_REPORT;AB_REPORT=${AB_REPORT:-'monitor=300 processes scroll=true'}
unset GDE_EXECUTION

export AB_COMPATIBILITY;AB_COMPATIBILITY=3.1.4.4

# Deployed execution script for graph "target_table_load_all_dbs", compiled at Tuesday, April 07, 2015 13:19:57 using GDE version 3.1.4.1
export AB_JOB;AB_JOB=${AB_JOB_PREFIX:-""}target_table_load_all_dbs
# Begin Ab Initio shell utility functions

: ${_ab_uname:=$(uname)}

function __AB_INVOKE_PROJECT
{
  typeset _AB_PROJECT_KSH="$1" ; shift
  typeset _AB_PROJECT_DIR="$1" ; shift
  typeset _AB_DEFINE_OR_EXECUTE="$1" ; shift
  typeset _AB_START_OR_END="$1" ; shift
  # Check that the project exists:
  if [ ! -r "$_AB_PROJECT_KSH" ] ; then
    print -r -u2 Warning: Cannot find common sandbox script: "$_AB_PROJECT_KSH"
    if [ ! -z "${_AB_CALLING_PROJECT:=}" ] ; then
      print -r -u2 Please check the common sandbox settings for the calling project: "$_AB_CALLING_PROJECT"
    fi
  fi
  if [ $# -gt 0 ] ; then
    . "$_AB_PROJECT_KSH" "$_AB_PROJECT_DIR" "$_AB_DEFINE_OR_EXECUTE" "$_AB_START_OR_END"  "$@"
  else
    . "$_AB_PROJECT_KSH" "$_AB_PROJECT_DIR" "$_AB_DEFINE_OR_EXECUTE" "$_AB_START_OR_END" 
  fi;
}

function __AB_DOTIT
{
  if [ $# -gt 0 ] ; then
    .  "$@"
  fi
}

function __AB_QUOTEIT {
  typeset queue q qq qed lotsaqs s trail
  q="'"
  qq='"'
  if [ X"$1" = X"" ] ; then
    print $q$q
    return
  fi
  lotsaqs=${q}${qq}${q}${qq}${q}
  if [ ${#1} -ge 10000 ]; then
    print -r -- "$1" | sed "s/$q/$lotsaqs/g; 1s/^/$q/; \$s/\$/$q/"
  else
    queue=${1%$q}
    if [ X"$queue" != X"$1" ] ; then
      trail="${qq}${q}${qq}" 
    else 
      trail=""
    fi
    oldIFS="$IFS"
    IFS=$q
    set -- $queue
    IFS="$oldIFS"
    print -rn "$q$1"
    shift
    for s; do
      print -rn "$lotsaqs$s"
    done
    print -r $q$trail
  fi
}

function __AB_dirname {
    case $_ab_uname in
    Windows_* | CYGWIN_* )
        typeset d='' p="$1"
        # Strip drive letter colon, if present, and put it into d.
        case $p in
        [A-Za-z]:* )
            d=${p%%:*}:
            p=${p#??}
            ;;
        esac
        # Remove trailing separators, though not the last character in the
        # pathname.
        while : true; do
            case $p in
            ?*[/\\] )
                p=${p%[/\\]} ;;
            * )
                break ;;
            esac
        done
        if [[ "$p" = ?*[/\\]* ]] ; then
            print -r -- "$d${p%[/\\]*}"
        elif [[ "$p" = [/\\]* ]] ; then
            print "$d/"
        else
            print "$d." 
        fi
        ;;
    * ) # Unix
        typeset p="$1"
        # Remove trailing separators, though not the last character in the
        # pathname.
        while : true; do
            case $p in
            ?*/ )
                p="${p%/}" ;;
            * )
                break ;;
            esac
        done
        case $p in
        ?*/* )
            print -r -- "${p%/*}" ;;
        /* )
            print / ;;
        * )
            print . ;;
        esac
        ;;
    esac
}

function __AB_concat_pathname {
    case $_ab_uname in
    Windows_* | CYGWIN_* )
        # Does not handle all cases of concatenating partially absolute
        # pathnames, those with only one of a drive letter or an initial
        # separator.
        case $2 in
        [/\\]* | [A-Za-z]:* )
            print -r -- "$2"
            ;;
        * )
            case $1 in
            # Assume that empty string means ".".  Avoid adding a
            # redundant separator.
            '' | *[/\\] )
                print -r -- "$1$2" ;;
            * )
                print -r -- "$1/$2" ;;
            esac
            ;;
        esac
        ;;
    * ) # Unix
        case $2 in
        /* )
            print -r -- "$2"
            ;;
        * )
            case $1 in
            # Assume that empty string means ".".  Avoid adding a
            # redundant separator.
            '' | */ )
                print -r -- "$1$2" ;;
            * )
                print -r -- "$1/$2" ;;
            esac
            ;;
        esac
        ;;
    esac
}

function __AB_COND {
if [ X"$1" = X0  -o X"$1" = Xfalse -o X"$1" = XFalse -o X"$1" = XF -o X"$1" = Xf ] ; then
  print "0"
else
  print "1"
fi
}

# End Ab Initio shell utility functions
export AB_GRAPH_NAME;AB_GRAPH_NAME=target_table_load_all_dbs

# Host Setup Commands:
. /dw/etl/mstr_cfg/etlenv.setup
_AB_PROXY_DIR="$(pwd)"/target_table_load_all_dbs-ProxyDir-$$
rm -rf "${_AB_PROXY_DIR}"
mkdir "${_AB_PROXY_DIR}"
print -r -- "" > "${_AB_PROXY_DIR}"'/GDE-Parameters'
function __AB_CLEANUP_PROXY_FILES
{
   rm -rf "${_AB_PROXY_DIR}"
   rm -rf "${AB_EXTERNAL_PROXY_DIR}"
   return
}
trap '__AB_CLEANUP_PROXY_FILES' EXIT
# Work around pdksh bug: the EXIT handler is not executed upon a signal.
trap '_AB_status=$?; __AB_CLEANUP_PROXY_FILES; exit $_AB_status' HUP INT QUIT TERM
if [ $# -gt 0 -a X"$1" = X"-help" ]; then
print -r -- 'Usage: target_table_load_all_dbs.ksh <ETL_ID> <JOB_ENV> <SQL_FILENAME>'
exit 1
fi

# Command Line Processing
function _AB_PARSE_ARGUMENTS {
   unset ETL_ID
   unset JOB_ENV
   unset SQL_FILENAME
   _ab_index_var=0
   if [ $# -gt 0 ]; then
      export ETL_ID;      ETL_ID="${1}"
      let _ab_index_var=_ab_index_var+1
      _AB_USED_ARGUMENTS[_ab_index_var]=1
      shift
   fi
   if [ $# -gt 0 ]; then
      export JOB_ENV;      JOB_ENV="${1}"
      let _ab_index_var=_ab_index_var+1
      _AB_USED_ARGUMENTS[_ab_index_var]=1
      shift
   fi
   if [ $# -gt 0 ]; then
      export SQL_FILENAME;      SQL_FILENAME="${1}"
      let _ab_index_var=_ab_index_var+1
      _AB_USED_ARGUMENTS[_ab_index_var]=1
      shift
   fi
   while [ $# -gt 0 ]; do
   _ab_kwd="${1}"
   let _ab_index_var=_ab_index_var+1
   shift
   case ${_ab_kwd} in
     -TRGT_DB )
      export TRGT_DB;      TRGT_DB="${1}"
      _AB_USED_ARGUMENTS[_ab_index_var]=1
      _AB_USED_ARGUMENTS[_ab_index_var+1]=1
      let _ab_index_var=_ab_index_var+1
      shift
      ;;
     -TRGT_DB_SCHEMA )
      export TRGT_DB_SCHEMA;      TRGT_DB_SCHEMA="${1}"
      _AB_USED_ARGUMENTS[_ab_index_var]=1
      _AB_USED_ARGUMENTS[_ab_index_var+1]=1
      let _ab_index_var=_ab_index_var+1
      shift
      ;;
     -DEFAULT_DB )
      export DEFAULT_DB;      DEFAULT_DB="${1}"
      _AB_USED_ARGUMENTS[_ab_index_var]=1
      _AB_USED_ARGUMENTS[_ab_index_var+1]=1
      let _ab_index_var=_ab_index_var+1
      shift
      ;;
     -ODBC_DATA_SOURCE_NAME )
      export ODBC_DATA_SOURCE_NAME;      ODBC_DATA_SOURCE_NAME="${1}"
      _AB_USED_ARGUMENTS[_ab_index_var]=1
      _AB_USED_ARGUMENTS[_ab_index_var+1]=1
      let _ab_index_var=_ab_index_var+1
      shift
      ;;
     -MSSQL_USERNAME )
      export MSSQL_USERNAME;      MSSQL_USERNAME="${1}"
      _AB_USED_ARGUMENTS[_ab_index_var]=1
      _AB_USED_ARGUMENTS[_ab_index_var+1]=1
      let _ab_index_var=_ab_index_var+1
      shift
      ;;
     -MSSQL_PASSWORD )
      export MSSQL_PASSWORD;      MSSQL_PASSWORD="${1}"
      _AB_USED_ARGUMENTS[_ab_index_var]=1
      _AB_USED_ARGUMENTS[_ab_index_var+1]=1
      let _ab_index_var=_ab_index_var+1
      shift
      ;;
     -MYSQL_USERNAME )
      export MYSQL_USERNAME;      MYSQL_USERNAME="${1}"
      _AB_USED_ARGUMENTS[_ab_index_var]=1
      _AB_USED_ARGUMENTS[_ab_index_var+1]=1
      let _ab_index_var=_ab_index_var+1
      shift
      ;;
     -MYSQL_PASSWORD )
      export MYSQL_PASSWORD;      MYSQL_PASSWORD="${1}"
      _AB_USED_ARGUMENTS[_ab_index_var]=1
      _AB_USED_ARGUMENTS[_ab_index_var+1]=1
      let _ab_index_var=_ab_index_var+1
      shift
      ;;
   * )
      if [ X"${_AB_USED_ARGUMENTS[_ab_index_var]}" != X1 ]; then
         print -r -- 'Unexpected command line argument found: '"${_ab_kwd}"
         print -r -- 'Usage: target_table_load_all_dbs.ksh <ETL_ID> <JOB_ENV> <SQL_FILENAME>'
         exit 1
      fi
   esac
   done
}
if [ $# -gt 0 ]; then
   _AB_PARSE_ARGUMENTS "$@"
else
   _AB_PARSE_ARGUMENTS
fi

if [ X"${ETL_ID:-}" = X"" ]; then
   print -r -- 'Required parameter ETL_ID undefined'
   print -r -- 'Usage: target_table_load_all_dbs.ksh <ETL_ID> <JOB_ENV> <SQL_FILENAME>'
   exit 1
fi

if [ X"${JOB_ENV:-}" = X"" ]; then
   print -r -- 'Required parameter JOB_ENV undefined'
   print -r -- 'Usage: target_table_load_all_dbs.ksh <ETL_ID> <JOB_ENV> <SQL_FILENAME>'
   exit 1
fi

if [ X"${SQL_FILENAME:-}" = X"" ]; then
   print -r -- 'Required parameter SQL_FILENAME undefined'
   print -r -- 'Usage: target_table_load_all_dbs.ksh <ETL_ID> <JOB_ENV> <SQL_FILENAME>'
   exit 1
fi
export ETL_CFG_FILE;ETL_CFG_FILE="$DW_CFG"'/'"$ETL_ID"'.cfg'
export SUBJECT_AREA;SUBJECT_AREA=${ETL_ID%%.*}
mpjret=$?
if [ 0 -ne $mpjret ] ; then
   print -- Error evaluating: 'parameter SUBJECT_AREA of target_table_load_all_dbs', interpretation 'shell'
   exit $mpjret
fi
export TABLE_ID;TABLE_ID=${ETL_ID##*.}
mpjret=$?
if [ 0 -ne $mpjret ] ; then
   print -- Error evaluating: 'parameter TABLE_ID of target_table_load_all_dbs', interpretation 'shell'
   exit $mpjret
fi
export CFG_DBC_PARAM;CFG_DBC_PARAM=$(JOB_ENV_UPPER=$(print $JOB_ENV | tr [:lower:] [:upper:]) 
  eval print ${JOB_ENV_UPPER}_DBC)
mpjret=$?
if [ 0 -ne $mpjret ] ; then
   print -- Error evaluating: 'parameter CFG_DBC_PARAM of target_table_load_all_dbs', interpretation 'shell'
   exit $mpjret
fi
export DEFAULT_DB_NAME;DEFAULT_DB_NAME=$(JOB_ENV_UPPER=$(print $JOB_ENV | tr [:lower:] [:upper:])
 eval print teradata_\$DW_${JOB_ENV_UPPER}_DB)
mpjret=$?
if [ 0 -ne $mpjret ] ; then
   print -- Error evaluating: 'parameter DEFAULT_DB_NAME of target_table_load_all_dbs', interpretation 'shell'
   exit $mpjret
fi
export AB_JOB;AB_JOB=$(if [ $ETL_ENV ]
then
   print $AB_JOB.$TABLE_ID.${SQL_FILENAME%.sql}.$ETL_ENV.$JOB_ENV
else
   print $AB_JOB.$TABLE_ID.${SQL_FILENAME%.sql}.$JOB_ENV
fi)
mpjret=$?
if [ 0 -ne $mpjret ] ; then
   print -- Error evaluating: 'parameter AB_JOB of target_table_load_all_dbs', interpretation 'shell'
   exit $mpjret
fi
export DB_NAME;DB_NAME=$(grep "^$CFG_DBC_PARAM\>" $ETL_CFG_FILE | read PARAM VALUE COMMENT; print ${VALUE:-$DEFAULT_DB_NAME})
mpjret=$?
if [ 0 -ne $mpjret ] ; then
   print -- Error evaluating: 'parameter DB_NAME of target_table_load_all_dbs', interpretation 'shell'
   exit $mpjret
fi
export AB_IDB_CONFIG;AB_IDB_CONFIG=${DB_NAME}.dbc
mpjret=$?
if [ 0 -ne $mpjret ] ; then
   print -- Error evaluating: 'parameter AB_IDB_CONFIG of target_table_load_all_dbs', interpretation 'shell'
   exit $mpjret
fi
export DB_TYPE;DB_TYPE=$(grep "^dbms\>" $DW_DBC/$AB_IDB_CONFIG | tr [:lower:] [:upper:] | read PARAM VALUE COMMENT; print ${VALUE:-0})
mpjret=$?
if [ 0 -ne $mpjret ] ; then
   print -- Error evaluating: 'parameter DB_TYPE of target_table_load_all_dbs', interpretation 'shell'
   exit $mpjret
fi
export TRGT_DB;TRGT_DB=$(case $DB_TYPE in
    "MSSQL" ) print $(grep "^MSSQL_TRGT_DB\>" $ETL_CFG_FILE | read PARAM VALUE COMMENT; eval print $VALUE);;
          * ) print -- "dummy";;
esac)
mpjret=$?
if [ 0 -ne $mpjret ] ; then
   print -- Error evaluating: 'parameter TRGT_DB of target_table_load_all_dbs', interpretation 'shell'
   exit $mpjret
fi
export TRGT_DB_SCHEMA;TRGT_DB_SCHEMA=$(case $DB_TYPE in
    "MSSQL" ) print $(grep "^MSSQL_TRGT_DB_SCHEMA\>" $ETL_CFG_FILE | read PARAM VALUE COMMENT; eval print $VALUE);;
          * ) print -- "";;
esac)
mpjret=$?
if [ 0 -ne $mpjret ] ; then
   print -- Error evaluating: 'parameter TRGT_DB_SCHEMA of target_table_load_all_dbs', interpretation 'shell'
   exit $mpjret
fi
export DEFAULT_DB;DEFAULT_DB="$TRGT_DB"
export TNS_NAME;TNS_NAME=$(grep "^db_name\>" $DW_DBC/$AB_IDB_CONFIG | read A TNS_NAME_TMP
  print ${TNS_NAME_TMP#@})
mpjret=$?
if [ 0 -ne $mpjret ] ; then
   print -- Error evaluating: 'parameter TNS_NAME of target_table_load_all_dbs', interpretation 'shell'
   exit $mpjret
fi
export ORA_USERNAME;ORA_USERNAME=$(grep "^$TNS_NAME\>" $DW_LOGINS/ora_logins.dat | read TNS_NAME ORA_USERNAME ORA_PASSWORD ; print $ORA_USERNAME)
mpjret=$?
if [ 0 -ne $mpjret ] ; then
   print -- Error evaluating: 'parameter ORA_USERNAME of target_table_load_all_dbs', interpretation 'shell'
   exit $mpjret
fi
export ORA_PASSWORD;ORA_PASSWORD=$(grep "^$TNS_NAME\>" $DW_LOGINS/ora_logins.dat | read TNS_NAME ORA_USERNAME ORA_PASSWORD ; print $ORA_PASSWORD)
mpjret=$?
if [ 0 -ne $mpjret ] ; then
   print -- Error evaluating: 'parameter ORA_PASSWORD of target_table_load_all_dbs', interpretation 'shell'
   exit $mpjret
fi
export ODBC_DATA_SOURCE_NAME;ODBC_DATA_SOURCE_NAME=$(grep "^odbc_data_source_name\>" $DW_DBC/$AB_IDB_CONFIG | read A ODSN_TMP; print ${ODSN_TMP:-""})
mpjret=$?
if [ 0 -ne $mpjret ] ; then
   print -- Error evaluating: 'parameter ODBC_DATA_SOURCE_NAME of target_table_load_all_dbs', interpretation 'shell'
   exit $mpjret
fi
export MSSQL_USERNAME;MSSQL_USERNAME=$(if [[ $DB_TYPE == 'MSSQL' ]]
  then
    if [[ ! -n $MSSQL_USERNAME ]]
    then
      grep "^$ODBC_DATA_SOURCE_NAME\>" $DW_LOGINS/mssql_logins.dat | read ODBC_NAME MSSQL_USERNAME MSSQL_PASSWORD ; print $MSSQL_USERNAME
    else
      print $MSSQL_USERNAME
    fi
  fi
 )
mpjret=$?
if [ 0 -ne $mpjret ] ; then
   print -- Error evaluating: 'parameter MSSQL_USERNAME of target_table_load_all_dbs', interpretation 'shell'
   exit $mpjret
fi
export MSSQL_PASSWORD;MSSQL_PASSWORD=$(if [[ $DB_TYPE == 'MSSQL' ]]
  then
    if [[ ! -n $MSSQL_PASSWORD ]]
    then
      grep "^$ODBC_DATA_SOURCE_NAME\>" $DW_LOGINS/mssql_logins.dat | read ODBC_NAME MSSQL_USERNAME MSSQL_PASSWORD ; print $MSSQL_PASSWORD
    else
      print $MSSQL_PASSWORD
    fi
  fi
 )
mpjret=$?
if [ 0 -ne $mpjret ] ; then
   print -- Error evaluating: 'parameter MSSQL_PASSWORD of target_table_load_all_dbs', interpretation 'shell'
   exit $mpjret
fi
export MYSQL_USERNAME;MYSQL_USERNAME=$(if [[ $DB_TYPE == 'MYSQL' ]]
  then
    if [[ ! -n $MYSQL_USERNAME ]]
    then
      grep "^$ODBC_DATA_SOURCE_NAME\>" $DW_LOGINS/mysql_logins.dat | read ODSN MYSQL_USERNAME MYSQL_PASSWORD ; print $MYSQL_USERNAME
    else
      print $MYSQL_USERNAME
    fi
  fi
 )
mpjret=$?
if [ 0 -ne $mpjret ] ; then
   print -- Error evaluating: 'parameter MYSQL_USERNAME of target_table_load_all_dbs', interpretation 'shell'
   exit $mpjret
fi
export MYSQL_PASSWORD;MYSQL_PASSWORD=$(if [[ $DB_TYPE == 'MYSQL' ]]
  then
    if [[ ! -n $MYSQL_PASSWORD ]]
    then
      grep "^$ODBC_DATA_SOURCE_NAME\>" $DW_LOGINS/mysql_logins.dat | read ODSN MYSQL_USERNAME MYSQL_PASSWORD ; print $MYSQL_PASSWORD
    else
      print $MYSQL_PASSWORD
    fi
  fi
 )
mpjret=$?
if [ 0 -ne $mpjret ] ; then
   print -- Error evaluating: 'parameter MYSQL_PASSWORD of target_table_load_all_dbs', interpretation 'shell'
   exit $mpjret
fi
export DW_SA_LOG;DW_SA_LOG="$DW_LOG"'/'"$JOB_ENV"'/'"$SUBJECT_AREA"'/'"$TABLE_ID"'/'"$CURR_DATE"
export DW_SA_TMP;DW_SA_TMP="$DW_TMP"'/'"$JOB_ENV"'/'"$SUBJECT_AREA"
export FILE_DATETIME;FILE_DATETIME=$(date '+%Y%m%d-%H%M%S')
mpjret=$?
if [ 0 -ne $mpjret ] ; then
   print -- Error evaluating: 'parameter FILE_DATETIME of target_table_load_all_dbs', interpretation 'shell'
   exit $mpjret
fi
export CREATE_TMP_SQL_FILE;CREATE_TMP_SQL_FILE=$(set -e
  print "cat <<EOF" > $DW_SA_TMP/$TABLE_ID.bt.$SQL_FILENAME.tmp
  if [[ $DB_TYPE == 'TERADATA' ]] 
  then 
     print "select session;" >> $DW_SA_TMP/$TABLE_ID.bt.$SQL_FILENAME.tmp 
  fi
  cat $DW_SQL/$SQL_FILENAME >> $DW_SA_TMP/$TABLE_ID.bt.$SQL_FILENAME.tmp
  print "EOF" >> $DW_SA_TMP/$TABLE_ID.bt.$SQL_FILENAME.tmp
  set +e)
mpjret=$?
if [ 0 -ne $mpjret ] ; then
   print -- Error evaluating: 'parameter CREATE_TMP_SQL_FILE of target_table_load_all_dbs', interpretation 'shell'
   exit $mpjret
fi
export RUN_SQL_FILE;RUN_SQL_FILE=$(. $DW_SA_TMP/$TABLE_ID.bt.$SQL_FILENAME.tmp)
mpjret=$?
if [ 0 -ne $mpjret ] ; then
   print -- Error evaluating: 'parameter RUN_SQL_FILE of target_table_load_all_dbs', interpretation 'shell'
   exit $mpjret
fi
export RUN_SQL_LOGFILE;RUN_SQL_LOGFILE=$DW_SA_LOG/$TABLE_ID.bt.${SQL_FILENAME%.sql}.$FILE_DATETIME.log
mpjret=$?
if [ 0 -ne $mpjret ] ; then
   print -- Error evaluating: 'parameter RUN_SQL_LOGFILE of target_table_load_all_dbs', interpretation 'shell'
   exit $mpjret
fi
(
   # Parameters of Run SQL
   _AB_FILE_NAME__DBConfigFile="$AB_IDB_CONFIG"
   if [ -r "${_AB_FILE_NAME__DBConfigFile}" ]; then
      DBConfigFile=$(< "${_AB_FILE_NAME__DBConfigFile}")
      mpjret=$?
      if [ 0 -ne $mpjret ] ; then
         print -- Error evaluating: 'parameter DBConfigFile of Run_SQL', interpretation 'shell'
         exit $mpjret
      fi
   else
      _AB_DBC_PATH=$(m_db find "${_AB_FILE_NAME__DBConfigFile}" 2>/dev/null)
      if [ $? = 0 ]; then
         DBConfigFile=$(< "${_AB_DBC_PATH}")
         mpjret=$?
         if [ 0 -ne $mpjret ] ; then
            print -- Error evaluating: 'parameter DBConfigFile of Run_SQL', interpretation 'shell'
            exit $mpjret
         fi
      else
         print -r -- 'Warning: cannot read '"'""${_AB_FILE_NAME__DBConfigFile}""'"' to define parameter DBConfigFile of Run_SQL'
      fi
   fi
   dbms="$DB_TYPE"
   interface=utility
   SQLFile=$RUN_SQL_FILE
   mpjret=$?
   if [ 0 -ne $mpjret ] ; then
      print -- Error evaluating: 'parameter SQLFile of Run_SQL', interpretation 'shell'
      exit $mpjret
   fi
   print -r -- "${SQLFile}" > "${_AB_PROXY_DIR}"'/Run_SQL-2.sql'
   _AB_FILE_NAME__SQLFile=Run_SQL-2.sql
   print -rn Run_SQL__SQLFile= >>"${_AB_PROXY_DIR}"'/GDE-Parameters'
   __AB_QUOTEIT "${SQLFile}" >> "${_AB_PROXY_DIR}"'/GDE-Parameters'
   print -rn _AB_FILE_NAME__Run_SQL__SQLFile= >> "${_AB_PROXY_DIR}"'/GDE-Parameters'
   __AB_QUOTEIT "${_AB_FILE_NAME__SQLFile}" >> "${_AB_PROXY_DIR}"'/GDE-Parameters'
)
mpjret=$?
if [ 0 -ne $mpjret ] ; then exit $mpjret ; fi
. "${_AB_PROXY_DIR}"'/GDE-Parameters'

#+Script Start+  ==================== 
#+End Script Start+  ====================
# Check that the "mp" program is found correctly on the PATH
case "$_ab_uname" in
  Windows_* )
    _ab_expected_mp=$AB_HOME/bin/mp.exe ;;
  * )
    _ab_expected_mp=$AB_HOME/bin/mp
esac
if [ ! -x "$_ab_expected_mp" ]; then
  print "\n*** ERROR: executable $_ab_expected_mp not found"
  exit 1
fi
_ab_found_mp=$(whence mp)
if [ "$_ab_found_mp" = "" ] || [ "$_ab_found_mp" -ot "$_ab_expected_mp" ] || [ "$_ab_found_mp" -nt "$_ab_expected_mp" ]; then
  if [ "$_ab_found_mp" = "" ]; then
    print "\n*** ERROR: mp not found on PATH"
  else
    case "$_ab_uname" in
      CYGWIN_* )
        _ab_found_mp=`cygpath -m "$_ab_found_mp"` ;;
    esac
    print "\n*** ERROR: Wrong mp found on the PATH: $_ab_found_mp"
    print "           Should be via \$AB_HOME/bin: $_ab_expected_mp"
  fi
  print "\nCheck Setup Script in Host Connections Settings and Script Start in Graph Settings for PATH modifications"
  print "Active PATH=$PATH"
  exit 1
fi
if [ -f "$AB_HOME/bin/ab_catalog_functions.ksh" ]; then . ab_catalog_functions.ksh; fi
mv "${_AB_PROXY_DIR}" "$(pwd)"/"${AB_JOB}"'-target_table_load_all_dbs-ProxyDir'
_AB_PROXY_DIR="$(pwd)"/"${AB_JOB}"'-target_table_load_all_dbs-ProxyDir'
print -r -- 'record string("|") node, timestamp, component, subcomponent, event_type; string("|\n") event_text; end' > "${_AB_PROXY_DIR}"'/Run_SQL-3.dml'
print -r -- 'out::reformat(in) =
begin
  out.event_text :: in.event_text;
end;' > "${_AB_PROXY_DIR}"'/Reformat-4.xfr'
print -r -- 'record
  string("\n") event_text;
end;' > "${_AB_PROXY_DIR}"'/Reformat-5.dml'

mp job ${AB_JOB}

# Layouts:
mp layout layout1 "$DW_TMP"

# Record Formats (Metadata):
mp metadata metadata1 -file "${_AB_PROXY_DIR}"'/Run_SQL-3.dml'
mp metadata metadata2 -file "${_AB_PROXY_DIR}"'/Reformat-5.dml'

export AB_CATALOG;AB_CATALOG=${AB_CATALOG:-"${XX_CATALOG}"}
# Catalog Usage: Creating temporary catalog using lookup files only
m_rmcatalog -catalog GDE-target_table_load_all_dbs-${AB_JOB}.cat > /dev/null 2>&1
m_mkcatalog -catalog GDE-target_table_load_all_dbs-${AB_JOB}.cat
SAVED_CATALOG="${AB_CATALOG}"
export AB_CATALOG;AB_CATALOG='GDE-target_table_load_all_dbs-'"${AB_JOB}"'.cat'

# Files:
mp file Run_SQL_Log_File 'file:'"$RUN_SQL_LOGFILE" -flags rdwr,unlink,creat,norollback
mp file Run_SQL_Log_File_Tmp 'file:'"${RUN_SQL_LOGFILE}"'.tmp' -flags wronly,unlink,creat,norollback

# Components in phase 0:
mp db-runsql Run_SQL "$AB_IDB_CONFIG" "${_AB_PROXY_DIR}"'/Run_SQL-2.sql' -interface utility -layout Run_SQL_Log_File
mp checkpoint 0

# Components in phase 1:
mp reformat-transform Reformat -limit 0 -ramp 0.0 -layout Run_SQL_Log_File_Tmp
mp add-port Reformat.out.out0 ${_AB_PROXY_DIR:+"$_AB_PROXY_DIR"}'/Reformat-4.xfr'
mp checkpoint 1

# Components in phase 2:
mp filter Rename_Run_SQL_Log_File_Tmp mv ${RUN_SQL_LOGFILE}.tmp ${RUN_SQL_LOGFILE} -layout layout1

# Flows for Entire Graph:
mp straight-flow Flow_1 Run_SQL.log Run_SQL_Log_File.write -metadata metadata1
mp straight-flow Flow_2 Run_SQL_Log_File.read Reformat.in -metadata metadata1
mp straight-flow Flow_3 Reformat.out.out0 Run_SQL_Log_File_Tmp.write -metadata metadata2

unset AB_COMM_WAIT
export AB_TRACKING_GRAPH_THUMBPRINT;AB_TRACKING_GRAPH_THUMBPRINT=3794828
mp run
mpjret=$?
unset AB_COMM_WAIT
unset AB_TRACKING_GRAPH_THUMBPRINT
mp reset
m_rmcatalog > /dev/null 2>&1
export XX_CATALOG;XX_CATALOG="${SAVED_CATALOG}"
export AB_CATALOG;AB_CATALOG="${SAVED_CATALOG}"

#+Script End+  ==================== 
#+End Script End+  ====================

exit $mpjret
