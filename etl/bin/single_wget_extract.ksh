#!/bin/ksh -eu
#------------------------------------------------------------------------------------------------
# Filename:     single_wget_extract.ksh
#
# Revision History:
#
# Name             Date            Description
# ---------------  --------------  ---------------------------------------------------
# ???              ??/??/????      Initial Creation
# Ryan Wong        10/04/2013      Redhat changes
# John Hackley     09/09/2015      Password encryption changes
# John Hackley     02/19/2018      Enable SFTP Proxy as part of Gauls decommissioning
#
#------------------------------------------------------------------------------------------------

ETL_ID=$1
FILE_ID=$2
SCP_CONN=$3
SOURCE_FILE=$4
TARGET_FILE=$5  

. $DW_MASTER_LIB/dw_etl_common_functions.lib

DWI_fetch_pw $ETL_ID scp $SCP_CONN
DWIrc=$?

if [[ -z $SCP_PASSWORD ]]
then
  print "Unable to retrieve SCP password, exiting; ETL_ID=$ETL_ID; SCP_CONN=$SCP_CONN"
  exit $DWIrc
fi


set +e
grep "^EXTRACT_USE_EXT_WEB_PROXY\>" $DW_CFG/$ETL_ID.cfg | read PARAM VALUE COMMENT;  EXTRACT_USE_EXT_WEB_PROXY=${VALUE:-0}
rcode=$?
set -e

if [ $rcode != 0 ]
then
  print "${0##*/}: WARNING, failure determining value for EXTRACT_USE_EXT_WEB_PROXY parameter from $DW_CFG/$ETL_ID.cfg" >&2
fi


set +e
grep "^CNDTL_COMPRESSION\>" $DW_CFG/$ETL_ID.cfg | read PARAM VALUE COMMENT;  IS_COMPRESS=${VALUE:-0}
rcode=$?
set -e

if [ $rcode != 0 ]
then
  print "${0##*/}: WARNING, failure determining value for CNDTL_COMPRESSION parameter from $DW_CFG/$ETL_ID.cfg" >&2
fi

if [ $IS_COMPRESS = 1 ]
then
  set +e
  grep "^CNDTL_COMPRESSION_SFXN\>" $DW_CFG/$ETL_ID.cfg | read PARAM VALUE COMMENT; COMPRESS_SFX=${VALUE:-".gz"}
  rcode=$?
  set -e

  if [ $rcode != 0 ]
  then
   print "${0##*/}: WARNING, failure determining value for CNDTL_COMPRESSION_SFX parameter from $DW_CFG/$ETL_ID.cfg" >&2
  fi
else
   COMPRESS_SFX=""
fi

# If not defined, get IN_DIR from etl cfg
set +u
if [ "$IN_DIR" == "" ]
then
  assignTagValue IN_DIR IN_DIR $ETL_CFG_FILE W $DW_IN
  export IN_DIR=$IN_DIR/$JOB_ENV/$SUBJECT_AREA
fi
set -u

SOURCE_FILE_TMP=`print $(eval print $SOURCE_FILE)`
SOURCE_FILE_TMP=$SOURCE_FILE_TMP$COMPRESS_SFX
SOURCE_FILE_LOG=`print $(eval print $SOURCE_FILE | sed 's/\//_/g')`
TARGET_FILE_TMP=`print $(eval print $TARGET_FILE)`

  if [[ -n $UOW_TO ]]
  then
         TARGET_FILE_TMP=${TARGET_FILE_TMP%%$COMPRESS_SFX}$COMPRESS_SFX
  else
         TARGET_FILE_TMP=${TARGET_FILE_TMP%%$COMPRESS_SFX}.$BATCH_SEQ_NUM$COMPRESS_SFX
  fi
#TARGET_FILE_TMP=${TARGET_FILE_TMP%%$COMPRESS_SFX}.$BATCH_SEQ_NUM$COMPRESS_SFX


# Note that the name and port for the Web Proxy host are hard-coded here; a better home to hard-code would be etlenv.setup but
# too many of us are modifying it simultaneously this month

if [ $EXTRACT_USE_EXT_WEB_PROXY = 1 ]
then
# Only one of these proxy variables actually has to be set, depending on the external endpoint (http vs https). Keep it simple and set them both
  EXPORT http_proxy=httpproxy.vip.ebay.com:80
  EXPORT https_proxy=httpproxy.vip.ebay.com:80

  print "${0##*/}: INFO, Will use External Web Proxy for wget call" >&2
  print "${0##*/}: INFO, wget command line is: wget --verbose --tries=5 --waitretry=2 --no-host-directories -O $IN_DIR/$TARGET_FILE_TMP $URL/$SOURCE_FILE_TMP" >&2

#  print "${0##*/}: INFO, wget command line is: wget --verbose --append-output=$ETL_ID.$SOURCE_FILE_LOG.$CURR_DATETIME.log --tries=5 --waitretry=2 --no-host-directories $URL/$SOURCE_FILE_TMP" >&2

# Not sure this cd is necessary (since using -O option of wget), but it was in single_wget_internal_extract.ksh so keeping it.
  cd $IN_DIR/
  set +e
# Instead of specifying --append-output, just tack >&2 onto the end of the wget call
# wget --verbose --append-output=$ETL_ID.$SOURCE_FILE_LOG.$CURR_DATETIME.log --tries=5 --waitretry=2 --no-host-directories $URL/$SOURCE_FILE_TMP
  wget --verbose --tries=5 --waitretry=2 --no-host-directories -O $IN_DIR/$TARGET_FILE_TMP $URL/$SOURCE_FILE_TMP >&2
  rcode=$?
  set -e

  if [ $rcode != 0 ]
  then
    print "${0##*/}:  ERROR, failure executing wget." >&2
#   Don't need this, per above comment
#   print "${0##*/}:  ERROR, see $ETL_ID.$SOURCE_FILE_LOG.$CURR_DATETIME.log for wget error message." >&2
    exit $rcode
  fi

  ((FILE_REC_COUNT=`ls -l $IN_DIR/$TARGET_FILE_TMP | tr -s ' '| cut -d' ' -f5`/100))

  print $FILE_REC_COUNT > $DW_SA_TMP/$TABLE_ID.$JOB_TYPE_ID.$FILE_ID.record_count.dat

else

  set +e
  ssh "$SCP_USERNAME@$SCP_HOST" "cd $REMOTE_DIR; if [[ -f ./$SOURCE_FILE_TMP ]]; then rm -f ./$SOURCE_FILE_TMP; fi; wget --verbose --append-output=$ETL_ID.$SOURCE_FILE_LOG.$CURR_DATETIME.log --tries=5 --waitretry=2 --no-host-directories $URL/$SOURCE_FILE_TMP" >&2
  rcode=$?
  set -e

  if [ $rcode != 0 ]
  then
        print "${0##*/}:  ERROR, failure executing wget." >&2
        print "${0##*/}:  ERROR, see ${SCP_HOST}:$REMOTE_DIR/$ETL_ID.$SOURCE_FILE_LOG.$CURR_DATETIME.log for wget error message." >&2
        print
        print \"$SCP_USERNAME@$SCP_HOST \"cd $REMOTE_DIR\; wget --verbose --append-output=$ETL_ID.$SOURCE_FILE_LOG.$CURR_DATETIME.log --tries=5 --waitretry=2 --no-host-directories $URL/$SOURCE_FILE_TMP\" >&2
        print
        print "Output of file: ${SCP_HOST}:$REMOTE_DIR/$ETL_ID.$SOURCE_FILE_LOG.$CURR_DATETIME.log"
        print  
        ssh "$SCP_USERNAME@$SCP_HOST" "cd $REMOTE_DIR; cat $ETL_ID.$SOURCE_FILE_LOG.$CURR_DATETIME.log"
        exit 500 
  fi

  scp -v -B $SCP_USERNAME@$SCP_HOST:$REMOTE_DIR/${SOURCE_FILE_TMP##*/} $IN_DIR/$TARGET_FILE_TMP >&2

 
  ((FILE_REC_COUNT=`ls -l $IN_DIR/$TARGET_FILE_TMP | tr -s ' '| cut -d' ' -f5`/100))

  print $FILE_REC_COUNT > $DW_SA_TMP/$TABLE_ID.$JOB_TYPE_ID.$FILE_ID.record_count.dat

# Remove file on ssh server.
  ssh "$SCP_USERNAME@$SCP_HOST" "cd $REMOTE_DIR; rm ${SOURCE_FILE_TMP##*/}"
  ssh "$SCP_USERNAME@$SCP_HOST" "cd $REMOTE_DIR; rm $ETL_ID.$SOURCE_FILE_LOG.$CURR_DATETIME.log"

fi

if [[ $LAST_EXTRACT_TYPE = "V" ]]
then
        print $TO_EXTRACT_VALUE > $DW_SA_DAT/$TABLE_ID.$FILE_ID.last_extract_value.dat
fi

exit
